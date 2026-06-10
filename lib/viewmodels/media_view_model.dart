import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:alpaca_mobile/models/media_model.dart';
import 'package:alpaca_mobile/repositories/media_repository.dart';

/// Represents the current state of a view.
enum ViewState { initial, loading, loaded, error, empty }

/// ViewModel for media (image) management.
///
/// Handles image uploading from camera or gallery, loading media lists,
/// and deleting media items. Tracks upload progress for UI feedback.
class MediaViewModel extends ChangeNotifier {
  /// Creates a [MediaViewModel] with the given [MediaRepository].
  MediaViewModel({required MediaRepository mediaRepository})
      : _mediaRepository = mediaRepository;

  final MediaRepository _mediaRepository;

  // --- State ---

  ViewState _viewState = ViewState.initial;
  /// The current view state of this ViewModel.
  ViewState get viewState => _viewState;

  bool _isLoading = false;
  /// Whether an async operation is currently in progress.
  bool get isLoading => _isLoading;

  String? _error;
  /// The current error message, or null if no error.
  String? get error => _error;

  List<MediaModel> _mediaList = [];
  /// All loaded media items.
  List<MediaModel> get mediaList => List.unmodifiable(_mediaList);
  /// Alias for mediaList (for consistency with store profile screen)
  List<MediaModel> get mediaItems => mediaList;

  bool _isUploading = false;
  /// Whether an image upload is currently in progress.
  bool get isUploading => _isUploading;

  double _uploadProgress = 0.0;
  /// Upload progress from 0.0 to 1.0.
  double get uploadProgress => _uploadProgress;

  StreamSubscription<List<MediaModel>>? _mediaSubscription;

  // --- Methods ---

  /// Uploads an image file to Firebase Storage and creates a media record.
  ///
  /// [imageFile] is the file to upload.
  /// [category] classifies the media (e.g., product, location, promotion).
  /// [uploadedBy] is the ID of the user performing the upload.
  ///
  /// Tracks upload state via [isUploading] and [uploadProgress].
  Future<void> uploadImage({
    required File imageFile,
    required String category,
    required String uploadedBy,
  }) async {
    _isUploading = true;
    _uploadProgress = 0.0;
    _clearError();
    notifyListeners();

    final result = await _mediaRepository.uploadImage(
      imageFile,
      category,
      uploadedBy,
    );

    result.when(
      success: (media) {
        print('[MediaViewModel] Upload success, waiting for reload...');
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        print('[MediaViewModel] Upload failed: ${exception.message}');
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _isUploading = false;
    _uploadProgress = 1.0;
    notifyListeners();
  }

  /// Loads all media items for the given [userId].
  ///
  /// Fetches media records from Firestore filtered by the uploader.
  Future<void> loadMedia(String userId) async {
    print('[MediaViewModel] loadMedia called for userId: $userId');
    _setLoading(true);
    _clearError();

    final result = await _mediaRepository.getMedia(userId);

    result.when(
      success: (mediaList) {
        print('[MediaViewModel] Loaded ${mediaList.length} media items');
        _mediaList = mediaList;
        _viewState = mediaList.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        print('[MediaViewModel] Error loading media: ${exception.message}');
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Alias for loadMedia (for store profile view)
  Future<void> loadMediaByOwner(String ownerId) => loadMedia(ownerId);

  /// Deletes a media item by its [mediaId].
  ///
  /// Removes the item from the local list and deletes both the Firestore
  /// document and the file from Firebase Storage.
  Future<void> deleteMedia(String mediaId) async {
    _setLoading(true);
    _clearError();

    // Find the media item to get its imageUrl for storage deletion.
    final mediaItem = _mediaList.where((m) => m.id == mediaId).firstOrNull;
    if (mediaItem == null) {
      _error = 'Media item tidak ditemukan.';
      _viewState = ViewState.error;
      _setLoading(false);
      return;
    }

    final result = await _mediaRepository.deleteMedia(
      mediaId,
      mediaItem.imageUrl,
    );

    result.when(
      success: (_) {
        _mediaList.removeWhere((media) => media.id == mediaId);
        _viewState = _mediaList.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Subscribes to realtime media updates for the given [userId].
  ///
  /// Cancels any existing subscription before creating a new one.
  void subscribeToMedia(String userId) {
    _mediaSubscription?.cancel();
    _viewState = ViewState.loading;
    notifyListeners();

    _mediaSubscription = _mediaRepository.streamMedia(userId).listen(
      (mediaList) {
        _mediaList = mediaList;
        _viewState = mediaList.isEmpty ? ViewState.empty : ViewState.loaded;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error.toString();
        _viewState = ViewState.error;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _clearError() {
    _error = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _viewState = ViewState.loading;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _mediaSubscription?.cancel();
    super.dispose();
  }
}
