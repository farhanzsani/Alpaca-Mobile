/// CustomerMainScreen — Bottom navigation shell for customer flow.
///
/// Redesigned following ALPACA design guidelines:
/// primary green #2A5C45, Plus Jakarta Sans typography.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:alpaca_mobile/views/showcase/public_showcase_screen.dart';
import 'package:alpaca_mobile/views/showcase/nearby_stores_screen.dart';
import 'package:alpaca_mobile/views/showcase/favorites_screen.dart';
import 'package:alpaca_mobile/views/showcase/customer_profile_screen.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';

/// Main screen for customers with bottom navigation bar.
class CustomerMainScreen extends StatefulWidget {
  final int initialIndex;

  const CustomerMainScreen({super.key, this.initialIndex = 0});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  static const List<Widget> _screens = [
    PublicShowcaseScreen(),
    NearbyStoresScreen(),
    FavoritesScreen(),
    CustomerProfileScreen(),
  ];

  static const _navItems = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Beranda'),
    (icon: Icons.near_me_outlined, activeIcon: Icons.near_me_rounded, label: 'Terdekat'),
    (icon: Icons.favorite_outline_rounded, activeIcon: Icons.favorite_rounded, label: 'Favorit'),
    (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AlpacaBottomNav(
        selectedIndex: _selectedIndex,
        items: _navItems,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ─── Bottom Navigation ───────────────────────────────────────────────────────

class _AlpacaBottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<({IconData icon, IconData activeIcon, String label})> items;
  final ValueChanged<int> onTap;

  const _AlpacaBottomNav({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = i == selectedIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with active indicator dot
                        Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 24,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                        // Active indicator
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 16 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
