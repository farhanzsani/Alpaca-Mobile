/// CustomerProfileScreen — Account & settings for customer.
///
/// Redesigned following ALPACA design guidelines:
/// solid primary green header, clean avatar, grouped menu cards,
/// Plus Jakarta Sans typography throughout.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';

/// Customer profile screen showing user info and app settings.
class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  bool _isValidNetworkUrl(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasScheme &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _logout(BuildContext context) async {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Keluar Akun', style: AppText.display(size: 20)),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: AppText.ui(size: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
                style: AppText.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text('Keluar',
                style: AppText.ui(
                    size: 14, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthViewModel>().logout();
      if (context.mounted) {
        context.go(RouteNames.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;
    final photoUrl = user?.photoUrl;
    final hasPhoto = _isValidNetworkUrl(photoUrl);
    final initial = (user?.displayName.isNotEmpty == true
            ? user!.displayName.substring(0, 1)
            : 'U')
        .toUpperCase();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Profile header ──────────────────────────────────────────────
          _ProfileHeader(
            name: user?.displayName ?? 'Pengguna',
            email: user?.email ?? '',
            initial: initial,
            hasPhoto: hasPhoto,
            photoUrl: photoUrl,
          ),

          // ── Menu sections ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account section
                Text('Akun', style: AppText.label()),
                const SizedBox(height: AppSpacing.sm),
                _MenuCard(
                  items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Informasi Profil',
                      subtitle: 'Lihat dan edit data diri Anda',
                      onTap: () => context.push(RouteNames.profileEdit),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // App section
                Text('Aplikasi', style: AppText.label()),
                const SizedBox(height: AppSpacing.sm),
                _MenuCard(
                  items: [
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Tentang ALPACA',
                      subtitle: 'Versi 1.0.0',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'ALPACA',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            '© 2026 ALPACA Team. All rights reserved.',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Logout
                Text('Sesi', style: AppText.label()),
                const SizedBox(height: AppSpacing.sm),
                _LogoutCard(onTap: () => _logout(context)),

                const SizedBox(height: AppSpacing.xxl),

                // Version footer
                Center(
                  child: Text(
                    'ALPACA v1.0.0 · Platform UMKM Agraris',
                    style: AppText.micro(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String initial;
  final bool hasPhoto;
  final String? photoUrl;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.initial,
    required this.hasPhoto,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.primaryDark,
      padding: EdgeInsets.fromLTRB(
          AppSpacing.screenH, topPad + AppSpacing.lg, AppSpacing.screenH, AppSpacing.xl),
      child: Column(
        children: [
          // Page label
          Row(
            children: [
              Text(
                'Profil Saya',
                style: AppText.ui(
                  size: 13,
                  weight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.primary,
              backgroundImage: hasPhoto ? NetworkImage(photoUrl!.trim()) : null,
              child: !hasPhoto
                  ? Text(
                      initial,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 32,
                        color: Colors.white,
                        height: 1,
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            name,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 22,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: AppText.ui(
              size: 13,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Components ───────────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card(),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildMenuTile(item),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.border,
                  indent: AppSpacing.screenH,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuTile(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(item.icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: AppText.ui(size: 14, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: AppText.label()),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Keluar dari Akun',
                style: AppText.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.error),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
