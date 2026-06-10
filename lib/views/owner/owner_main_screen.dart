import 'package:flutter/material.dart';
import 'package:alpaca_mobile/views/owner/owner_dashboard_screen.dart';
import 'package:alpaca_mobile/views/owner/products_screen.dart';
import 'package:alpaca_mobile/views/owner/bookkeeping_screen.dart';
import 'package:alpaca_mobile/views/owner/waste_tracking_screen.dart';
import 'package:alpaca_mobile/views/owner/profile_screen.dart';

class OwnerMainScreen extends StatefulWidget {
  const OwnerMainScreen({super.key});

  @override
  State<OwnerMainScreen> createState() => _OwnerMainScreenState();
}

class _OwnerMainScreenState extends State<OwnerMainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    OwnerDashboardScreen(),
    ProductsScreen(),
    BookkeepingScreen(),
    WasteTrackingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                _buildNavItem(1, Icons.inventory_2_rounded, 'Produk'),
                _buildNavItem(2, Icons.account_balance_wallet_rounded, 'Keuangan'),
                _buildNavItem(3, Icons.recycling_rounded, 'Limbah'),
                _buildNavItem(4, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
