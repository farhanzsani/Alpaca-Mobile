import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a user in the ALPACA platform.
///
/// Users can have the role of [UserRole.ownerUmkm] (business owner)
/// or [UserRole.customer] (customer/tourist).
enum UserRole {
  ownerUmkm,
  customer;

  String toJson() {
    switch (this) {
      case UserRole.ownerUmkm:
        return 'owner_umkm';
      case UserRole.customer:
        return 'customer';
    }
  }

  static UserRole fromJson(String value) {
    switch (value) {
      case 'owner_umkm':
        return UserRole.ownerUmkm;
      case 'customer':
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }
}

/// Model representing a user account in the ALPACA system.
///
/// Contains profile information, authentication details, and role assignment
/// for agrarian SME owners and local culinary tourism customers.
class UserModel extends Equatable {
  /// Unique identifier for the user.
  final String id;

  /// Email address used for authentication.
  final String email;

  /// Display name shown in the app.
  final String displayName;

  /// Role of the user in the platform.
  final UserRole role;

  /// URL to the user's profile photo.
  final String? photoUrl;

  /// User's phone number for contact purposes.
  final String? phoneNumber;

  /// Timestamp when the user account was created.
  final DateTime createdAt;

  /// Timestamp when the user account was last updated.
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [UserModel] from a Firestore document map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      role: UserRole.fromJson(json['role'] as String? ?? 'customer'),
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  /// Safely parses a DateTime from Firestore data.
  /// Handles Timestamp, String, int (milliseconds), and null.
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  /// Converts this [UserModel] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.toJson(),
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
    };
  }
  /// Converts to Firestore-compatible map (with Timestamp).
  Map<String, dynamic> toFirestoreJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.toJson(),
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }


  /// Creates a copy of this [UserModel] with the given fields replaced.
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    String? photoUrl,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        role,
        photoUrl,
        phoneNumber,
        createdAt,
        updatedAt,
      ];
}


