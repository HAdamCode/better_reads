import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/books_provider.dart';
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.currentPage ?? 0;
    _controller = TextEditingController(text: _currentPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _progress {
    if (widget.totalPages == null || widget.totalPages == 0) return 0;
    return (_currentPage / widget.totalPages!).clamp(0.0, 1.0);
  }

  int get _percentage => (_progress * 100).round();

  void _updatePage(int value) {
    final maxPage = widget.totalPages ?? 9999;
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
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
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
                        _updatePage(parsed);
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

            // Total pages hint
            if (widget.totalPages != null) ...[
              const SizedBox(height: 8),
              Text(
                'of ${widget.totalPages} pages',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              'Hold buttons to adjust by 10',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 24),

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
