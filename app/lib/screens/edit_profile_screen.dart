import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../services/graphql_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late TextEditingController _displayNameController;
  late TextEditingController _handleController;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _hasChanges = false;
  File? _selectedImage;

  // Handle availability checking
  String? _originalHandle;
  bool _isCheckingHandle = false;
  bool? _isHandleAvailable;
  Timer? _handleDebounce;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _displayNameController = TextEditingController(text: auth.displayName ?? '');
    _displayNameController.addListener(_onFieldChanged);

    _originalHandle = auth.handle ?? '';
    _handleController = TextEditingController(text: _originalHandle);
    _handleController.addListener(_onHandleChanged);
  }

  @override
  void dispose() {
    _displayNameController.removeListener(_onFieldChanged);
    _displayNameController.dispose();
    _handleController.removeListener(_onHandleChanged);
    _handleController.dispose();
    _handleDebounce?.cancel();
    super.dispose();
  }

  void _onFieldChanged() {
    _checkForChanges();
  }

  void _onHandleChanged() {
    _checkForChanges();

    final handle = _handleController.text.trim().toLowerCase();

    // If handle is unchanged from original, clear availability state
    if (handle == _originalHandle) {
      setState(() {
        _isHandleAvailable = null;
        _isCheckingHandle = false;
      });
      _handleDebounce?.cancel();
      return;
    }

    // Debounce the availability check
    _handleDebounce?.cancel();
    if (handle.length >= 3) {
      setState(() => _isCheckingHandle = true);
      _handleDebounce = Timer(const Duration(milliseconds: 500), () {
        _checkHandleAvailability(handle);
      });
    } else {
      setState(() {
        _isHandleAvailable = null;
        _isCheckingHandle = false;
      });
    }
  }

  Future<void> _checkHandleAvailability(String handle) async {
    try {
      final available = await GraphQLService().isHandleAvailable(handle);
      if (mounted && _handleController.text.trim().toLowerCase() == handle) {
        setState(() {
          _isHandleAvailable = available;
          _isCheckingHandle = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingHandle = false);
      }
    }
  }

  void _checkForChanges() {
    final auth = context.read<AuthProvider>();
    final displayNameChanged = _displayNameController.text.trim() != (auth.displayName ?? '');
    final handleChanged = _handleController.text.trim().toLowerCase() != _originalHandle;
    final imageChanged = _selectedImage != null;
    final hasChanges = displayNameChanged || handleChanged || imageChanged;
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUploadingImage = true);

    try {
      await context.read<AuthProvider>().removeProfilePicture();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed')),
        );
      }
    } on AuthProviderException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showImagePickerOptions() {
    final auth = context.read<AuthProvider>();
    final hasProfilePicture = auth.profilePictureUrl != null;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (hasProfilePicture)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if handle is being changed and is not available
    final newHandle = _handleController.text.trim().toLowerCase();
    if (newHandle != _originalHandle && _isHandleAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Handle is not available')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final newDisplayName = _displayNameController.text.trim();

      // Upload new profile picture if selected
      if (_selectedImage != null) {
        await auth.uploadProfilePicture(_selectedImage!.path);
      }

      // Update display name in Cognito
      if (newDisplayName != auth.displayName) {
        await auth.updateDisplayName(newDisplayName);
      }

      // Update handle in DynamoDB via GraphQL
      if (newHandle != _originalHandle) {
        await auth.updateHandle(newHandle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.go('/profile');
      }
    } on AuthProviderException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            context.go('/profile');
          }
        } else {
          context.go('/profile');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  context.go('/profile');
                }
              } else {
                context.go('/profile');
              }
            },
          ),
          title: const Text('Edit Profile'),
          actions: [
            TextButton(
              onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 32),
                _buildDisplayNameField(),
                const SizedBox(height: 16),
                _buildHandleField(),
                const SizedBox(height: 16),
                _buildEmailField(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _isUploadingImage ? null : _showImagePickerOptions,
                child: Stack(
                  children: [
                    _buildAvatar(auth),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    if (_isUploadingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isUploadingImage ? null : _showImagePickerOptions,
                child: const Text('Change Photo'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(AuthProvider auth) {
    final profilePictureUrl = auth.profilePictureUrl;
    final displayText = (_displayNameController.text.isNotEmpty
            ? _displayNameController.text
            : auth.email ?? 'U')
        .substring(0, 1)
        .toUpperCase();

    if (_selectedImage != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_selectedImage!),
      );
    }

    if (profilePictureUrl != null) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: profilePictureUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
            errorWidget: (context, url, error) => Text(
              displayText,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Name',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _displayNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHandleField() {
    final handle = _handleController.text.trim().toLowerCase();
    final isChanged = handle != _originalHandle;

    Widget? suffixIcon;
    if (isChanged && handle.length >= 3) {
      if (_isCheckingHandle) {
        suffixIcon = const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      } else if (_isHandleAvailable == true) {
        suffixIcon = const Icon(Icons.check_circle, color: Colors.green);
      } else if (_isHandleAvailable == false) {
        suffixIcon = const Icon(Icons.cancel, color: Colors.red);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Handle',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _handleController,
          decoration: InputDecoration(
            hintText: 'your_handle',
            prefixIcon: const Icon(Icons.alternate_email),
            suffixIcon: suffixIcon,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a handle';
            }
            final trimmed = value.trim();
            if (trimmed.length < 3) {
              return 'Handle must be at least 3 characters';
            }
            if (trimmed.length > 20) {
              return 'Handle must be at most 20 characters';
            }
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
              return 'Only letters, numbers, and underscores';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Others can find you by @${handle.isNotEmpty ? handle : 'handle'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: auth.email ?? '',
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Email cannot be changed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        );
      },
    );
  }
}
