import 'dart:math';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/reading_location.dart';
import '../providers/books_provider.dart';
import '../providers/locations_provider.dart';
import '../providers/friends_provider.dart';
import '../utils/theme.dart';
import '../widgets/location_bottom_sheet.dart';

enum MapFilter { mySpots, friends, all }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  MapFilter _filter = MapFilter.mySpots;
  bool _friendsLoaded = false;
  double _currentZoom = 4.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationsProvider>().syncFromBackend();
    });
  }

  void _loadFriendLocations() {
    if (_friendsLoaded) return;
    _friendsLoaded = true;

    final friendsProvider = context.read<FriendsProvider>();
    final locationsProvider = context.read<LocationsProvider>();

    for (final friend in friendsProvider.friends) {
      locationsProvider.fetchFriendLocations(friend.friendId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LocationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.locations.isEmpty) {
            return _buildLoadingState();
          }

          if (provider.locations.isEmpty && _filter == MapFilter.mySpots) {
            return _buildEmptyState();
          }

          return Stack(
            children: [
              _buildMap(provider),
              // Warm parchment tint overlay
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFF5E6D3).withValues(alpha: 0.08),
                        Colors.transparent,
                        const Color(0xFFF5E6D3).withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
              // Top fade for filter bar area
              IgnorePointer(
                child: Container(
                  height: MediaQuery.of(context).padding.top + 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFAF6F1).withValues(alpha: 0.85),
                        const Color(0xFFFAF6F1).withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom fade for controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFFFAF6F1).withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildHeader(provider),
              _buildBottomControls(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFFFAF6F1),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your reading map...',
              style: TextStyle(
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(30.0, -20.0),
            initialZoom: 2.5,
          ),
          children: [
            _buildTileLayer(),
          ],
        ),
        // Strong warm overlay for empty state
        IgnorePointer(
          child: Container(
            color: const Color(0xFFFAF6F1).withValues(alpha: 0.6),
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stacked book icons
                SizedBox(
                  height: 80,
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 10,
                        child: Transform.rotate(
                          angle: -0.15,
                          child: _buildMiniBook(const Color(0xFF8B4513)),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        child: Transform.rotate(
                          angle: 0.15,
                          child: _buildMiniBook(const Color(0xFF2D4A3E)),
                        ),
                      ),
                      _buildMiniBook(const Color(0xFFB8860B)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Reading Journey',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C1810),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pin the places where stories\ncome alive for you',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => context.push('/add-location'),
                  icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                  label: const Text('Drop Your First Pin'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBook(Color color) {
    return Container(
      width: 36,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.auto_stories, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildTileLayer() {
    // Positron: ultra-clean, light gray base that takes on our warm overlay nicely
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.betterreads.app',
    );
  }

  Widget _buildMap(LocationsProvider provider) {
    final markers = _buildMarkers(provider);

    LatLng center = const LatLng(30.0, -20.0);
    double zoom = 2.5;

    if (provider.locations.isNotEmpty) {
      final first = provider.locations.first;
      center = LatLng(first.latitude, first.longitude);
      zoom = 5.0;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onPositionChanged: (position, hasGesture) {
          if (position.zoom != _currentZoom) {
            setState(() => _currentZoom = position.zoom);
          }
        },
      ),
      children: [
        _buildTileLayer(),
        MarkerLayer(markers: markers),
      ],
    );
  }

  List<Marker> _buildMarkers(LocationsProvider provider) {
    final allLocations = <({ReadingLocation location, bool isOwn})>[];

    if (_filter == MapFilter.mySpots || _filter == MapFilter.all) {
      for (final location in provider.locations) {
        allLocations.add((location: location, isOwn: true));
      }
    }

    if (_filter == MapFilter.friends || _filter == MapFilter.all) {
      _loadFriendLocations();
      for (final location in provider.allFriendLocations) {
        allLocations.add((location: location, isOwn: false));
      }
    }

    final metersPerPixel = 156543.0 / pow(2, _currentZoom);
    final clusterDistanceMeters = metersPerPixel * 50;

    final groups = <List<({ReadingLocation location, bool isOwn})>>[];
    final used = <int>{};

    for (var i = 0; i < allLocations.length; i++) {
      if (used.contains(i)) continue;
      final group = [allLocations[i]];
      used.add(i);
      for (var j = i + 1; j < allLocations.length; j++) {
        if (used.contains(j)) continue;
        final dist = _distanceBetween(
          allLocations[i].location, allLocations[j].location,
        );
        if (dist < clusterDistanceMeters) {
          group.add(allLocations[j]);
          used.add(j);
        }
      }
      groups.add(group);
    }

    return groups.map((group) {
      final first = group.first;
      if (group.length == 1) {
        return _buildSingleMarker(first.location, first.isOwn);
      } else {
        return _buildClusterMarker(group);
      }
    }).toList();
  }

  double _distanceBetween(ReadingLocation a, ReadingLocation b) {
    const metersPerDegLat = 111320.0;
    final avgLat = (a.latitude + b.latitude) / 2;
    final metersPerDegLon = 111320.0 * cos(avgLat * pi / 180);
    final dx = (a.longitude - b.longitude) * metersPerDegLon;
    final dy = (a.latitude - b.latitude) * metersPerDegLat;
    return sqrt(dx * dx + dy * dy);
  }

  Marker _buildSingleMarker(ReadingLocation location, bool isOwn) {
    final booksProvider = context.read<BooksProvider>();
    final userBook = location.bookId != null
        ? booksProvider.getUserBook(location.bookId!)
        : null;
    final coverUrl = userBook?.book?.coverUrl;
    final isFriend = !isOwn;
    final accentColor = isFriend
        ? const Color(0xFF5B8A72)
        : AppTheme.primaryColor;

    return Marker(
      point: LatLng(location.latitude, location.longitude),
      width: 60,
      height: 78,
      child: GestureDetector(
        onTap: () => _showLocationSheet(location, isOwn),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Outer glow
            Container(
              width: 54,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 3),
                  color: accentColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _buildFallbackMarker(location, accentColor),
                          placeholder: (_, __) =>
                              _buildFallbackMarker(location, accentColor),
                        )
                      : _buildFallbackMarker(location, accentColor),
                ),
              ),
            ),
            // Triangle pointer
            CustomPaint(
              size: const Size(16, 10),
              painter: _PinTipPainter(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackMarker(ReadingLocation location, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          location.bookId != null ? Icons.auto_stories : Icons.bookmark_rounded,
          color: Colors.white.withValues(alpha: 0.9),
          size: 24,
        ),
      ),
    );
  }

  Marker _buildClusterMarker(
    List<({ReadingLocation location, bool isOwn})> group,
  ) {
    final first = group.first.location;
    // Gather cover URLs for the stack preview
    final booksProvider = context.read<BooksProvider>();
    final coverUrls = group
        .map((e) {
          final ub = booksProvider.getUserBook(e.location.bookId ?? '');
          return ub?.book?.coverUrl;
        })
        .where((url) => url != null)
        .take(3)
        .toList();

    return Marker(
      point: LatLng(first.latitude, first.longitude),
      width: 70,
      height: 80,
      child: GestureDetector(
        onTap: () => _showClusterSheet(group),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: coverUrls.isNotEmpty
                    ? Stack(
                        children: [
                          // Show first book cover as background
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: coverUrls.first!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(color: AppTheme.primaryColor),
                            ),
                          ),
                          // Dark overlay with count
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: Center(
                              child: Text(
                                '${group.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: AppTheme.primaryColor,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_stories,
                                color: Colors.white,
                                size: 18,
                              ),
                              Text(
                                '${group.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            CustomPaint(
              size: const Size(16, 10),
              painter: _PinTipPainter(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationSheet(ReadingLocation location, bool isOwn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: LocationBottomSheet(
          location: location,
          isOwn: isOwn,
        ),
      ),
    );
  }

  void _showClusterSheet(
    List<({ReadingLocation location, bool isOwn})> group,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.layers_rounded,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${group.length} books here',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C1810),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            group.first.location.locationName,
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
                const SizedBox(height: 20),
                ...group.map((entry) {
                  final loc = entry.location;
                  final userBook =
                      context.read<BooksProvider>().getUserBook(loc.bookId ?? '');
                  final title = userBook?.book?.title ?? loc.locationName;
                  final coverUrl = userBook?.book?.coverUrl;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.pop(context);
                          _showLocationSheet(loc, entry.isOwn);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFFFAF6F1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: coverUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: coverUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Center(
                                          child: Icon(
                                            Icons.auto_stories,
                                            size: 18,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.auto_stories,
                                          size: 18,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF2C1810),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.textMuted.withValues(alpha: 0.5),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(LocationsProvider provider) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildFilterChip('My Spots', Icons.bookmark_rounded, MapFilter.mySpots),
                _buildFilterChip('Friends', Icons.people_rounded, MapFilter.friends),
                _buildFilterChip('All', Icons.public_rounded, MapFilter.all),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, MapFilter filter) {
    final isSelected = _filter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(LocationsProvider provider) {
    final count = _filter == MapFilter.friends
        ? provider.allFriendLocations.length
        : _filter == MapFilter.all
            ? provider.locations.length + provider.allFriendLocations.length
            : provider.locations.length;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Spot count pill
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_stories,
                        size: 13,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count spot${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C1810),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // New Spot FAB
          GestureDetector(
            onTap: () => context.push('/add-location'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 6),
                  Text(
                    'New Spot',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the triangular pin tip below the marker
class _PinTipPainter extends CustomPainter {
  final Color color;

  _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    // Add shadow
    canvas.drawShadow(path, Colors.black, 3.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter old) => old.color != color;
}
