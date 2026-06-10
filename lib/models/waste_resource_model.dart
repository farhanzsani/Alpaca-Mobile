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
      id: json['id'] as String? ?? '',
      wasteName: json['waste_name'] as String? ?? json['wasteName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'kg',
      category: json['category'] as String? ?? '',
      reusable: json['reusable'] as bool? ?? false,
      processingNotes: json['processing_notes'] as String? ?? json['processingNotes'] as String?,
      ownerId: json['owner_id'] as String? ?? json['ownerId'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// Safely parses a DateTime from Firestore data.
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  /// Converts this [WasteResourceModel] to a Firestore-compatible map.
  /// Note: 'id' is excluded because Firestore uses the document ID separately.
  /// 'createdAt' and 'updatedAt' are excluded because FirestoreService
  /// adds server timestamps automatically.
  Map<String, dynamic> toJson() {
    return {
      'waste_name': wasteName,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'reusable': reusable,
      'processing_notes': processingNotes,
      'owner_id': ownerId,
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
