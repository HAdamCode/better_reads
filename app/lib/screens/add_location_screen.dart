import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/locations_provider.dart';
import '../widgets/book_picker_dialog.dart';

class AddLocationScreen extends StatefulWidget {
  final String? preselectedBookId;
  final String? preselectedBookTitle;

  const AddLocationScreen({
    super.key,
    this.preselectedBookId,
    this.preselectedBookTitle,
  });

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng _pinLocation = const LatLng(37.7749, -122.4194); // Default SF
  String? _selectedBookId;
  String? _selectedBookTitle;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.preselectedBookId;
    _selectedBookTitle = widget.preselectedBookTitle;
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _pinLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _reverseGeocode(_pinLocation);
    } catch (e) {
      debugPrint('Failed to get location: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final name = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? '';
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        if (_nameController.text.isEmpty) {
          _nameController.text = name;
        }
        if (_addressController.text.isEmpty) {
          _addressController.text = address;
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await context.read<LocationsProvider>().addLocation(
            bookId: _selectedBookId,
            latitude: _pinLocation.latitude,
            longitude: _pinLocation.longitude,
            locationName: _nameController.text.trim(),
            address: _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reading spot saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reading Spot'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map with draggable pin
                SizedBox(
                  height: 250,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _pinLocation,
                      initialZoom: 13.0,
                      onTap: (tapPosition, point) {
                        setState(() => _pinLocation = point);
                        _reverseGeocode(point);
                      },
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
                            point: _pinLocation,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Location Name',
                              hintText: 'e.g. Coffee shop in Denver',
                              prefixIcon: Icon(Icons.place),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address (optional)',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Book picker
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.menu_book,
                              color: _selectedBookId != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                            title: Text(
                              _selectedBookTitle ?? 'Link a book (optional)',
                              style: TextStyle(
                                color: _selectedBookTitle != null
                                    ? null
                                    : Colors.grey.shade600,
                              ),
                            ),
                            trailing: _selectedBookId != null
                                ? IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _selectedBookId = null;
                                        _selectedBookTitle = null;
                                      });
                                    },
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: () async {
                              final result = await showDialog<Map<String, String>>(
                                context: context,
                                builder: (context) => const BookPickerDialog(),
                              );
                              if (result != null) {
                                setState(() {
                                  _selectedBookId = result['bookId'];
                                  _selectedBookTitle = result['title'];
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              hintText: 'What were you reading here?',
                              prefixIcon: Icon(Icons.notes),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
