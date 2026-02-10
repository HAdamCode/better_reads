import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import '../services/graphql_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  String? _email;
  String? _handle;
  String? _displayName;
  String? _profilePictureKey;
  String? _profilePictureUrl;

  // Temporary storage for pending sign-up data
  String? _pendingHandle;
  String? _pendingDisplayName;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get email => _email;
  String? get handle => _handle;
  String? get displayName => _displayName;
  String? get profilePictureKey => _profilePictureKey;
  String? get profilePictureUrl => _profilePictureUrl;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        await _fetchUserAttributes();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _fetchUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      for (final attr in attributes) {
        if (attr.userAttributeKey == AuthUserAttributeKey.email) {
          _email = attr.value;
        } else if (attr.userAttributeKey == AuthUserAttributeKey.name) {
          _displayName = attr.value;
        }
      }

      final user = await Amplify.Auth.getCurrentUser();
      _userId = user.userId;

      // Fetch handle and avatar from DynamoDB
      await _fetchUserDataFromBackend();
    } catch (e) {
      debugPrint('Error fetching user attributes: $e');
    }
  }

  Future<void> _fetchUserDataFromBackend() async {
    if (_userId == null) return;
    try {
      final userData = await GraphQLService().getUser(_userId!);
      if (userData != null) {
        _handle = userData['handle'] as String?;
        final avatarUrl = userData['avatarUrl'] as String?;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          _profilePictureKey = avatarUrl;
          await _refreshProfilePictureUrl();
        }
        debugPrint('Loaded user data: handle=$_handle, avatarUrl=$_profilePictureKey');
      } else {
        // User record doesn't exist in DynamoDB - create it
        await _ensureUserRecordExists();
      }
    } catch (e) {
      debugPrint('Error fetching user data from backend: $e');
      // Try to create user record if fetch failed
      await _ensureUserRecordExists();
    }
  }

  Future<void> _ensureUserRecordExists() async {
    if (_userId == null || _email == null) return;
    try {
      // Generate a default handle from email
      final defaultHandle = _email!.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      await GraphQLService().createUser(
        email: _email!,
        handle: defaultHandle,
        displayName: _displayName ?? _email!.split('@').first,
      );
      _handle = defaultHandle;
      debugPrint('Created user record in DynamoDB');
    } catch (e) {
      debugPrint('Error creating user record: $e');
    }
  }

  Future<void> _refreshProfilePictureUrl() async {
    if (_profilePictureKey == null) return;
    try {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(_profilePictureKey!),
        options: const StorageGetUrlOptions(
          pluginOptions: S3GetUrlPluginOptions(
            expiresIn: Duration(hours: 1),
          ),
        ),
      ).result;
      _profilePictureUrl = result.url.toString();
    } catch (e) {
      debugPrint('Error getting profile picture URL: $e');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String handle,
  }) async {
    try {
      // Store pending data for after confirmation
      _pendingHandle = handle;
      _pendingDisplayName = displayName;

      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
            AuthUserAttributeKey.name: displayName,
          },
        ),
      );

      if (result.isSignUpComplete) {
        // Auto sign in after sign up
        await signIn(email: email, password: password);
      }
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );

      if (!result.isSignUpComplete) {
        throw AuthProviderException('Sign up confirmation failed');
      }
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> resendSignUpCode({required String email}) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: email);
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (result.isSignedIn) {
        await _fetchUserAttributes();
        _status = AuthStatus.authenticated;

        // Create user record in DynamoDB if this is a new sign-up
        if (_pendingHandle != null && _pendingDisplayName != null) {
          try {
            await GraphQLService().createUser(
              email: email,
              handle: _pendingHandle!,
              displayName: _pendingDisplayName!,
            );
            _handle = _pendingHandle;
          } catch (e) {
            debugPrint('Failed to create user record: $e');
          } finally {
            _pendingHandle = null;
            _pendingDisplayName = null;
          }
        }

        notifyListeners();
      }
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      _status = AuthStatus.unauthenticated;
      _userId = null;
      _email = null;
      _handle = null;
      _displayName = null;
      _profilePictureKey = null;
      _profilePictureUrl = null;
      _pendingHandle = null;
      _pendingDisplayName = null;
      notifyListeners();
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await Amplify.Auth.resetPassword(username: email);
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> confirmResetPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: AuthUserAttributeKey.name,
        value: displayName,
      );
      _displayName = displayName;
      notifyListeners();
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> updateHandle(String handle) async {
    try {
      await GraphQLService().updateUser(handle: handle);
      _handle = handle;
      notifyListeners();
    } catch (e) {
      throw AuthProviderException('Failed to update handle: $e');
    }
  }

  Future<void> uploadProfilePicture(String filePath) async {
    if (_userId == null) {
      throw AuthProviderException('User not authenticated');
    }

    try {
      final file = AWSFile.fromPath(filePath);
      final key = 'protected/$_userId/profile-picture.jpg';

      // Upload to S3
      await Amplify.Storage.uploadFile(
        localFile: file,
        path: StoragePath.fromString(key),
        options: const StorageUploadFileOptions(
          pluginOptions: S3UploadFilePluginOptions(
            getProperties: true,
          ),
        ),
      ).result;

      // Save the key to DynamoDB (more reliable than Cognito custom attributes)
      debugPrint('Saving profile picture key to DynamoDB: $key');
      await GraphQLService().updateUser(avatarUrl: key);
      debugPrint('Profile picture key saved successfully');

      _profilePictureKey = key;
      await _refreshProfilePictureUrl();
      notifyListeners();
    } on StorageException catch (e) {
      throw AuthProviderException('Failed to upload image: ${e.message}');
    } catch (e) {
      throw AuthProviderException('Failed to save profile picture: $e');
    }
  }

  Future<void> removeProfilePicture() async {
    if (_profilePictureKey == null) return;

    try {
      // Delete from S3
      await Amplify.Storage.remove(
        path: StoragePath.fromString(_profilePictureKey!),
      ).result;

      // Clear the avatarUrl in DynamoDB
      await GraphQLService().updateUser(avatarUrl: '');

      _profilePictureKey = null;
      _profilePictureUrl = null;
      notifyListeners();
    } on StorageException catch (e) {
      throw AuthProviderException('Failed to remove image: ${e.message}');
    } catch (e) {
      throw AuthProviderException('Failed to remove profile picture: $e');
    }
  }
}

class AuthProviderException implements Exception {
  final String message;

  AuthProviderException(this.message);

  @override
  String toString() => message;
}
