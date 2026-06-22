/// Business onboarding screen after registration.
///
/// Collects business name, description, and location for new UMKM owners.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';
import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/widgets/platform_map.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';
import 'package:alpaca_mobile/core/exceptions/app_exception.dart';

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
  final MapController _mapController = MapController();

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
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await context.read<LocationViewModel>().getCurrentDeviceLocation();
      setState(() {
        _selectedLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_selectedLocation, 15);

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
            content: Text(e is AppException ? e.message : e.toString()),
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Setup Bisnis Anda',
          style: AppText.ui(size: 17, weight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isCheckingUser
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Menyiapkan akun Anda...'),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        style: AppText.display(
                          size: 28,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Informasi ini akan ditampilkan di showcase publik',
                        style: AppText.ui(
                          size: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Business Name
                      Text(
                        'Nama Usaha',
                        style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: AppText.ui(size: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Warung Kopi Ibu Ani',
                          hintStyle: AppText.ui(size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                          prefixIcon: const Icon(Icons.business_outlined, size: 20),
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
                      Text(
                        'Deskripsi (Opsional)',
                        style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        style: AppText.ui(size: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Ceritakan tentang bisnis Anda',
                          hintStyle: AppText.ui(size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                          prefixIcon: const Icon(Icons.description_outlined, size: 20),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
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
                              style: AppText.ui(
                                size: 15,
                                weight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 16),
                            label: Text(
                              'Dapatkan Koordinat',
                              style: AppText.ui(size: 12, weight: FontWeight.w600, color: AppColors.primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap pada peta untuk menandai lokasi bisnis Anda',
                        style: AppText.ui(
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: PlatformMap(
                          initialCameraPosition: (
                            target: _selectedLocation,
                            zoom: 15.0,
                          ),
                          markers: [
                            Marker(
                              point: _selectedLocation,
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                          onTap: (latLng) {
                            setState(() => _selectedLocation = latLng);
                          },
                          mapController: _mapController,
                          myLocationButtonEnabled: false,
                          myLocationEnabled: true,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      AlpacaPrimaryButton(
                        label: 'Simpan dan Lanjutkan',
                        isLoading: _isSaving,
                        onPressed: _saveAndContinue,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
