/// Media repository for the ALPACA application.
///
/// Provides image upload, retrieval, deletion, and real-time streaming
/// by combining StorageService and FirestoreService.
library;

import 'dart:async';
import 'dart:io';

import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/constants/firebase_constants.dart';
import 'package:alpaca_mobile/core/exceptions/app_exception.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/firestore_service.dart';
import 'package:alpaca_mobile/firebase/storage_service.dart';
import 'package:alpaca_mobile/models/media_model.dart';

/// Repository handling media (image) operations.
///
/// Manages the full lifecycle of media uploads including storing files
/// in Firebase Storage and tracking metadata in Firestore.
class MediaRepository {
  /// Creates a [MediaRepository] with the required Firebase services.
  MediaRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
    required ApiClient apiClient,
  })  : _firestoreService = firestoreService,
        _storageService = storageService,
        _apiClient = apiClient;

  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final ApiClient _apiClient;

  /// Uploads an image file to backend API.
  ///
  /// Backend handles both file upload and database record creation.
  ///
  /// Returns the created [MediaModel] on success.
  Future<Result<MediaModel>> uploadImage(
    File file,
    String category,
    String uploadedBy,
  ) async {
    // Upload file with category - backend saves to appropriate folder
    final uploadResult = await _apiClient.uploadImage(file, category: category);

    return uploadResult.map((imageUrl) {
      // Return model based on upload response
      // Note: backend should return full media object, not just URL
      return MediaModel(
        id: '', // Will be fetched when reloading
        imageUrl: imageUrl,
        uploadedBy: uploadedBy,
        uploadedAt: DateTime.now(),
        category: category,
      );
    });
  }

  /// Retrieves all media items for a specific [ownerId] from backend API.
  Future<Result<List<MediaModel>>> getMedia(String ownerId) async {
    return _apiClient.getPublic('/media', (j) {
      final data = j is Map ? j['data'] : j;
      if (data is List) {
        return data.map((e) => MediaModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }, query: {'owner_id': ownerId});
  }

  /// Deletes a media item by its [id] and removes the file from Storage.
  ///
  /// The [imageUrl] is used to identify the file in Firebase Storage.
  Future<Result<void>> deleteMedia(String id, String imageUrl) async {
    // Delete the file from Firebase Storage.
    final storageResult = await _storageService.deleteFile(imageUrl);

    // Even if storage deletion fails, attempt to remove the Firestore document.
    // This prevents orphaned documents if the storage file was already deleted.
    final firestoreResult = await _firestoreService.deleteDocument(
      collection: FirebaseCollections.media,
      id: id,
    );

    // Return the Firestore result as the primary outcome.
    // If storage failed but Firestore succeeded, the media record is removed.
    if (firestoreResult.isFailure) {
      return firestoreResult;
    }

    return storageResult.isFailure ? storageResult : firestoreResult;
  }

  /// Streams all media items for a specific [ownerId] in real-time.
  /// NOTE: Currently disabled as backend uses REST API, not Firestore
  Stream<List<MediaModel>> streamMedia(String ownerId) {
    // Return empty stream - use loadMedia() instead for REST API
    return Stream.value([]);
  }
}
