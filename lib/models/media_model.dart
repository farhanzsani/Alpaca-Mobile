import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model representing a media item (image) in the ALPACA platform.
///
/// Used for storing and managing images uploaded by business owners,
/// such as product photos, business location images, and promotional content.
class MediaModel extends Equatable {
  /// Unique identifier for the media item.
  final String id;

  /// URL where the image is stored (e.g., Firebase Storage URL).
  final String imageUrl;

  /// ID of the user who uploaded this media.
  final String uploadedBy;

  /// Timestamp when the media was uploaded.
  final DateTime uploadedAt;

  /// Category of the media (e.g., product, location, promotion).
  final String category;

  /// Optional description of the media content.
  final String? description;

  const MediaModel({
    required this.id,
    required this.imageUrl,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.category,
    this.description,
  });

  /// Creates a [MediaModel] from backend API JSON.
  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] as String? ?? '',
      imageUrl: json['url'] as String? ?? json['image_url'] as String? ?? json['imageUrl'] as String? ?? '',
      uploadedBy: json['owner_id'] as String? ?? json['uploaded_by'] as String? ?? json['uploadedBy'] as String? ?? '',
      uploadedAt: _parseDateTime(json['created_at'] ?? json['uploaded_at'] ?? json['uploadedAt']),
      category: json['category'] as String? ?? '',
      description: json['description'] as String?,
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

  /// Converts this [MediaModel] to backend API JSON format.
  Map<String, dynamic> toJson() {
    return {
      'url': imageUrl,
      'owner_id': uploadedBy,
      'category': category,
      'description': description,
      'created_at': uploadedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [MediaModel] with the given fields replaced.
  MediaModel copyWith({
    String? id,
    String? imageUrl,
    String? uploadedBy,
    DateTime? uploadedAt,
    String? category,
    String? description,
  }) {
    return MediaModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
        id,
        imageUrl,
        uploadedBy,
        uploadedAt,
        category,
        description,
      ];
}
