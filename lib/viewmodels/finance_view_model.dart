import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:alpaca_mobile/models/transaction_model.dart';
import 'package:alpaca_mobile/repositories/transaction_repository.dart';

/// Represents the current state of a view.
enum ViewState { initial, loading, loaded, error, empty }

/// ViewModel for financial transaction management.
///
/// Manages income and expense transactions, calculates totals,
/// and provides daily/monthly summaries for business owners.
class FinanceViewModel extends ChangeNotifier {
  /// Creates a [FinanceViewModel] with the given [TransactionRepository].
  FinanceViewModel({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository;

  final TransactionRepository _transactionRepository;

  // --- State ---

  ViewState _viewState = ViewState.initial;
  /// The current view state of this ViewModel.
  ViewState get viewState => _viewState;

  bool _isLoading = false;
  /// Whether an async operation is currently in progress.
  bool get isLoading => _isLoading;

  String? _error;
  /// The current error message, or null if no error.
  String? get error => _error;

  List<TransactionModel> _transactions = [];
  /// All loaded financial transactions.
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  /// Total income from all loaded transactions.
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Total expense from all loaded transactions.
  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Net balance (total income minus total expenses).
  double get balance => totalIncome - totalExpense;

  StreamSubscription<List<TransactionModel>>? _transactionsSubscription;

  // --- Methods ---

  /// Loads all transactions for the given [ownerId].
  ///
  /// Optionally filters by [startDate] and [endDate] for date range queries.
  Future<void> loadTransactions(
    String ownerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _transactionRepository.getTransactions(
      ownerId,
      startDate: startDate,
      endDate: endDate,
    );

    result.when(
      success: (transactions) {
        _transactions = transactions;
        _viewState =
            transactions.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Adds a new financial transaction.
  ///
  /// On success, the transaction (with the generated Firestore ID) is
  /// appended to the local list and totals are recalculated automatically
  /// via computed getters.
  Future<void> addTransaction(TransactionModel transaction) async {
    _setLoading(true);
    _clearError();

    final result = await _transactionRepository.addTransaction(transaction);

    result.when(
      success: (docId) {
        final savedTransaction = transaction.copyWith(id: docId);
        _transactions.add(savedTransaction);
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Updates an existing financial transaction.
  ///
  /// Replaces the transaction in the local list with the updated version.
  Future<void> updateTransaction(TransactionModel transaction) async {
    _setLoading(true);
    _clearError();

    final result = await _transactionRepository.updateTransaction(transaction);

    result.when(
      success: (_) {
        final index = _transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          _transactions[index] = transaction;
        }
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Deletes a transaction by its [transactionId].
  ///
  /// Removes the transaction from the local list on success.
  Future<void> deleteTransaction(String transactionId) async {
    _setLoading(true);
    _clearError();

    final result =
        await _transactionRepository.deleteTransaction(transactionId);

    result.when(
      success: (_) {
        _transactions.removeWhere((t) => t.id == transactionId);
        _viewState =
            _transactions.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Subscribes to realtime transaction updates for the given [ownerId].
  ///
  /// Cancels any existing subscription before creating a new one.
  void subscribeToTransactions(String ownerId) {
    _transactionsSubscription?.cancel();
    _viewState = ViewState.loading;
    notifyListeners();

    _transactionsSubscription =
        _transactionRepository.streamTransactions(ownerId).listen(
      (transactions) {
        _transactions = transactions;
        _viewState =
            transactions.isEmpty ? ViewState.empty : ViewState.loaded;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error.toString();
        _viewState = ViewState.error;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Returns a daily summary of transactions grouped by date.
  ///
  /// Each entry maps a date (with time zeroed out) to a list of
  /// transactions that occurred on that day.
  Map<DateTime, List<TransactionModel>> getDailySummary() {
    final Map<DateTime, List<TransactionModel>> summary = {};
    for (final transaction in _transactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      summary.putIfAbsent(dateKey, () => []).add(transaction);
    }
    return summary;
  }

  /// Returns a monthly summary with total income and expense per month.
  ///
  /// Each entry maps a month key (format: 'YYYY-MM') to a record
  /// containing the total income and expense for that month.
  Map<String, ({double income, double expense})> getMonthlySummary() {
    final Map<String, ({double income, double expense})> summary = {};
    for (final transaction in _transactions) {
      final monthKey =
          '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      final existing = summary[monthKey] ?? (income: 0.0, expense: 0.0);

      if (transaction.type == TransactionType.income) {
        summary[monthKey] = (
          income: existing.income + transaction.amount,
          expense: existing.expense,
        );
      } else {
        summary[monthKey] = (
          income: existing.income,
          expense: existing.expense + transaction.amount,
        );
      }
    }
    return summary;
  }

  void _clearError() {
    _error = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _viewState = ViewState.loading;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
