import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/reading_location.dart';
import '../providers/books_provider.dart';
import '../providers/locations_provider.dart';

class LocationDetailScreen extends StatelessWidget {
  final String locationId;

  const LocationDetailScreen({super.key, required this.locationId});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationsProvider>(
      builder: (context, provider, _) {
        final location = provider.locations
            .where((l) => l.locationId == locationId)
            .firstOrNull;

        if (location == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Location')),
            body: const Center(child: Text('Location not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(location.locationName),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete(context, provider, location);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Static map
                SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter:
                          LatLng(location.latitude, location.longitude),
                      initialZoom: 13.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.betterreads.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                                location.latitude, location.longitude),
                            width: 40,
                            height: 40,
                            child: Icon(
                              location.bookId != null
                                  ? Icons.menu_book
                                  : Icons.place,
                              color: Theme.of(context).colorScheme.primary,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.locationName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (location.address != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location.address!,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.yMMMd().format(location.createdAt),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      if (location.bookId != null) ...[
                        const SizedBox(height: 16),
                        Builder(builder: (context) {
                          final userBook = context.read<BooksProvider>().getUserBook(location.bookId!);
                          final title = userBook?.book?.title ?? location.bookId!;
                          final coverUrl = userBook?.book?.coverUrl;
                          return Card(
                            child: ListTile(
                              leading: coverUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(coverUrl, width: 40, height: 56, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.menu_book),
                                      ),
                                    )
                                  : const Icon(Icons.menu_book),
                              title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/book/${location.bookId}'),
                            ),
                          );
                        }),
                      ],
                      if (location.notes != null &&
                          location.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Notes',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(location.notes!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    LocationsProvider provider,
    ReadingLocation location,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text(
            'Delete "${location.locationName}" from your reading map?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await provider.deleteLocation(location.locationId);
                if (context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
