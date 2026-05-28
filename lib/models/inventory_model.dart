import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model representing an inventory item for an agrarian SME.
///
/// Tracks product stock levels, categories, and minimum stock thresholds
/// to help business owners manage their supply chain effectively.
class InventoryModel extends Equatable {
  /// Unique identifier for the inventory item.
  final String id;

  /// Name of the product in inventory.
  final String productName;

  /// Category of the inventory item (e.g., raw material, finished goods).
  final String category;

  /// Current quantity in stock.
  final int quantity;

  /// Minimum stock level before a restock alert is triggered.
  final int minimumStock;

  /// Unit of measurement (e.g., kg, pcs, liters).
  final String unit;

  /// ID of the business owner who owns this inventory item.
  final String ownerId;

  /// Timestamp when the inventory item was created.
  final DateTime createdAt;

  /// Timestamp when the inventory item was last updated.
  final DateTime updatedAt;

  const InventoryModel({
    required this.id,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.minimumStock,
    required this.unit,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an [InventoryModel] from a Firestore document map.
  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'] as String,
      productName: json['productName'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      minimumStock: json['minimumStock'] as int,
      unit: json['unit'] as String,
      ownerId: json['ownerId'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this [InventoryModel] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'category': category,
      'quantity': quantity,
      'minimumStock': minimumStock,
      'unit': unit,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates a copy of this [InventoryModel] with the given fields replaced.
  InventoryModel copyWith({
    String? id,
    String? productName,
    String? category,
    int? quantity,
    int? minimumStock,
    String? unit,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minimumStock: minimumStock ?? this.minimumStock,
      unit: unit ?? this.unit,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether the current stock is below the minimum threshold.
  bool get isLowStock => quantity < minimumStock;

  @override
  List<Object?> get props => [
        id,
        productName,
        category,
        quantity,
        minimumStock,
        unit,
        ownerId,
        createdAt,
        updatedAt,
      ];
}
