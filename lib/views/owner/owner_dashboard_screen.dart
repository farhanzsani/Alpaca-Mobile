/// OwnerDashboardScreen - Main dashboard for UMKM owners.
///
/// Modern fintech-style dashboard with dark green theme.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/finance_view_model.dart';
import 'package:alpaca_mobile/viewmodels/product_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';
import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final List<String> _businessTips = [
    'Luangkan waktu beberapa menit setiap hari untuk meninjau kondisi bisnis.',
    'Catat setiap pengeluaran sekecil apa pun agar laporan tetap akurat.',
    'Pastikan stok produk utama selalu tersedia untuk pelanggan.',
    'Evaluasi produk dengan penjualan terbaik secara berkala.',
    'Lakukan pengecekan kas secara rutin untuk menghindari selisih.',
  ];

  String _currentTip = '';

  @override
  void initState() {
    super.initState();
    _currentTip = _businessTips[math.Random().nextInt(_businessTips.length)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBusinessLocation();
      _loadDashboardData();
    });
  }

  Future<void> _checkBusinessLocation() async {
    final authVm = context.read<AuthViewModel>();
    final locationVm = context.read<LocationViewModel>();
    final userId = authVm.currentUser?.id;

    if (userId != null) {
      await locationVm.getCurrentLocation(userId);
      
      if (mounted && locationVm.businessLocation == null) {
        context.go(RouteNames.businessOnboarding);
      }
    }
  }

  Future<void> _loadDashboardData() async {
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id;
    if (userId == null) return;

    context.read<ProductViewModel>().loadProducts(userId);
    
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    context.read<FinanceViewModel>().loadTransactions(userId, startDate: startDate, endDate: endDate);
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final financeVm = context.watch<FinanceViewModel>();
    final productVm = context.watch<ProductViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF86EFAC),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeaderSection(user?.displayName ?? 'Owner', financeVm),
              _buildQuickActions(),
              _buildContent(financeVm, productVm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(String name, FinanceViewModel financeVm) {
    final income = financeVm.totalIncome;
    final expense = financeVm.totalExpense;
    final balance = income - expense;

    return Consumer<AuthViewModel>(
      builder: (context, authVm, _) {
        final user = authVm.currentUser;
        
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
            child: Column(
              children: [
                // Top bar with user info
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo,',
                              style: AppText.ui(
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.70),
                                weight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              name,
                              style: AppText.ui(
                                size: 17,
                                color: Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => context.go(RouteNames.ownerProfile),
                        borderRadius: BorderRadius.circular(22),
                        child: _buildProfileAvatar(user),
                      ),
                    ],
                  ),
                ),
            
                // Balance section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        'Saldo Saat Ini',
                        style: AppText.ui(
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.70),
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCurrencyFull(balance),
                        style: AppText.ui(
                          size: 32,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.trending_up_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Omset',
                                        style: AppText.ui(
                                          size: 12,
                                          color: Colors.white.withValues(alpha: 0.80),
                                          weight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatCurrency(income),
                                    style: AppText.ui(
                                      size: 16,
                                      weight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.trending_down_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Pengeluaran',
                                        style: AppText.ui(
                                          size: 12,
                                          color: Colors.white.withValues(alpha: 0.80),
                                          weight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatCurrency(expense),
                                    style: AppText.ui(
                                      size: 16,
                                      weight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            'Produk',
            Icons.inventory_2_outlined,
            AppColors.primary,
            () => context.go(RouteNames.ownerProducts),
          ),
          _buildActionButton(
            'Transaksi',
            Icons.receipt_long_outlined,
            AppColors.error,
            () => context.go(RouteNames.ownerBookkeeping),
          ),
          _buildActionButton(
            'Limbah',
            Icons.recycling_outlined,
            AppColors.info,
            () => context.go(RouteNames.ownerWaste),
          ),
          _buildActionButton(
            'Lokasi',
            Icons.store_outlined,
            AppColors.warning,
            () => context.go(RouteNames.ownerLocation),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppText.ui(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FinanceViewModel financeVm, ProductViewModel productVm) {
    final lowStockCount = productVm.products.where((p) => p.isLowStock).length;
    final recentTransactions = financeVm.transactions.take(5).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTipsCard(),
          const SizedBox(height: 24),

          // ── Ringkasan (wide 2-column layout) ─────────────────────
          Text(
            'Ringkasan Usaha',
            style: AppText.ui(
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Produk',
                  '${productVm.products.length}',
                  'item terdaftar',
                  Icons.inventory_2_outlined,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Transaksi',
                  '${financeVm.transactions.length}',
                  'bulan ini',
                  Icons.receipt_long_outlined,
                  AppColors.primary,
                ),
              ),
            ],
          ),
          if (lowStockCount > 0) ...[
            const SizedBox(height: 12),
            _buildAlertCard(lowStockCount),
          ],
          const SizedBox(height: 24),

          // ── Transaksi Terbaru ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaksi Terbaru',
                style: AppText.ui(
                  size: 16,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.ownerBookkeeping),
                child: Text(
                  'Lihat Semua',
                  style: AppText.ui(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada transaksi',
                      style: AppText.ui(
                        size: 14,
                        color: AppColors.textSecondary,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentTransactions.map((transaction) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTransactionItem(transaction),
            )),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(dynamic transaction) {
    final isIncome = transaction.type.toString().contains('income');
    final amount = transaction.amount as double;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIncome ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title ?? 'Transaksi',
                  style: AppText.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.date),
                  style: AppText.ui(
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} ${_formatCurrency(amount)}',
            style: AppText.ui(
              size: 15,
              weight: FontWeight.w700,
              color: isIncome ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _currentTip,
              style: AppText.ui(
                size: 13,
                color: AppColors.onPrimaryContainer,
                weight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppText.ui(
              size: 24,
              weight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppText.ui(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppText.ui(
              size: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perhatian',
                  style: AppText.ui(
                    size: 13,
                    color: AppColors.onSecondaryContainer,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count produk stok menipis',
                  style: AppText.ui(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrencyFull(double value) {
    final formatter = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp$formatter';
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return 'Rp${(value / 1000000000).toStringAsFixed(1)}M';
    } else if (value >= 1000000) {
      return 'Rp${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return 'Rp${(value / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp${value.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Hari ini';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isValidUrl(String? url) {
    if (url == null) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildProfileAvatar(dynamic user) {
    final photoUrl = user?.photoUrl;
    final displayName = user?.displayName ?? '';
    
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: _isValidUrl(photoUrl)
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(displayName),
              )
            : _buildAvatarFallback(displayName),
      ),
    );
  }

  Widget _buildAvatarFallback(String displayName) {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: AppText.ui(
          size: 18,
          color: Colors.white,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}
