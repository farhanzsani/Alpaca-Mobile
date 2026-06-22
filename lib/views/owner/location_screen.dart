/// Location management screen for business owners.
///
/// Allows owners to input business details, get current GPS location,
/// view coordinates, preview on Google Maps, and save/update their
/// business location information.
library;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/theme/app_theme.dart';
import 'package:alpaca_mobile/core/widgets/platform_map.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';
import 'package:alpaca_mobile/core/exceptions/app_exception.dart';

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

  final MapController _mapController = MapController();
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
    _mapController.dispose();
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
      final pos = await context.read<LocationViewModel>().getCurrentDeviceLocation();
      setState(() {
        _selectedPosition = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_selectedPosition!, 15);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is AppException ? e.message : e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
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
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: locationVm.isLoading && locationVm.businessLocation == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
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
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi Bisnis',
                      style: AppText.ui(
                        size: 20,
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Atur lokasi bisnis Anda',
                      style: AppText.ui(
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.70),
                        weight: FontWeight.w400,
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map preview
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 240,
                child: PlatformMap(
                  initialCameraPosition: (
                    target: defaultPosition,
                    zoom: _selectedPosition != null ? 16.0 : 10.0,
                  ),
                  mapController: _mapController,
                  markers: _selectedPosition != null
                      ? [
                          Marker(
                            point: _selectedPosition!,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ]
                      : [],
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
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                _isGettingLocation
                    ? 'Mendapatkan lokasi...'
                    : 'Gunakan GPS',
                style: AppText.ui(size: 14, weight: FontWeight.w600, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
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
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_selectedPosition!.latitude.toStringAsFixed(6)}, '
                        '${_selectedPosition!.longitude.toStringAsFixed(6)}',
                        style: AppText.ui(
                          size: 13,
                          color: AppColors.primary,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Business name
            Text(
              'Nama Bisnis',
              style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: AppText.ui(size: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Masukkan nama bisnis Anda',
                hintStyle: AppText.ui(size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.store_outlined, size: 20),
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
            Text(
              'Alamat',
              style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _addressController,
              style: AppText.ui(size: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Masukkan alamat lengkap',
                hintStyle: AppText.ui(size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
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
            Text(
              'Deskripsi (Opsional)',
              style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              style: AppText.ui(size: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Deskripsikan bisnis Anda',
                hintStyle: AppText.ui(size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.description_outlined, size: 20),
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
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        locationVm.error!,
                        style: AppText.ui(
                          size: 13,
                          color: AppColors.error,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Save button
            AlpacaPrimaryButton(
              label: locationVm.businessLocation != null ? 'Perbarui Lokasi' : 'Simpan Lokasi',
              isLoading: locationVm.isLoading,
              onPressed: _saveLocation,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
