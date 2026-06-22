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
                // Top bar with user info
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF86EFAC).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF86EFAC),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Halo,',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF86EFAC),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
                  const Text(
                    'Saldo Saat Ini',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF86EFAC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrencyFull(balance),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.trending_up_rounded,
                                    size: 16,
                                    color: const Color(0xFF86EFAC),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Omset',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF86EFAC),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatCurrency(income),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
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
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.trending_down_rounded,
                                    size: 16,
                                    color: const Color(0xFF86EFAC),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Pengeluaran',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF86EFAC),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatCurrency(expense),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
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
            Icons.inventory_2_rounded,
            const Color(0xFF22C55E),
            () => context.go(RouteNames.ownerProducts),
          ),
          _buildActionButton(
            'Transaksi',
            Icons.receipt_long_rounded,
            const Color(0xFFDC2626),
            () => context.go(RouteNames.ownerBookkeeping),
          ),
          _buildActionButton(
            'Limbah',
            Icons.recycling_rounded,
            const Color(0xFF2563EB),
            () => context.go(RouteNames.ownerWaste),
          ),
          _buildActionButton(
            'Lokasi',
            Icons.store_rounded,
            const Color(0xFFD97706),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
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
          const Text(
            'Ringkasan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
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
                  Icons.inventory_2_rounded,
                  const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Transaksi',
                  '${financeVm.transactions.length}',
                  'bulan ini',
                  Icons.receipt_long_rounded,
                  const Color(0xFF064E3B),
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
              const Text(
                'Transaksi Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.ownerBookkeeping),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF22C55E),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome
                  ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                  : const Color(0xFFDC2626).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIncome ? const Color(0xFF22C55E) : const Color(0xFFDC2626),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} ${_formatCurrency(amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isIncome ? const Color(0xFF22C55E) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
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
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF065F46),
                fontWeight: FontWeight.w500,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(int count) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD97706)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perhatian',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count produk stok menipis',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF78350F),
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
        color: const Color(0xFF86EFAC).withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF86EFAC).withValues(alpha: 0.5),
          width: 2,
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
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFF86EFAC),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
