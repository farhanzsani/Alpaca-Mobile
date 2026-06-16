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
import 'package:alpaca_mobile/core/widgets/platform_map.dart';
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
      ownerPhone: existingLocation?.ownerPhone, // Preserve existing
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
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: locationVm.isLoading && locationVm.businessLocation == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF22C55E),
                    ),
                  )
                : _buildForm(context, locationVm),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF86EFAC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Color(0xFF86EFAC),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi Bisnis',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Atur lokasi bisnis Anda',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF86EFAC),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, LocationViewModel locationVm) {
    final defaultPosition = _selectedPosition ??
        const LatLng(-6.200000, 106.816666); // Default: Jakarta

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map preview
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 240,
                child: PlatformMap(
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
            const SizedBox(height: 16),

            // GPS button
            OutlinedButton.icon(
              onPressed: _isGettingLocation ? null : _getCurrentPosition,
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF22C55E),
                      ),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                _isGettingLocation
                    ? 'Mendapatkan lokasi...'
                    : 'Gunakan GPS',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF22C55E),
                side: const BorderSide(color: Color(0xFF22C55E)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_selectedPosition != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 20,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_selectedPosition!.latitude.toStringAsFixed(6)}, '
                        '${_selectedPosition!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w500,
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
              decoration: InputDecoration(
                labelText: 'Nama Bisnis',
                hintText: 'Masukkan nama bisnis Anda',
                prefixIcon: const Icon(Icons.store_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF22C55E),
                    width: 2,
                  ),
                ),
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
              decoration: InputDecoration(
                labelText: 'Alamat',
                hintText: 'Masukkan alamat lengkap',
                prefixIcon: const Icon(Icons.location_on_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF22C55E),
                    width: 2,
                  ),
                ),
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
              decoration: InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Deskripsikan bisnis Anda',
                prefixIcon: const Icon(Icons.description_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF22C55E),
                    width: 2,
                  ),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Error message
            if (locationVm.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDC2626)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        locationVm.error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Save button
            ElevatedButton.icon(
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
                  : const Icon(Icons.save_rounded),
              label: Text(
                locationVm.businessLocation != null
                    ? 'Perbarui Lokasi'
                    : 'Simpan Lokasi',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
