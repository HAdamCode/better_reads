import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/books_provider.dart';
import '../utils/theme.dart';

class EditReadingDatesDialog extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? sessionId; // If provided, edits a reading session instead of UserBook dates

  const EditReadingDatesDialog({
    super.key,
    required this.bookId,
    required this.bookTitle,
    this.startedAt,
    this.finishedAt,
    this.sessionId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String bookId,
    required String bookTitle,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? sessionId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EditReadingDatesDialog(
        bookId: bookId,
        bookTitle: bookTitle,
        startedAt: startedAt,
        finishedAt: finishedAt,
        sessionId: sessionId,
      ),
    );
  }

  @override
  State<EditReadingDatesDialog> createState() => _EditReadingDatesDialogState();
}

class _EditReadingDatesDialogState extends State<EditReadingDatesDialog> {
  DateTime? _startedAt;
  DateTime? _finishedAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startedAt = widget.startedAt;
    _finishedAt = widget.finishedAt;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? (_startedAt ?? _finishedAt ?? DateTime.now())
        : (_finishedAt ?? DateTime.now());

    final firstDate = DateTime(2000);
    final lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.readColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startedAt = picked;
          // If start date is after finish date, clear finish date
          if (_finishedAt != null && picked.isAfter(_finishedAt!)) {
            _finishedAt = null;
          }
        } else {
          _finishedAt = picked;
          // If finish date is before start date, set start date to same day
          if (_startedAt != null && picked.isBefore(_startedAt!)) {
            _startedAt = picked;
          }
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final provider = context.read<BooksProvider>();

      if (widget.sessionId != null) {
        // Editing a reading session
        await provider.updateReadingSession(
          widget.bookId,
          widget.sessionId!,
          startedAt: _startedAt,
          finishedAt: _finishedAt,
        );
      } else {
        // Editing UserBook dates (legacy)
        await provider.updateReadingDates(
          widget.bookId,
          startedAt: _startedAt,
          finishedAt: _finishedAt,
        );
      }
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

  Future<void> _delete() async {
    if (widget.sessionId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reading Record?'),
        content: const Text(
          'This will permanently remove this reading session from your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await context.read<BooksProvider>().deleteReadingSession(
          widget.bookId,
          widget.sessionId!,
        );
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
          setState(() => _isSaving = false);
        }
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat.yMMMd().format(date);
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.readColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: AppTheme.readColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Dates',
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

            // Started reading date
            _buildDateRow(
              label: 'Started reading',
              date: _startedAt,
              icon: Icons.play_circle_outline,
              onTap: () => _selectDate(context, true),
              onClear: _startedAt != null
                  ? () => setState(() => _startedAt = null)
                  : null,
            ),

            const SizedBox(height: 16),

            // Finished reading date
            _buildDateRow(
              label: 'Finished reading',
              date: _finishedAt,
              icon: Icons.check_circle_outline,
              onTap: () => _selectDate(context, false),
              onClear: _finishedAt != null
                  ? () => setState(() => _finishedAt = null)
                  : null,
            ),

            // Reading duration hint
            if (_startedAt != null && _finishedAt != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.readColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AppTheme.readColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_startedAt!, _finishedAt!),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.readColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.readColor,
                    ),
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

            // Delete button (only for reading sessions)
            if (widget.sessionId != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isSaving ? null : _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete this reading record'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: date != null
                ? AppTheme.readColor.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: date != null ? AppTheme.readColor : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: date != null ? null : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (date == null)
              Icon(Icons.edit, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  String _formatDuration(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    if (days == 0) return 'Finished same day';
    if (days == 1) return 'Read in 1 day';
    if (days < 7) return 'Read in $days days';
    if (days < 30) {
      final weeks = (days / 7).round();
      return 'Read in $weeks week${weeks > 1 ? 's' : ''}';
    }
    final months = (days / 30).round();
    return 'Read in $months month${months > 1 ? 's' : ''}';
  }
}
