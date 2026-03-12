import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reading_location.dart';
import '../providers/books_provider.dart';
import '../providers/locations_provider.dart';

class LocationBottomSheet extends StatelessWidget {
  final ReadingLocation location;
  final bool isOwn;

  const LocationBottomSheet({
    super.key,
    required this.location,
    required this.isOwn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Location name
          Text(
            location.locationName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          if (location.address != null) ...[
            const SizedBox(height: 4),
            Text(
              location.address!,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],

          const SizedBox(height: 8),
          Text(
            DateFormat.yMMMd().format(location.createdAt),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),

          if (location.bookId != null) ...[
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final userBook = context.read<BooksProvider>().getUserBook(location.bookId!);
              final title = userBook?.book?.title ?? location.bookId!;
              final coverUrl = userBook?.book?.coverUrl;
              return Card(
                child: ListTile(
                  leading: coverUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(coverUrl, width: 32, height: 48, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.menu_book),
                          ),
                        )
                      : const Icon(Icons.menu_book),
                  title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  dense: true,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/book/${location.bookId}');
                  },
                ),
              );
            }),
          ],

          if (location.notes != null && location.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              location.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/location/${location.locationId}');
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
              ),
              if (isOwn) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteLocation(context),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _deleteLocation(BuildContext context) {
    final provider = context.read<LocationsProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Location'),
        content:
            Text('Delete "${location.locationName}" from your reading map?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              Navigator.pop(context); // close bottom sheet
              try {
                await provider.deleteLocation(location.locationId);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Location deleted')),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
