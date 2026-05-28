import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Type of financial transaction.
enum TransactionType {
  income,
  expense;

  String toJson() {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
    }
  }

  static TransactionType fromJson(String value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        return TransactionType.expense;
    }
  }
}

/// Model representing a financial transaction for an agrarian SME.
///
/// Tracks income and expenses to help business owners maintain
/// accurate financial records and monitor cash flow.
class TransactionModel extends Equatable {
  /// Unique identifier for the transaction.
  final String id;

  /// Type of transaction (income or expense).
  final TransactionType type;

  /// Title or name of the transaction.
  final String title;

  /// Monetary amount of the transaction.
  final double amount;

  /// Optional description providing additional details.
  final String? description;

  /// Date when the transaction occurred.
  final DateTime date;

  /// ID of the business owner who recorded this transaction.
  final String ownerId;

  /// Timestamp when the transaction record was created.
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    this.description,
    required this.date,
    required this.ownerId,
    required this.createdAt,
  });

  /// Creates a [TransactionModel] from a Firestore document map.
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.fromJson(json['type'] as String),
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      date: (json['date'] as Timestamp).toDate(),
      ownerId: json['ownerId'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this [TransactionModel] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'title': title,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy of this [TransactionModel] with the given fields replaced.
  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    String? title,
    double? amount,
    String? description,
    DateTime? date,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        amount,
        description,
        date,
        ownerId,
        createdAt,
      ];
}
