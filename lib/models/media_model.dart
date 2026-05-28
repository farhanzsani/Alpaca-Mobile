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

  /// Creates a [MediaModel] from a Firestore document map.
  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      uploadedBy: json['uploadedBy'] as String,
      uploadedAt: (json['uploadedAt'] as Timestamp).toDate(),
      category: json['category'] as String,
      description: json['description'] as String?,
    );
  }

  /// Converts this [MediaModel] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'category': category,
      'description': description,
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
