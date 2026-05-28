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

  /// Timestamp when the product was created.
  final DateTime createdAt;

  /// Timestamp when the product was last updated.
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.productName,
    this.description,
    required this.price,
    this.imageUrl,
    required this.ownerId,
    required this.category,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [ProductModel] from a Firestore document map.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      productName: json['productName'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      ownerId: json['ownerId'] as String,
      category: json['category'] as String,
      isAvailable: json['isAvailable'] as bool,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this [ProductModel] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'category': category,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
        createdAt,
        updatedAt,
      ];
}
