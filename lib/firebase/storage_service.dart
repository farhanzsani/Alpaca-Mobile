/// Firebase Storage service for the ALPACA application.
///
/// Provides methods for file upload, download URL retrieval, deletion,
/// and listing. All methods return [Result<T>] for consistent error handling.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/firebase_service.dart';

/// Metadata about an uploaded file.
class StorageFileMetadata {
  const StorageFileMetadata({
    required this.path,
    required this.name,
    required this.size,
    this.contentType,
    this.downloadUrl,
    this.updatedAt,
  });

  /// Full storage path of the file.
  final String path;

  /// File name.
  final String name;

  /// File size in bytes.
  final int size;

  /// MIME content type of the file.
  final String? contentType;

  /// Public download URL, if available.
  final String? downloadUrl;

  /// Last updated timestamp.
  final DateTime? updatedAt;
}

/// Service class for Firebase Storage operations.
///
/// Usage:
/// ```dart
/// final storageService = StorageService();
///
/// // Upload a file
/// final result = await storageService.uploadFile(
///   path: 'users/user123/avatar.jpg',
///   file: File('/path/to/image.jpg'),
/// );
///
/// // Get download URL
/// final urlResult = await storageService.getDownloadUrl('users/user123/avatar.jpg');
/// ```
class StorageService extends FirebaseService {
  /// Creates a [StorageService] with an optional [FirebaseStorage] instance.
  StorageService({
    FirebaseStorage? storage,
    super.logger,
  }) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads a [File] to the specified storage [path].
  ///
  /// Optionally accepts [metadata] for setting content type and custom metadata.
  /// Returns [StorageFileMetadata] with details about the uploaded file.
  Future<Result<StorageFileMetadata>> uploadFile({
    required String path,
    required File file,
    SettableMetadata? metadata,
  }) async {
    return retryOperation(
      () async {
        final ref = _storage.ref(path);

        // Determine metadata if not provided.
        final uploadMetadata = metadata ?? SettableMetadata(
          contentType: _inferContentType(path),
        );

        final uploadTask = ref.putFile(file, uploadMetadata);
        final snapshot = await uploadTask;

        final downloadUrl = await snapshot.ref.getDownloadURL();
        final fullMetadata = await snapshot.ref.getMetadata();

        logger.i('uploadFile: uploaded ${file.path} to $path');

        return StorageFileMetadata(
          path: path,
          name: ref.name,
          size: fullMetadata.size ?? 0,
          contentType: fullMetadata.contentType,
          downloadUrl: downloadUrl,
          updatedAt: fullMetadata.updated,
        );
      },
      operationName: 'uploadFile($path)',
    );
  }

  /// Uploads raw bytes to the specified storage [path].
  ///
  /// Useful for uploading in-memory data such as processed images or
  /// generated files. Returns [StorageFileMetadata] with upload details.
  Future<Result<StorageFileMetadata>> uploadBytes({
    required String path,
    required Uint8List bytes,
    SettableMetadata? metadata,
  }) async {
    return retryOperation(
      () async {
        final ref = _storage.ref(path);

        final uploadMetadata = metadata ?? SettableMetadata(
          contentType: _inferContentType(path),
        );

        final uploadTask = ref.putData(bytes, uploadMetadata);
        final snapshot = await uploadTask;

        final downloadUrl = await snapshot.ref.getDownloadURL();
        final fullMetadata = await snapshot.ref.getMetadata();

        logger.i('uploadBytes: uploaded ${bytes.length} bytes to $path');

        return StorageFileMetadata(
          path: path,
          name: ref.name,
          size: fullMetadata.size ?? 0,
          contentType: fullMetadata.contentType,
          downloadUrl: downloadUrl,
          updatedAt: fullMetadata.updated,
        );
      },
      operationName: 'uploadBytes($path)',
    );
  }

  /// Retrieves the public download URL for a file at the specified [path].
  ///
  /// Returns the URL as a [String] on success.
  Future<Result<String>> getDownloadUrl(String path) async {
    return retryOperation(
      () async {
        final ref = _storage.ref(path);
        final url = await ref.getDownloadURL();
        logger.d('getDownloadUrl($path): retrieved successfully');
        return url;
      },
      operationName: 'getDownloadUrl($path)',
    );
  }

  /// Deletes a file at the specified storage [path].
  ///
  /// Returns `void` wrapped in [Result] on success.
  Future<Result<void>> deleteFile(String path) async {
    return retryOperation(
      () async {
        final ref = _storage.ref(path);
        await ref.delete();
        logger.i('deleteFile($path): deleted successfully');
      },
      operationName: 'deleteFile($path)',
    );
  }

  /// Lists all files and prefixes (subdirectories) at the specified [path].
  ///
  /// Returns a list of [StorageFileMetadata] for each file found.
  /// Does not recurse into subdirectories.
  Future<Result<List<StorageFileMetadata>>> listFiles(String path) async {
    return retryOperation(
      () async {
        final ref = _storage.ref(path);
        final listResult = await ref.listAll();

        final files = <StorageFileMetadata>[];
        for (final item in listResult.items) {
          try {
            final metadata = await item.getMetadata();
            files.add(StorageFileMetadata(
              path: item.fullPath,
              name: item.name,
              size: metadata.size ?? 0,
              contentType: metadata.contentType,
              updatedAt: metadata.updated,
            ));
          } catch (e) {
            // If we can't get metadata for a single file, still include it
            // with minimal info rather than failing the entire operation.
            logger.w('listFiles($path): failed to get metadata for ${item.name}', error: e);
            files.add(StorageFileMetadata(
              path: item.fullPath,
              name: item.name,
              size: 0,
            ));
          }
        }

        logger.d('listFiles($path): found ${files.length} files');
        return files;
      },
      operationName: 'listFiles($path)',
    );
  }

  /// Retrieves metadata for a file at the specified [path].
  ///
  /// Returns [StorageFileMetadata] with full file details.
  Future<Result<StorageFileMetadata>> getFileMetadata(String path) async {
    return retryOperation(
      () async {
        final ref = _storage.ref(path);
        final metadata = await ref.getMetadata();

        return StorageFileMetadata(
          path: ref.fullPath,
          name: ref.name,
          size: metadata.size ?? 0,
          contentType: metadata.contentType,
          updatedAt: metadata.updated,
        );
      },
      operationName: 'getFileMetadata($path)',
    );
  }

  /// Infers the MIME content type from a file path extension.
  String? _inferContentType(String path) {
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'svg' => 'image/svg+xml',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'mp4' => 'video/mp4',
      'mp3' => 'audio/mpeg',
      'json' => 'application/json',
      'txt' => 'text/plain',
      'csv' => 'text/csv',
      _ => null,
    };
  }
}
