/// Profile screen for business owners.
///
/// Displays user information, business summary, and provides
/// options to edit profile and logout.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/models/user_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';

/// Screen displaying the owner's profile information.
///
/// Features:
/// - User avatar/photo
/// - Display name, email, role
/// - Edit profile button
/// - Business info summary
/// - Logout button
/// - App version info
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
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
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
      backgroundColor: const Color(0xFFF9FAFB),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(context, user),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildUserInfoCard(context, user),
                        const SizedBox(height: 16),
                        if (locationVm.businessLocation != null)
                          _buildBusinessInfoCard(context, locationVm),
                        if (locationVm.businessLocation != null)
                          const SizedBox(height: 16),
                        _buildActionsCard(context),
                        const SizedBox(height: 24),
                        Text(
                          'ALPACA v1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Platform Digitalisasi UMKM Agraris',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
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

  Widget _buildHeader(BuildContext context, UserModel user) {
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 20, 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.go(RouteNames.ownerDashboard),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Profil',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF86EFAC).withValues(alpha: 0.2),
                    backgroundImage: user.photoUrl != null && _isValidUrl(user.photoUrl!) ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null || !_isValidUrl(user.photoUrl!)
                        ? Text(
                            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              color: Color(0xFF86EFAC),
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF86EFAC).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF86EFAC).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _roleLabel(user.role),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF86EFAC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 20,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informasi Akun',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow(
            context,
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            icon: Icons.phone_outlined,
            label: 'Telepon',
            value: user.phoneNumber ?? 'Belum diatur',
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.store_outlined,
                  size: 20,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informasi Bisnis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow(
            context,
            icon: Icons.business_outlined,
            label: 'Nama Bisnis',
            value: business.businessName,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            icon: Icons.location_on_outlined,
            label: 'Alamat',
            value: business.address,
          ),
          if (business.description != null &&
              business.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF22C55E)),
            ),
            title: const Text(
              'Edit Profil',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur edit profil akan segera hadir.'),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFFD97706)),
            ),
            title: const Text(
              'Kelola Lokasi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            onTap: () => context.push(RouteNames.ownerLocation),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, size: 20, color: Color(0xFFDC2626)),
            ),
            title: const Text(
              'Keluar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
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
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
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
