import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../utils/theme.dart';
import 'shelf_picker_sheet.dart';

enum QuickAddButtonStyle {
  icon, // Icon button (for BookListTile trailing)
  badge, // Badge overlay (for BookCard)
}

class QuickAddButton extends StatefulWidget {
  final Book book;
  final QuickAddButtonStyle style;
  final VoidCallback? onAdded;

  const QuickAddButton({
    super.key,
    required this.book,
    this.style = QuickAddButtonStyle.icon,
    this.onAdded,
  });

  @override
  State<QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<QuickAddButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    final provider = context.read<BooksProvider>();
    final isInLibrary = provider.isBookInLibrary(widget.book.isbn);

    if (isInLibrary) {
      // Book already in library - open shelf picker
      ShelfPickerSheet.show(context, widget.book.isbn);
    } else {
      // Quick add to Want to Read
      setState(() => _isLoading = true);

      // Play success animation
      await _animationController.forward();
      await _animationController.reverse();

      await provider.addBookToShelf(widget.book, ReadingStatus.wantToRead);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to Want to Read'),
            action: SnackBarAction(
              label: 'Change',
              onPressed: () => ShelfPickerSheet.show(context, widget.book.isbn),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onAdded?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, provider, _) {
        final shelf = provider.getBookShelf(widget.book.isbn);
        final isInLibrary = shelf != null;

        return GestureDetector(
          onTap: _isLoading ? null : _onTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildButton(isInLibrary, shelf),
          ),
        );
      },
    );
  }

  Widget _buildButton(bool isInLibrary, ReadingStatus? shelf) {
    switch (widget.style) {
      case QuickAddButtonStyle.icon:
        return _buildIconButton(isInLibrary, shelf);
      case QuickAddButtonStyle.badge:
        return _buildBadgeButton(isInLibrary, shelf);
    }
  }

  Widget _buildIconButton(bool isInLibrary, ReadingStatus? shelf) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (isInLibrary) {
      return Icon(
        _getShelfIcon(shelf!),
        color: _getShelfColor(shelf),
        size: 24,
      );
    }

    return Icon(
      Icons.add_circle_outline,
      color: AppTheme.wantToReadColor,
      size: 24,
    );
  }

  Widget _buildBadgeButton(bool isInLibrary, ReadingStatus? shelf) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isInLibrary
            ? _getShelfColor(shelf!).withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isInLibrary ? _getShelfIcon(shelf!) : Icons.add_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                if (isInLibrary) ...[
                  const SizedBox(width: 3),
                  Text(
                    _getShortLabel(shelf!),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  IconData _getShelfIcon(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return Icons.bookmark;
      case ReadingStatus.currentlyReading:
        return Icons.menu_book;
      case ReadingStatus.read:
        return Icons.check_circle;
      case ReadingStatus.none:
        return Icons.add_rounded;
    }
  }

  Color _getShelfColor(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return AppTheme.wantToReadColor;
      case ReadingStatus.currentlyReading:
        return AppTheme.currentlyReadingColor;
      case ReadingStatus.read:
        return AppTheme.readColor;
      case ReadingStatus.none:
        return AppTheme.textMuted;
    }
  }

  String _getShortLabel(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return 'TBR';
      case ReadingStatus.currentlyReading:
        return 'Reading';
      case ReadingStatus.read:
        return 'Read';
      case ReadingStatus.none:
        return '';
    }
  }
}
