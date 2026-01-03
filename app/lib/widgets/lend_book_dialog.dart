import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lending_provider.dart';
import '../utils/theme.dart';

class LendBookDialog extends StatefulWidget {
  final String bookId;
  final String? bookTitle;

  const LendBookDialog({
    super.key,
    required this.bookId,
    this.bookTitle,
  });

  static Future<bool?> show(BuildContext context, String bookId, {String? bookTitle}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => LendBookDialog(bookId: bookId, bookTitle: bookTitle),
    );
  }

  @override
  State<LendBookDialog> createState() => _LendBookDialogState();
}

class _LendBookDialogState extends State<LendBookDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lendBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLending = true;
      _error = null;
    });

    try {
      final provider = context.read<LendingProvider>();
      await provider.lendBook(widget.bookId, _controller.text);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ArgumentError catch (e) {
      setState(() {
        _error = e.message;
        _isLending = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to lend book';
        _isLending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lend Book'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.bookTitle != null) ...[
              Text(
                'Lending: ${widget.bookTitle}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Borrower Name',
                hintText: 'Who are you lending to?',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) => _lendBook(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isLending ? null : _lendBook,
          icon: _isLending
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.surfaceColor,
                  ),
                )
              : const Icon(Icons.share, size: 18),
          label: const Text('Lend'),
        ),
      ],
    );
  }
}
