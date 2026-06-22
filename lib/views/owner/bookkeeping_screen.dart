/// BookkeepingScreen - Financial management for UMKM owners.
///
/// Displays income/expense summary, transaction list with tabs,
/// monthly filtering, and add transaction functionality.
/// Uses [FinanceViewModel] for state management.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:alpaca_mobile/models/transaction_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/finance_view_model.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bookkeeping screen with summary, tabs, and transaction management.
class BookkeepingScreen extends StatefulWidget {
  const BookkeepingScreen({super.key});

  @override
  State<BookkeepingScreen> createState() => _BookkeepingScreenState();
}

class _BookkeepingScreenState extends State<BookkeepingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  /// Currency formatter for Indonesian Rupiah.
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Date formatter for transaction display.
  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTransactions() {
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id;
    if (userId == null) return;

    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

    context.read<FinanceViewModel>().loadTransactions(
      userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Filters transactions by type based on current tab.
  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> transactions) {
    // Filter by selected date first
    final dateFiltered = transactions.where((t) {
      return t.date.year == _selectedDate.year &&
             t.date.month == _selectedDate.month &&
             t.date.day == _selectedDate.day;
    }).toList();
    
    // Then filter by tab
    switch (_tabController.index) {
      case 1:
        return dateFiltered.where((t) => t.type == TransactionType.income).toList();
      case 2:
        return dateFiltered.where((t) => t.type == TransactionType.expense).toList();
      default:
        return dateFiltered;
    }
  }
  
  /// Calculate daily summary
  Map<String, double> _getDailySummary(List<TransactionModel> transactions) {
    final dateFiltered = transactions.where((t) {
      return t.date.year == _selectedDate.year &&
             t.date.month == _selectedDate.month &&
             t.date.day == _selectedDate.day;
    }).toList();
    
    double income = 0;
    double expense = 0;
    
    for (var t in dateFiltered) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    
    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  @override
  Widget build(BuildContext context) {
    final financeVM = context.watch<FinanceViewModel>();
    final dailySummary = _getDailySummary(financeVM.transactions);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBarRow(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Summary card
                SliverToBoxAdapter(child: _buildSummaryCard(dailySummary)),
                // Date slider
                SliverToBoxAdapter(child: _buildDateSlider()),
                // Month filter title row
                SliverToBoxAdapter(child: _buildMonthFilter()),
                // Transaction list
                _buildTransactionSliver(
                  _getFilteredTransactions(financeVM.transactions),
                  financeVM,
                ),
                // FAB spacing at bottom
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context, financeVM),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHeader() {
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembukuan',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Kelola transaksi keuangan',
                      style: AppText.ui(
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.70),
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppText.ui(
          weight: FontWeight.w600,
          size: 13,
        ),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        onTap: (_) => setState(() {}),
        tabs: const [
          Tab(
            height: 40,
            child: Center(child: Text('Semua')),
          ),
          Tab(
            height: 40,
            child: Center(child: Text('Pemasukan')),
          ),
          Tab(
            height: 40,
            child: Center(child: Text('Pengeluaran')),
          ),
        ],
      ),
    );
  }

  /// Builds the financial summary card.
  Widget _buildSummaryCard(Map<String, double> summary) {
    final financeVM = context.watch<FinanceViewModel>();
    final income = summary['income'] ?? 0;
    final expense = summary['expense'] ?? 0;
    final balance = summary['balance'] ?? 0;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Total Balance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Total Saldo',
                  style: AppText.ui(
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.70),
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currencyFormat.format(financeVM.balance),
                  style: AppText.ui(
                    size: 28,
                    weight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Daily Balance
          Text(
            'Saldo Hari Ini',
            style: AppText.ui(
              size: 13,
              color: AppColors.textSecondary,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currencyFormat.format(balance),
            style: AppText.ui(
              size: 24,
              weight: FontWeight.w700,
              letterSpacing: -0.5,
              color: balance >= 0
                  ? AppColors.primary
                  : AppColors.error,
            ),
          ),
          const SizedBox(height: 20),

          // Income and expense row
          Row(
            children: [
              // Income
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.trending_up_rounded,
                            color: Color(0xFF22C55E),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pemasukan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currencyFormat.format(income),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF22C55E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Expense
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.trending_down_rounded,
                            color: Color(0xFFDC2626),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pengeluaran',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currencyFormat.format(expense),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the date slider for daily navigation.
  Widget _buildDateSlider() {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 30));
    final dayCount = today.difference(startDate).inDays + 1; // Only up to today
    
    return Container(
      height: 70,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dayCount,
        itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
          final isSelected = date.year == _selectedDate.year &&
                            date.month == _selectedDate.month &&
                            date.day == _selectedDate.day;
          final isToday = date.year == today.year &&
                         date.month == today.month &&
                         date.day == today.day;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 50,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF22C55E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFE5E7EB),
                  width: isToday && !isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE', 'id_ID').format(date).substring(0, 3),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the month filter row.
  Widget _buildMonthFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Transaksi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          InkWell(
            onTap: () => _showMonthlyMutation(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: Color(0xFF3B82F6),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Mutasi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
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

  /// Shows monthly mutation/statement view
  void _showMonthlyMutation() {
    DateTime selectedMutationMonth = _selectedMonth;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              final financeVM = context.watch<FinanceViewModel>();
              
              // Filter transactions by selected month
              final monthlyTransactions = financeVM.transactions.where((t) {
                return t.date.year == selectedMutationMonth.year &&
                       t.date.month == selectedMutationMonth.month;
              }).toList();
              
              double totalIncome = 0;
              double totalExpense = 0;
              
              for (var t in monthlyTransactions) {
                if (t.type == TransactionType.income) {
                  totalIncome += t.amount;
                } else {
                  totalExpense += t.amount;
                }
              }
              
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mutasi Bulanan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Month and Year selector
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedMutationMonth.month,
                            decoration: InputDecoration(
                              labelText: 'Bulan',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: List.generate(12, (index) {
                              final month = index + 1;
                              return DropdownMenuItem(
                                value: month,
                                child: Text(DateFormat('MMMM', 'id_ID').format(DateTime(2000, month))),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() {
                                  selectedMutationMonth = DateTime(
                                    selectedMutationMonth.year,
                                    value,
                                  );
                                  _selectedMonth = selectedMutationMonth;
                                });
                                _loadTransactions();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedMutationMonth.year,
                            decoration: InputDecoration(
                              labelText: 'Tahun',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: List.generate(
                              DateTime.now().year - 2020 + 1,
                              (index) => DropdownMenuItem(
                                value: 2020 + index,
                                child: Text('${2020 + index}'),
                              ),
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() {
                                  selectedMutationMonth = DateTime(
                                    value,
                                    selectedMutationMonth.month,
                                  );
                                  _selectedMonth = selectedMutationMonth;
                                });
                                _loadTransactions();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pemasukan',
                                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                              ),
                              Text(
                                _currencyFormat.format(totalIncome),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pengeluaran',
                                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                              ),
                              Text(
                                _currencyFormat.format(totalExpense),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Saldo Bersih',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                _currencyFormat.format(totalIncome - totalExpense),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: totalIncome - totalExpense >= 0
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Transaction count
                    Text(
                      '${monthlyTransactions.length} Transaksi',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Transaction list
                    Expanded(
                      child: monthlyTransactions.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada transaksi',
                                style: TextStyle(color: Color(0xFF9CA3AF)),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: monthlyTransactions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final transaction = monthlyTransactions[index];
                                final isIncome = transaction.type == TransactionType.income;
                                
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
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
                                              transaction.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _dateFormat.format(transaction.date),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${isIncome ? '+' : '-'} ${_currencyFormat.format(transaction.amount)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isIncome ? const Color(0xFF22C55E) : const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Builds the transaction list view.
  /// Builds transaction section as a Sliver for use inside CustomScrollView.
  Widget _buildTransactionSliver(
    List<TransactionModel> transactions,
    FinanceViewModel financeVM,
  ) {
    if (financeVM.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF22C55E)),
          ),
        ),
      );
    }

    if (transactions.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded, size: 56, color: Color(0xFFD1D5DB)),
              SizedBox(height: 16),
              Text(
                'Belum ada transaksi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tap tombol + untuk mencatat transaksi',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      sliver: SliverList.separated(
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final isIncome = transaction.type == TransactionType.income;

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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                        : const Color(0xFFDC2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isIncome
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dateFormat.format(transaction.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'} ${_currencyFormat.format(transaction.amount)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isIncome
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Hapus Transaksi'),
                            content: Text(
                              'Apakah Anda yakin ingin menghapus "${transaction.title}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          if (context.mounted) {
                            await context.read<FinanceViewModel>().deleteTransaction(transaction.id);
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows the add transaction bottom sheet.
  void _showAddTransactionSheet(
    BuildContext context,
    FinanceViewModel financeVM,
  ) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    TransactionType selectedType = TransactionType.income;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Center(
                        child: Text(
                          'Tambah Transaksi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Transaction type toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: TransactionType.values.map((type) {
                            final isSelected = selectedType == type;
                            final isIncome = type == TransactionType.income;
                            final label = isIncome ? 'Pemasukan' : 'Pengeluaran';

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    selectedType = type;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isIncome
                                            ? Colors.green.shade100
                                            : Colors.red.shade100)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? (isIncome
                                              ? Colors.green.shade700
                                              : Colors.red.shade700)
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title field
                      TextFormField(
                        controller: titleController,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Judul transaksi wajib diisi';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Judul',
                          hintText: 'Contoh: Penjualan sayur',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amount field
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Jumlah wajib diisi';
                          }
                          final amount = double.tryParse(
                            value.replaceAll('.', '').replaceAll(',', '.'),
                          );
                          if (amount == null || amount <= 0) {
                            return 'Masukkan jumlah yang valid';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Jumlah (Rp)',
                          hintText: '0',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi (opsional)',
                          hintText: 'Tambahkan catatan...',
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date picker
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF2E7D32),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setSheetState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _dateFormat.format(selectedDate),
                                style: const TextStyle(fontSize: 15),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                final amount = double.parse(
                                  amountController.text
                                      .replaceAll('.', '')
                                      .replaceAll(',', '.'),
                                );

                                final authVm = context.read<AuthViewModel>();
                                final userId = authVm.currentUser?.id ?? '';

                                final transaction = TransactionModel(
                                  id: '',
                                  type: selectedType,
                                  title: titleController.text.trim(),
                                  amount: amount,
                                  description: descriptionController.text.trim().isNotEmpty
                                      ? descriptionController.text.trim()
                                      : null,
                                  date: selectedDate,
                                  ownerId: userId,
                                  createdAt: DateTime.now(),
                                );

                                await financeVM.addTransaction(transaction);
                                
                                // Reload transactions after create
                                await financeVM.loadTransactions(userId);

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Transaksi berhasil ditambahkan',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
