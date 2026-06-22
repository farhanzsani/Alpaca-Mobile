import 'package:flutter/material.dart';
import 'package:alpaca_mobile/views/owner/owner_dashboard_screen.dart';
import 'package:alpaca_mobile/views/owner/products_screen.dart';
import 'package:alpaca_mobile/views/owner/bookkeeping_screen.dart';
import 'package:alpaca_mobile/views/owner/waste_tracking_screen.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';

class OwnerMainScreen extends StatefulWidget {
  final int initialIndex;
  
  const OwnerMainScreen({super.key, this.initialIndex = 0});

  @override
  State<OwnerMainScreen> createState() => _OwnerMainScreenState();
}

class _OwnerMainScreenState extends State<OwnerMainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  static const List<Widget> _screens = [
    OwnerDashboardScreen(),
    ProductsScreen(),
    BookkeepingScreen(),
    WasteTrackingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Beranda'),
                _buildNavItem(1, Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'Produk'),
                _buildNavItem(2, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Keuangan'),
                _buildNavItem(3, Icons.recycling_rounded, Icons.recycling_outlined, 'Limbah'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppText.ui(
                  size: 10,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 12 : 0,
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
  }
}
