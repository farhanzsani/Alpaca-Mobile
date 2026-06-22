import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';
import 'package:alpaca_mobile/models/user_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';

/// Screen displaying the owner's profile information.
class ProfileScreen extends StatefulWidget {
  /// Creates a [ProfileScreen].
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusinessInfo();
    });
  }

  void _loadBusinessInfo() {
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id;
    if (userId != null) {
      context.read<LocationViewModel>().getCurrentLocation(userId);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Keluar',
          style: AppText.sectionHeader(color: AppColors.textPrimary),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun?',
          style: AppText.ui(size: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: AppText.ui(size: 14, weight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Keluar',
              style: AppText.ui(size: 14, weight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthViewModel>().logout();
      if (mounted) {
        context.go(RouteNames.login);
      }
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.ownerUmkm:
        return 'Pemilik UMKM';
      case UserRole.customer:
        return 'Pelanggan';
    }
  }

  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final locationVm = context.watch<LocationViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go(RouteNames.ownerDashboard),
        ),
        title: Text(
          'Profil',
          style: AppText.sectionHeader(),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
                child: Column(
                  children: [
                    _buildProfileHeader(user),
                    const SizedBox(height: AppSpacing.lg),
                    _buildUserInfoCard(context, user),
                    const SizedBox(height: AppSpacing.md),
                    if (locationVm.businessLocation != null) ...[
                      _buildBusinessInfoCard(context, locationVm),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildActionsCard(context),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'ALPACA v1.0.0',
                      style: AppText.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Platform Digitalisasi UMKM Agraris',
                      style: AppText.ui(
                        size: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: user.photoUrl != null && _isValidUrl(user.photoUrl!) ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null || !_isValidUrl(user.photoUrl!)
                ? Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: AppText.ui(
                      size: 36,
                      weight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.displayName,
            style: AppText.ui(
              size: 20,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              _roleLabel(user.role),
              style: AppText.ui(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Informasi Akun',
                style: AppText.ui(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          _buildInfoRow(
            context,
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            icon: Icons.phone_outlined,
            label: 'Telepon',
            value: user.phoneNumber ?? 'Belum diatur',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Bergabung',
            value: _formatDate(user.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoCard(
      BuildContext context, LocationViewModel locationVm) {
    final business = locationVm.businessLocation!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.store_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Informasi Bisnis',
                style: AppText.ui(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          _buildInfoRow(
            context,
            icon: Icons.business_outlined,
            label: 'Nama Bisnis',
            value: business.businessName,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            icon: Icons.location_on_outlined,
            label: 'Alamat',
            value: business.address,
          ),
          if (business.description != null &&
              business.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow(
              context,
              icon: Icons.description_outlined,
              label: 'Deskripsi',
              value: business.description!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
            ),
            title: Text(
              'Edit Profil',
              style: AppText.ui(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              context.push(RouteNames.profileEdit);
            },
          ),
          const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
            ),
            title: Text(
              'Kelola Lokasi',
              style: AppText.ui(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () => context.push(RouteNames.ownerLocation),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.logout, size: 20, color: AppColors.error),
            ),
            title: Text(
              'Keluar',
              style: AppText.ui(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.ui(
                  size: 12,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppText.ui(
                  size: 14,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
