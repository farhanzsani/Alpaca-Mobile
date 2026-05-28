/// Location management screen for business owners.
///
/// Allows owners to input business details, get current GPS location,
/// view coordinates, preview on Google Maps, and save/update their
/// business location information.
library;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';

/// Screen for managing the business location of an owner.
///
/// Features:
/// - Form to input business details (name, address, description)
/// - Button to get current GPS location
/// - Display current coordinates
/// - Google Maps preview showing pin at business location
/// - Save/update button
class LocationScreen extends StatefulWidget {
  /// Creates a [LocationScreen].
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingLocation();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _loadExistingLocation() {
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id;
    if (userId != null) {
      context.read<LocationViewModel>().getCurrentLocation(userId);
    }
  }

  void _populateFields(BusinessLocationModel location) {
    _nameController.text = location.businessName;
    _addressController.text = location.address;
    _descriptionController.text = location.description ?? '';
    _selectedPosition = LatLng(location.latitude, location.longitude);
  }

  Future<void> _getCurrentPosition() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check location service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Layanan lokasi tidak aktif. Aktifkan GPS Anda.'),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin lokasi ditolak.'),
              ),
            );
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak secara permanen. '
                'Buka pengaturan untuk mengaktifkan.',
              ),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _selectedPosition = LatLng(position.latitude, position.longitude);
        });

        context.read<LocationViewModel>().setCurrentPosition(
              latitude: position.latitude,
              longitude: position.longitude,
            );

        // Animate map to new position
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedPosition!, 16),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lokasi terlebih dahulu menggunakan GPS.'),
        ),
      );
      return;
    }

    final authVm = context.read<AuthViewModel>();
    final locationVm = context.read<LocationViewModel>();
    final userId = authVm.currentUser?.id;

    if (userId == null) return;

    final now = DateTime.now();
    final existingLocation = locationVm.businessLocation;

    final location = BusinessLocationModel(
      id: existingLocation?.id ?? '',
      businessName: _nameController.text.trim(),
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      ownerId: userId,
      createdAt: existingLocation?.createdAt ?? now,
      updatedAt: now,
    );

    if (existingLocation != null && existingLocation.id.isNotEmpty) {
      await locationVm.updateBusinessLocation(location);
    } else {
      await locationVm.saveBusinessLocation(location);
    }

    if (mounted && locationVm.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi berhasil disimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationVm = context.watch<LocationViewModel>();

    // Populate fields when data is loaded
    if (locationVm.businessLocation != null &&
        _nameController.text.isEmpty) {
      _populateFields(locationVm.businessLocation!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Bisnis'),
      ),
      body: locationVm.isLoading && locationVm.businessLocation == null
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(context, locationVm),
    );
  }

  Widget _buildForm(BuildContext context, LocationViewModel locationVm) {
    final defaultPosition = _selectedPosition ??
        const LatLng(-6.200000, 106.816666); // Default: Jakarta

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map preview
            Card(
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 220,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: defaultPosition,
                    zoom: _selectedPosition != null ? 16 : 10,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _selectedPosition != null
                      ? {
                          Marker(
                            markerId: const MarkerId('business_location'),
                            position: _selectedPosition!,
                            infoWindow: InfoWindow(
                              title: _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : 'Lokasi Bisnis',
                            ),
                          ),
                        }
                      : {},
                  onTap: (position) {
                    setState(() => _selectedPosition = position);
                    context.read<LocationViewModel>().setCurrentPosition(
                          latitude: position.latitude,
                          longitude: position.longitude,
                        );
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // GPS button and coordinates
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGettingLocation ? null : _getCurrentPosition,
                    icon: _isGettingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _isGettingLocation
                          ? 'Mendapatkan lokasi...'
                          : 'Gunakan GPS',
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedPosition != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedPosition!.latitude.toStringAsFixed(6)}, '
                        '${_selectedPosition!.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Business name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Bisnis',
                hintText: 'Masukkan nama bisnis Anda',
                prefixIcon: Icon(Icons.store_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama bisnis wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                hintText: 'Masukkan alamat lengkap',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Deskripsikan bisnis Anda',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Error message
            if (locationVm.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  locationVm.error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Save button
            FilledButton.icon(
              onPressed: locationVm.isLoading ? null : _saveLocation,
              icon: locationVm.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                locationVm.businessLocation != null
                    ? 'Perbarui Lokasi'
                    : 'Simpan Lokasi',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
