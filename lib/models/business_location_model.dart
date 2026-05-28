import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model representing a business location on the ALPACA platform.
///
/// Stores geographic and descriptive information about agrarian SME
/// locations for the local culinary tourism map feature.
class BusinessLocationModel extends Equatable {
  /// Unique identifier for the business location.
  final String id;

  /// Name of the business at this location.
  final String businessName;

  /// Geographic latitude coordinate.
  final double latitude;

  /// Geographic longitude coordinate.
  final double longitude;

  /// Full street address of the business.
  final String address;

  /// Optional description of the business or location.
  final String? description;

  /// ID of the business owner who owns this location.
  final String ownerId;

  /// URL to an image representing this business location.
  final String? imageUrl;

  /// Timestamp when the location was created.
  final DateTime createdAt;

  /// Timestamp when the location was last updated.
  final DateTime updatedAt;

  const BusinessLocationModel({
    required this.id,
    required this.businessName,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.description,
    required this.ownerId,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [BusinessLocationModel] from a Firestore document map.
  factory BusinessLocationModel.fromJson(Map<String, dynamic> json) {
    return BusinessLocationModel(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this [BusinessLocationModel] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'description': description,
      'ownerId': ownerId,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates a copy of this [BusinessLocationModel] with the given fields replaced.
  BusinessLocationModel copyWith({
    String? id,
    String? businessName,
    double? latitude,
    double? longitude,
    String? address,
    String? description,
    String? ownerId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessLocationModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessName,
        latitude,
        longitude,
        address,
        description,
        ownerId,
        imageUrl,
        createdAt,
        updatedAt,
      ];
}
