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

  /// Uploads an image file and creates a media document in Firestore.
  ///
  /// The file is uploaded to backend API endpoint.
  ///
  /// Returns the created [MediaModel] on success.
  Future<Result<MediaModel>> uploadImage(
    File file,
    String category,
    String uploadedBy,
  ) async {
    // Upload to backend API
    final uploadResult = await _apiClient.uploadImage(file);

    return uploadResult.when(
      success: (imageUrl) async {
        final now = DateTime.now();
        final mediaModel = MediaModel(
          id: '', // Will be set by Firestore auto-generated ID.
          imageUrl: imageUrl,
          uploadedBy: uploadedBy,
          uploadedAt: now,
          category: category,
        );

        // Create media document in Firestore.
        final docResult = await _firestoreService.addDocument(
          collection: FirebaseCollections.media,
          data: mediaModel.toJson(),
        );

        return docResult.when(
          success: (docId) =>
              Result.success(mediaModel.copyWith(id: docId)),
          failure: (exception) => Result<MediaModel>.failure(exception),
        );
      },
      failure: (exception) => Result.failure(exception),
    );
  }

  /// Retrieves all media items for a specific [ownerId].
  Future<Result<List<MediaModel>>> getMedia(String ownerId) async {
    return _firestoreService.getCollection<MediaModel>(
      collection: FirebaseCollections.media,
      fromFirestore: (data, docId) =>
          MediaModel.fromJson({...data, 'id': docId}),
      queryParams: QueryParams(
        where: [
          WhereCondition(
            field: 'uploadedBy',
            operator: WhereOperator.isEqualTo,
            value: ownerId,
          ),
        ],
        orderBy: 'uploadedAt',
        descending: true,
      ),
    );
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
  Stream<List<MediaModel>> streamMedia(String ownerId) {
    return _firestoreService
        .streamCollection<MediaModel>(
          collection: FirebaseCollections.media,
          fromFirestore: (data, docId) =>
              MediaModel.fromJson({...data, 'id': docId}),
          queryParams: QueryParams(
            where: [
              WhereCondition(
                field: 'uploadedBy',
                operator: WhereOperator.isEqualTo,
                value: ownerId,
              ),
            ],
            orderBy: 'uploadedAt',
            descending: true,
          ),
        )
        .map((result) => result.dataOrNull ?? []);
  }
}
