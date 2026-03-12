import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../providers/locations_provider.dart';
import '../utils/theme.dart';

class UpdateProgressDialog extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final int? currentPage;
  final int? totalPages;

  const UpdateProgressDialog({
    super.key,
    required this.bookId,
    required this.bookTitle,
    this.currentPage,
    this.totalPages,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String bookId,
    required String bookTitle,
    int? currentPage,
    int? totalPages,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => UpdateProgressDialog(
        bookId: bookId,
        bookTitle: bookTitle,
        currentPage: currentPage,
        totalPages: totalPages,
      ),
    );
  }

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  late TextEditingController _controller;
  late int _currentPage;
  int? _totalPages;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.currentPage ?? 0;
    _totalPages = widget.totalPages;
    _controller = TextEditingController(text: _currentPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _progress {
    if (_totalPages == null || _totalPages == 0) return 0;
    return (_currentPage / _totalPages!).clamp(0.0, 1.0);
  }

  int get _percentage => (_progress * 100).round();

  void _updatePage(int value) {
    if (_totalPages == null || _totalPages == 0) {
      _showEditTotalPagesDialog();
      return;
    }
    final maxPage = _totalPages ?? 9999;
    setState(() {
      _currentPage = value.clamp(0, maxPage);
      _controller.text = _currentPage.toString();
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<BooksProvider>().updateReadingProgress(
            widget.bookId,
            _currentPage,
          );
      if (mounted) {
        // Capture references before popping (dialog context becomes invalid after pop)
        final locationsProvider = context.read<LocationsProvider>();
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final router = GoRouter.of(context);
        Navigator.of(context).pop(true);
        _autoAddLocation(locationsProvider, scaffoldMessenger, router);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _autoAddLocation(
    LocationsProvider locationsProvider,
    ScaffoldMessengerState scaffoldMessenger,
    GoRouter router,
  ) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Skip if this book already has a location nearby (~500m)
      final existingSpots = locationsProvider.getLocationsForBook(widget.bookId);
      for (final spot in existingSpots) {
        final distance = Geolocator.distanceBetween(
          spot.latitude, spot.longitude,
          position.latitude, position.longitude,
        );
        if (distance < 500) return;
      }

      String locationName = '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          locationName = place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              locationName;
          address = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        }
      } catch (_) {}

      final location = await locationsProvider.addLocation(
        bookId: widget.bookId,
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
        address: address,
      );

      if (location != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Reading spot added: $locationName'),
            action: SnackBarAction(
              label: 'Edit',
              onPressed: () => router.push('/location/${location.locationId}'),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Auto-add location failed: $e');
    }
  }

  Future<void> _showEditTotalPagesDialog() async {
    final controller = TextEditingController(
      text: _totalPages?.toString() ?? '',
    );

    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Total Pages'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Total pages',
            hintText: 'Enter the number of pages',
          ),
          onSubmitted: (value) {
            final pages = int.tryParse(value);
            Navigator.of(context).pop(pages);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final pages = int.tryParse(controller.text);
              Navigator.of(context).pop(pages);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result > 0 && mounted) {
      try {
        await context.read<BooksProvider>().updateTotalPages(widget.bookId, result);
        if (mounted) {
          setState(() {
            _totalPages = result;
            // Clamp current page to new total
            if (_currentPage > result) {
              _currentPage = result;
              _controller.text = _currentPage.toString();
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Total pages set to $result')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e')),
          );
        }
      }
    }
  }

  Future<void> _finishBook() async {
    final booksProvider = context.read<BooksProvider>();
    // Get effective page count (may have been updated by user)
    final userBook = booksProvider.getUserBook(widget.bookId);
    final totalPages = userBook?.effectivePageCount;

    // Require total pages before finishing (needed for statistics)
    if (totalPages == null || totalPages <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set the total pages before finishing'),
        ),
      );
      await _showEditTotalPagesDialog();
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Update progress to total pages
      await booksProvider.updateReadingProgress(widget.bookId, totalPages);
      // Move to Read shelf
      await booksProvider.updateBookShelf(widget.bookId, ReadingStatus.read);
      if (mounted) {
        final locationsProvider = context.read<LocationsProvider>();
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final router = GoRouter.of(context);
        Navigator.of(context).pop(true);
        _autoAddLocation(locationsProvider, scaffoldMessenger, router);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to finish book: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with bookmark icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.currentlyReadingColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bookmark,
                    color: AppTheme.currentlyReadingColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.bookTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 12,
                backgroundColor: AppTheme.currentlyReadingColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(AppTheme.currentlyReadingColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_percentage% complete',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.currentlyReadingColor,
              ),
            ),

            const SizedBox(height: 24),

            // Page input with +/- buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus button
                _buildAdjustButton(
                  icon: Icons.remove,
                  onPressed: () => _updatePage(_currentPage - 1),
                  onLongPress: () => _updatePage(_currentPage - 10),
                ),

                const SizedBox(width: 16),

                // Page input field
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        final maxPage = _totalPages ?? 9999;
                        setState(() {
                          _currentPage = parsed.clamp(0, maxPage);
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Plus button
                _buildAdjustButton(
                  icon: Icons.add,
                  onPressed: () => _updatePage(_currentPage + 1),
                  onLongPress: () => _updatePage(_currentPage + 10),
                ),
              ],
            ),

            // Total pages hint (tappable to edit)
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showEditTotalPagesDialog,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (_totalPages != null && _totalPages! > 0)
                        ? 'of $_totalPages pages'
                        : 'Set total pages',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 14, color: AppTheme.primaryColor),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Hold buttons to adjust by 10',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 16),

            // Finish Book button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _finishBook,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Finish Book'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.readColor,
                  side: BorderSide(color: AppTheme.readColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback onPressed,
    required VoidCallback onLongPress,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.currentlyReadingColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: AppTheme.currentlyReadingColor),
          iconSize: 28,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}
