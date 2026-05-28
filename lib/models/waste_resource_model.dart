import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model representing a waste resource tracked by an agrarian SME.
///
/// Supports the circular economy feature of the ALPACA platform by helping
/// business owners track waste materials that can potentially be reused
/// or repurposed in other processes.
class WasteResourceModel extends Equatable {
  /// Unique identifier for the waste resource.
  final String id;

  /// Name of the waste material.
  final String wasteName;

  /// Quantity of the waste resource available.
  final double quantity;

  /// Unit of measurement (e.g., kg, liters, pcs).
  final String unit;

  /// Category of the waste (e.g., organic, packaging, byproduct).
  final String category;

  /// Whether this waste material can be reused or repurposed.
  final bool reusable;

  /// Notes on how this waste can be processed or repurposed.
  final String? processingNotes;

  /// ID of the business owner who generated this waste.
  final String ownerId;

  /// Timestamp when the waste resource record was created.
  final DateTime createdAt;

  /// Timestamp when the waste resource record was last updated.
  final DateTime updatedAt;

  const WasteResourceModel({
    required this.id,
    required this.wasteName,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.reusable,
    this.processingNotes,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [WasteResourceModel] from a Firestore document map.
  factory WasteResourceModel.fromJson(Map<String, dynamic> json) {
    return WasteResourceModel(
      id: json['id'] as String,
      wasteName: json['wasteName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      category: json['category'] as String,
      reusable: json['reusable'] as bool,
      processingNotes: json['processingNotes'] as String?,
      ownerId: json['ownerId'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this [WasteResourceModel] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wasteName': wasteName,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'reusable': reusable,
      'processingNotes': processingNotes,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates a copy of this [WasteResourceModel] with the given fields replaced.
  WasteResourceModel copyWith({
    String? id,
    String? wasteName,
    double? quantity,
    String? unit,
    String? category,
    bool? reusable,
    String? processingNotes,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WasteResourceModel(
      id: id ?? this.id,
      wasteName: wasteName ?? this.wasteName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      reusable: reusable ?? this.reusable,
      processingNotes: processingNotes ?? this.processingNotes,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        wasteName,
        quantity,
        unit,
        category,
        reusable,
        processingNotes,
        ownerId,
        createdAt,
        updatedAt,
      ];
}
