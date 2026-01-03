import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shelves_provider.dart';
import '../utils/theme.dart';

class CreateShelfDialog extends StatefulWidget {
  const CreateShelfDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const CreateShelfDialog(),
    );
  }

  @override
  State<CreateShelfDialog> createState() => _CreateShelfDialogState();
}

class _CreateShelfDialogState extends State<CreateShelfDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createShelf() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final provider = context.read<ShelvesProvider>();
      final shelf = await provider.createShelf(_controller.text);
      if (mounted) {
        Navigator.of(context).pop(shelf.id);
      }
    } on ArgumentError catch (e) {
      setState(() {
        _error = e.message;
        _isCreating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to create shelf';
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Shelf'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Shelf Name',
                hintText: 'e.g., Book Club, Favorites',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a shelf name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                if (value.trim().length > 50) {
                  return 'Name must be less than 50 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) => _createShelf(),
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
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCreating ? null : _createShelf,
          child: _isCreating
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.surfaceColor,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
