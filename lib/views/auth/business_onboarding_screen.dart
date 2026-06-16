/// Business onboarding screen after registration.
///
/// Collects business name, description, and location for new UMKM owners.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';

/// Onboarding screen for new UMKM owners to set up their business profile.
class BusinessOnboardingScreen extends StatefulWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  State<BusinessOnboardingScreen> createState() => _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState extends State<BusinessOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  LatLng _selectedLocation = const LatLng(-6.2088, 106.8456); // Jakarta default
  bool _isSaving = false;
  bool _isCheckingUser = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _checkExistingBusiness();
  }

  Future<void> _checkExistingBusiness() async {
    final authVm = context.read<AuthViewModel>();
    final locationVm = context.read<LocationViewModel>();
    final userId = authVm.currentUser?.id;

    if (userId != null) {
      await locationVm.getCurrentLocation(userId);
      
      // If business already exists, skip to dashboard
      if (mounted && locationVm.businessLocation != null) {
        context.go(RouteNames.ownerDashboard);
      }
    }

    if (mounted) {
      setState(() => _isCheckingUser = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan lokasi tidak aktif. Silakan aktifkan di pengaturan.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak permanen. Ubah di pengaturan aplikasi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Get current position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 15),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi berhasil didapatkan'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authVm = context.read<AuthViewModel>();
    final locationVm = context.read<LocationViewModel>();
    final apiClient = context.read<ApiClient>();
    final user = authVm.currentUser;
    
    if (user == null) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi berakhir, silakan login kembali'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Force sync user to backend first
    print('[Onboarding] Force syncing user to backend: ${user.email}');
    final syncResult = await apiClient.post(
      '/users/create',
      {
        'id': user.id,
        'email': user.email,
        'display_name': user.displayName,
        'role': user.role.toJson(),
        'photo_url': user.photoUrl ?? '',
        'phone_number': user.phoneNumber,
        'created_at': user.createdAt.toIso8601String(),
        'updated_at': user.updatedAt.toIso8601String(),
      },
      (_) => {},
    );
    
    if (syncResult.isSuccess) {
      print('[Onboarding] User sync successful');
    } else {
      print('[Onboarding] User sync failed: ${syncResult.exceptionOrNull?.message}');
    }
    
    // Wait a bit for backend to process
    await Future.delayed(const Duration(milliseconds: 500));

    final business = BusinessLocationModel(
      id: '',
      businessName: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      address: _addressController.text.trim(),
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      ownerId: user.id,
      ownerPhone: null, // Will be set from user profile
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await locationVm.saveBusinessLocation(business);

    if (mounted) {
      setState(() => _isSaving = false);

      if (locationVm.error == null) {
        context.go(RouteNames.ownerDashboard);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationVm.error ?? 'Gagal menyimpan data'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _saveAndContinue,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Bisnis Anda'),
        automaticallyImplyLeading: false,
      ),
      body: _isCheckingUser
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menyiapkan akun Anda...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
            // Header
            const Icon(
              Icons.storefront_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Lengkapi Profil Bisnis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Informasi ini akan ditampilkan di showcase publik',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Business Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Usaha',
                hintText: 'Contoh: Warung Kopi Ibu Ani',
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama usaha wajib diisi';
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
                hintText: 'Ceritakan tentang bisnis Anda',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
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
              textCapitalization: TextCapitalization.words,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Map
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lokasi Bisnis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Dapatkan Koordinat'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap pada peta untuk menandai lokasi bisnis Anda',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation,
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('business'),
                    position: _selectedLocation,
                    infoWindow: const InfoWindow(title: 'Lokasi Bisnis'),
                  ),
                },
                onTap: (latLng) {
                  setState(() => _selectedLocation = latLng);
                },
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationButtonEnabled: false,
                myLocationEnabled: true,
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveAndContinue,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: const Text('Simpan dan Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }
}
