/// Transaction repository for the ALPACA application.
///
/// Provides CRUD operations, date-based filtering, and financial
/// aggregation for business transactions.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:alpaca_mobile/core/constants/firebase_constants.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/firestore_service.dart';
import 'package:alpaca_mobile/models/transaction_model.dart';

/// Repository handling financial transaction operations.
///
/// Supports income/expense tracking, date-range queries, and
/// financial summaries for agrarian SME owners.
class TransactionRepository {
  /// Creates a [TransactionRepository] with the required Firestore service.
  TransactionRepository({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  /// Adds a new transaction to Firestore.
  ///
  /// Returns the document ID of the created transaction.
  Future<Result<String>> addTransaction(TransactionModel transaction) async {
    return _firestoreService.addDocument(
      collection: FirebaseCollections.transactions,
      data: transaction.toJson(),
      id: transaction.id.isNotEmpty ? transaction.id : null,
    );
  }

  /// Updates an existing transaction.
  ///
  /// The [transaction] must have a valid [TransactionModel.id].
  Future<Result<void>> updateTransaction(TransactionModel transaction) async {
    return _firestoreService.updateDocument(
      collection: FirebaseCollections.transactions,
      id: transaction.id,
      data: transaction.toJson(),
    );
  }

  /// Deletes a transaction by its [id].
  Future<Result<void>> deleteTransaction(String id) async {
    return _firestoreService.deleteDocument(
      collection: FirebaseCollections.transactions,
      id: id,
    );
  }

  /// Retrieves transactions for a specific [ownerId] with optional date filtering.
  ///
  /// If [startDate] and [endDate] are provided, only transactions within
  /// that date range are returned.
  Future<Result<List<TransactionModel>>> getTransactions(
    String ownerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <WhereCondition>[
      WhereCondition(
        field: 'ownerId',
        operator: WhereOperator.isEqualTo,
        value: ownerId,
      ),
    ];

    if (startDate != null) {
      conditions.add(
        WhereCondition(
          field: 'date',
          operator: WhereOperator.isGreaterThanOrEqualTo,
          value: Timestamp.fromDate(startDate),
        ),
      );
    }

    if (endDate != null) {
      conditions.add(
        WhereCondition(
          field: 'date',
          operator: WhereOperator.isLessThanOrEqualTo,
          value: Timestamp.fromDate(endDate),
        ),
      );
    }

    return _firestoreService.getCollection<TransactionModel>(
      collection: FirebaseCollections.transactions,
      fromFirestore: (data, docId) =>
          TransactionModel.fromJson({...data, 'id': docId}),
      queryParams: QueryParams(
        where: conditions,
        orderBy: 'date',
        descending: true,
      ),
    );
  }

  /// Streams all transactions for a specific [ownerId] in real-time.
  Stream<List<TransactionModel>> streamTransactions(String ownerId) {
    return _firestoreService
        .streamCollection<TransactionModel>(
          collection: FirebaseCollections.transactions,
          fromFirestore: (data, docId) =>
              TransactionModel.fromJson({...data, 'id': docId}),
          queryParams: QueryParams(
            where: [
              WhereCondition(
                field: 'ownerId',
                operator: WhereOperator.isEqualTo,
                value: ownerId,
              ),
            ],
            orderBy: 'date',
            descending: true,
          ),
        )
        .map((result) => result.dataOrNull ?? []);
  }

  /// Retrieves all transactions for a specific [ownerId] on a given [date].
  Future<Result<List<TransactionModel>>> getDailyTransactions(
    String ownerId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    return getTransactions(ownerId, startDate: startOfDay, endDate: endOfDay);
  }

  /// Retrieves all transactions for a specific [ownerId] in a given [month] and [year].
  Future<Result<List<TransactionModel>>> getMonthlyTransactions(
    String ownerId,
    int year,
    int month,
  ) async {
    final startOfMonth = DateTime(year, month);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59, 999);

    return getTransactions(ownerId, startDate: startOfMonth, endDate: endOfMonth);
  }

  /// Calculates the total income for a specific [ownerId] within an optional date range.
  ///
  /// Returns the sum of all income transactions' amounts.
  Future<Result<double>> getTotalIncome(
    String ownerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await getTransactions(
      ownerId,
      startDate: startDate,
      endDate: endDate,
    );

    return result.when(
      success: (transactions) {
        final total = transactions
            .where((t) => t.type == TransactionType.income)
            .fold<double>(0.0, (sum, t) => sum + t.amount);
        return Result.success(total);
      },
      failure: (exception) => Result.failure(exception),
    );
  }

  /// Calculates the total expense for a specific [ownerId] within an optional date range.
  ///
  /// Returns the sum of all expense transactions' amounts.
  Future<Result<double>> getTotalExpense(
    String ownerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await getTransactions(
      ownerId,
      startDate: startDate,
      endDate: endDate,
    );

    return result.when(
      success: (transactions) {
        final total = transactions
            .where((t) => t.type == TransactionType.expense)
            .fold<double>(0.0, (sum, t) => sum + t.amount);
        return Result.success(total);
      },
      failure: (exception) => Result.failure(exception),
    );
  }
}
