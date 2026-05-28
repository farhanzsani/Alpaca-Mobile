/// OwnerDashboardScreen - Main dashboard for UMKM owners.
///
/// Displays a welcome message, quick stats summary, and a grid
/// of feature cards for navigating to various business management tools.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/inventory_view_model.dart';
import 'package:alpaca_mobile/viewmodels/finance_view_model.dart';
import 'package:alpaca_mobile/core/routes/route_names.dart';

/// Data model for dashboard feature cards.
class _FeatureCard {
  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final String? subtitle;
}

/// Owner dashboard with feature grid and quick stats.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  /// Feature cards displayed in the dashboard grid.
  final List<_FeatureCard> _features = const [
    _FeatureCard(
      title: 'Inventaris',
      subtitle: 'Kelola stok barang',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF2E7D32),
      route: RouteNames.ownerInventory,
    ),
    _FeatureCard(
      title: 'Pembukuan',
      subtitle: 'Catat pemasukan & pengeluaran',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF1565C0),
      route: RouteNames.ownerBookkeeping,
    ),
    _FeatureCard(
      title: 'Media & Branding',
      subtitle: 'Kelola konten promosi',
      icon: Icons.campaign_outlined,
      color: Color(0xFFE65100),
      route: RouteNames.ownerMedia,
    ),
    _FeatureCard(
      title: 'Lokasi Usaha',
      subtitle: 'Atur lokasi & peta',
      icon: Icons.location_on_outlined,
      color: Color(0xFF6A1B9A),
      route: RouteNames.ownerLocation,
    ),
    _FeatureCard(
      title: 'Produk',
      subtitle: 'Kelola katalog produk',
      icon: Icons.storefront_outlined,
      color: Color(0xFF00838F),
      route: RouteNames.ownerProducts,
    ),
    _FeatureCard(
      title: 'Limbah',
      subtitle: 'Pantau pengelolaan limbah',
      icon: Icons.recycling_outlined,
      color: Color(0xFF4E342E),
      route: RouteNames.ownerWaste,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  /// Loads initial data for dashboard stats.
  Future<void> _loadDashboardData() async {
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id;
    if (userId == null) return;

    final inventoryVM = context.read<InventoryViewModel>();
    final financeVM = context.read<FinanceViewModel>();

    await Future.wait([
      inventoryVM.loadItems(userId),
      financeVM.loadTransactions(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final inventoryVM = context.watch<InventoryViewModel>();
    final financeVM = context.watch<FinanceViewModel>();
    final userName = authViewModel.currentUser?.displayName ?? 'Pengguna';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ALPACA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(context, authViewModel),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF2E7D32),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Halo, $userName!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola usaha Anda dengan mudah',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Quick stats
              _buildStatsSection(inventoryVM, financeVM),
              const SizedBox(height: 24),

              // Feature grid
              const Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the quick stats summary section.
  Widget _buildStatsSection(
    InventoryViewModel inventoryVM,
    FinanceViewModel financeVM,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Hari Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.inventory_2,
                label: 'Total Produk',
                value: '${inventoryVM.items.length}',
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                icon: Icons.warning_amber_rounded,
                label: 'Stok Rendah',
                value: '${inventoryVM.lowStockItems.length}',
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                icon: Icons.trending_up,
                label: 'Pemasukan',
                value: _formatCurrency(financeVM.totalIncome),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a single stat item widget.
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the feature cards grid.
  Widget _buildFeatureGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: _features.length,
          itemBuilder: (context, index) {
            final feature = _features[index];
            return _buildFeatureCardWidget(context, feature);
          },
        );
      },
    );
  }

  /// Builds a single feature card widget.
  Widget _buildFeatureCardWidget(BuildContext context, _FeatureCard feature) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push(feature.route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature.icon,
                  color: feature.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                feature.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (feature.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  feature.subtitle!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the navigation drawer.
  Widget _buildDrawer(BuildContext context, AuthViewModel authViewModel) {
    final user = authViewModel.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Drawer header
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'Pengguna'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
            ),
          ),

          // Menu items
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outlined),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.ownerProfile);
            },
          ),

          const Spacer(),

          // Logout
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Keluar',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              await authViewModel.logout();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Formats a number as Indonesian Rupiah currency.
  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rp${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp${amount.toStringAsFixed(0)}';
  }
}
