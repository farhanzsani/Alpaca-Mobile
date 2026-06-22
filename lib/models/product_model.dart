import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model representing a product listed by an agrarian SME on the ALPACA platform.
///
/// Products are items available for sale to customers and tourists,
/// including local culinary products, agricultural goods, and artisanal items.
class ProductModel extends Equatable {
  /// Unique identifier for the product.
  final String id;

  /// Name of the product.
  final String productName;

  /// Detailed description of the product.
  final String? description;

  /// Price of the product in local currency (IDR).
  final double price;

  /// URL to the product image.
  final String? imageUrl;

  /// ID of the business owner who listed this product.
  final String ownerId;

  /// Category of the product (e.g., food, beverage, handicraft).
  final String category;

  /// Whether the product is currently available for purchase.
  final bool isAvailable;

  /// Current stock quantity.
  final int quantity;

  /// Minimum stock threshold for low stock warning.
  final int minimumStock;

  /// Unit of measurement (e.g., 'pcs', 'kg', 'liter').
  final String unit;

  /// Timestamp when the product was created.
  final DateTime createdAt;

  /// Timestamp when the product was last updated.
  final DateTime updatedAt;

  /// Whether the current stock is at or below the minimum threshold.
  bool get isLowStock => quantity <= minimumStock;

  /// Canonical category key used by filters.
  String get normalizedCategory => normalizeCategory(category);

  static String normalizeCategory(String? value) {
    final category = (value ?? '').trim().toLowerCase();

    switch (category) {
      case 'food':
      case 'makanan':
      case 'camilan':
      case 'kue & roti':
      case 'kue dan roti':
      case 'oleh-oleh':
      case 'oleh oleh':
      case 'bumbu & rempah':
      case 'bumbu dan rempah':
        return 'food';
      case 'beverage':
      case 'minuman':
        return 'beverage';
      case 'handicraft':
      case 'kerajinan':
        return 'handicraft';
      case 'agriculture':
      case 'pertanian':
        return 'agriculture';
      default:
        return 'other';
    }
  }

  static String categoryLabel(String? value) {
    switch (normalizeCategory(value)) {
      case 'food':
        return 'Makanan';
      case 'beverage':
        return 'Minuman';
      case 'handicraft':
        return 'Kerajinan';
      case 'agriculture':
        return 'Pertanian';
      default:
        return 'Lainnya';
    }
  }

  const ProductModel({
    required this.id,
    required this.productName,
    this.description,
    required this.price,
    this.imageUrl,
    required this.ownerId,
    required this.category,
    required this.isAvailable,
    this.quantity = 0,
    this.minimumStock = 0,
    this.unit = 'pcs',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [ProductModel] from a Firestore document map.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      productName: json['product_name'] as String? ?? json['productName'] as String? ?? '',
      description: json['description'] as String?,
      price: _parseDouble(json['price']),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      ownerId: json['owner_id'] as String? ?? json['ownerId'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      isAvailable: json['is_available'] as bool? ?? json['isAvailable'] as bool? ?? true,
      quantity: _parseInt(json['quantity']),
      minimumStock: _parseInt(json['minimum_stock'] ?? json['minimumStock']),
      unit: json['unit'] as String? ?? 'pcs',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// Safely parses a double from various types.
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// Safely parses an int from various types.
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Safely parses a DateTime from Firestore data.
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  /// Converts this [ProductModel] to a Firestore-compatible map.
  /// Note: 'id' is excluded because Firestore uses the document ID separately.
  /// 'createdAt' and 'updatedAt' are excluded because FirestoreService
  /// adds server timestamps automatically.
  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'owner_id': ownerId,
      'category': category,
      'is_available': isAvailable,
      'quantity': quantity,
      'minimum_stock': minimumStock,
      'unit': unit,
    };
  }

  /// Creates a copy of this [ProductModel] with the given fields replaced.
  ProductModel copyWith({
    String? id,
    String? productName,
    String? description,
    double? price,
    String? imageUrl,
    String? ownerId,
    String? category,
    bool? isAvailable,
    int? quantity,
    int? minimumStock,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      quantity: quantity ?? this.quantity,
      minimumStock: minimumStock ?? this.minimumStock,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productName,
        description,
        price,
        imageUrl,
        ownerId,
        category,
        isAvailable,
        quantity,
        minimumStock,
        unit,
        createdAt,
        updatedAt,
      ];
}
