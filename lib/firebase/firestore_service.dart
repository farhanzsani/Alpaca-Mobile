/// Generic Firestore CRUD service for the ALPACA application.
///
/// Provides type-safe methods for document and collection operations
/// with built-in error handling, retry logic, and streaming support.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:alpaca_mobile/core/exceptions/app_exception.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/firebase_service.dart';

/// Typedef for a function that converts a Firestore document snapshot to a model.
typedef FromFirestore<T> = T Function(Map<String, dynamic> data, String id);

/// Typedef for a function that converts a model to a Firestore-compatible map.
typedef ToFirestore<T> = Map<String, dynamic> Function(T model);

/// Parameters for querying Firestore collections.
///
/// Supports filtering, ordering, pagination, and limiting results.
class QueryParams {
  const QueryParams({
    this.where,
    this.orderBy,
    this.descending = false,
    this.limit,
    this.startAfter,
    this.endBefore,
  });

  /// List of where conditions as tuples of (field, operator, value).
  final List<WhereCondition>? where;

  /// Field name to order results by.
  final String? orderBy;

  /// Whether to order results in descending order.
  final bool descending;

  /// Maximum number of documents to return.
  final int? limit;

  /// Document snapshot to start after (for pagination).
  final DocumentSnapshot? startAfter;

  /// Document snapshot to end before (for pagination).
  final DocumentSnapshot? endBefore;
}

/// Represents a single Firestore where condition.
class WhereCondition {
  const WhereCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  /// The field name to filter on.
  final String field;

  /// The comparison operator (==, !=, <, <=, >, >=, array-contains, in, etc.).
  final WhereOperator operator;

  /// The value to compare against.
  final dynamic value;
}

/// Supported Firestore where operators.
enum WhereOperator {
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
  isNull,
}

/// Generic Firestore CRUD service.
///
/// Provides type-safe document and collection operations with automatic
/// error handling and retry logic for transient failures.
///
/// Usage:
/// ```dart
/// final firestoreService = FirestoreService();
///
/// // Get a document
/// final result = await firestoreService.getDocument<User>(
///   collection: 'users',
///   id: 'user123',
///   fromFirestore: (data, id) => User.fromMap(data, id),
/// );
///
/// // Stream a collection
/// final stream = firestoreService.streamCollection<User>(
///   collection: 'users',
///   fromFirestore: (data, id) => User.fromMap(data, id),
///   queryParams: QueryParams(orderBy: 'createdAt', descending: true),
/// );
/// ```
class FirestoreService extends FirebaseService {
  /// Creates a [FirestoreService] with an optional [FirebaseFirestore] instance.
  FirestoreService({
    FirebaseFirestore? firestore,
    super.logger,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns the underlying [FirebaseFirestore] instance.
  FirebaseFirestore get firestore => _firestore;

  /// Retrieves a single document by [id] from the specified [collection].
  ///
  /// Uses [fromFirestore] to convert the document data to type [T].
  /// Returns [DataException.notFound] if the document does not exist.
  Future<Result<T>> getDocument<T>({
    required String collection,
    required String id,
    required FromFirestore<T> fromFirestore,
  }) async {
    return retryOperation(
      () async {
        final doc = await _firestore.collection(collection).doc(id).get();
        if (!doc.exists || doc.data() == null) {
          throw DataException.notFound(collection);
        }
        return fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'getDocument($collection/$id)',
    );
  }

  /// Retrieves a collection of documents with optional query parameters.
  ///
  /// Uses [fromFirestore] to convert each document to type [T].
  /// Supports filtering, ordering, and pagination via [queryParams].
  Future<Result<List<T>>> getCollection<T>({
    required String collection,
    required FromFirestore<T> fromFirestore,
    QueryParams? queryParams,
  }) async {
    return retryOperation(
      () async {
        Query<Map<String, dynamic>> query = _firestore.collection(collection);
        query = _applyQueryParams(query, queryParams);

        final snapshot = await query.get();
        final documents = snapshot.docs
            .map((doc) => fromFirestore(doc.data(), doc.id))
            .toList();

        logger.d('getCollection($collection): retrieved ${documents.length} documents');
        return documents;
      },
      operationName: 'getCollection($collection)',
    );
  }

  /// Adds a new document to the specified [collection].
  ///
  /// If [id] is provided, the document is created with that ID.
  /// Otherwise, Firestore auto-generates an ID.
  ///
  /// Returns the document ID of the created document.
  Future<Result<String>> addDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? id,
  }) async {
    return retryOperation(
      () async {
        final dataWithTimestamp = {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (id != null) {
          await _firestore.collection(collection).doc(id).set(dataWithTimestamp);
          logger.i('addDocument($collection): created document with id $id');
          return id;
        } else {
          final docRef = await _firestore.collection(collection).add(dataWithTimestamp);
          logger.i('addDocument($collection): created document with id ${docRef.id}');
          return docRef.id;
        }
      },
      operationName: 'addDocument($collection)',
    );
  }

  /// Updates an existing document in the specified [collection].
  ///
  /// Only the fields present in [data] are updated; other fields remain unchanged.
  /// Automatically adds an `updatedAt` timestamp.
  Future<Result<void>> updateDocument({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    return retryOperation(
      () async {
        final dataWithTimestamp = {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection(collection).doc(id).update(dataWithTimestamp);
        logger.i('updateDocument($collection/$id): updated successfully');
      },
      operationName: 'updateDocument($collection/$id)',
    );
  }

  /// Deletes a document from the specified [collection].
  ///
  /// Returns `void` wrapped in [Result] on success.
  Future<Result<void>> deleteDocument({
    required String collection,
    required String id,
  }) async {
    return retryOperation(
      () async {
        await _firestore.collection(collection).doc(id).delete();
        logger.i('deleteDocument($collection/$id): deleted successfully');
      },
      operationName: 'deleteDocument($collection/$id)',
    );
  }

  /// Streams a single document, emitting updates in real-time.
  ///
  /// Returns a [Stream] of [Result<T>] that emits whenever the document changes.
  /// Emits [DataException.notFound] if the document does not exist.
  Stream<Result<T>> streamDocument<T>({
    required String collection,
    required String id,
    required FromFirestore<T> fromFirestore,
  }) {
    return _firestore
        .collection(collection)
        .doc(id)
        .snapshots()
        .map((snapshot) {
      try {
        if (!snapshot.exists || snapshot.data() == null) {
          return Result<T>.failure(DataException.notFound(collection));
        }
        return Result<T>.success(fromFirestore(snapshot.data()!, snapshot.id));
      } catch (e, st) {
        logger.e('streamDocument($collection/$id): error', error: e, stackTrace: st);
        return Result<T>.failure(handleException(e, st));
      }
    }).handleError((Object error, StackTrace stackTrace) {
      logger.e('streamDocument($collection/$id): stream error', error: error, stackTrace: stackTrace);
      return Result<T>.failure(handleException(error, stackTrace));
    });
  }

  /// Streams a collection of documents, emitting updates in real-time.
  ///
  /// Returns a [Stream] of [Result<List<T>>] that emits whenever any
  /// document in the collection changes.
  Stream<Result<List<T>>> streamCollection<T>({
    required String collection,
    required FromFirestore<T> fromFirestore,
    QueryParams? queryParams,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);
    query = _applyQueryParams(query, queryParams);

    return query.snapshots().map((snapshot) {
      try {
        final documents = snapshot.docs
            .map((doc) => fromFirestore(doc.data(), doc.id))
            .toList();
        return Result<List<T>>.success(documents);
      } catch (e, st) {
        logger.e('streamCollection($collection): error', error: e, stackTrace: st);
        return Result<List<T>>.failure(handleException(e, st));
      }
    }).handleError((Object error, StackTrace stackTrace) {
      logger.e('streamCollection($collection): stream error', error: error, stackTrace: stackTrace);
      return Result<List<T>>.failure(handleException(error, stackTrace));
    });
  }

  /// Performs a batch write operation.
  ///
  /// Executes multiple write operations atomically. If any operation fails,
  /// none of the changes are applied.
  ///
  /// [operations] is a callback that receives a [WriteBatch] to add operations to.
  Future<Result<void>> batchWrite(
    void Function(WriteBatch batch) operations,
  ) async {
    return retryOperation(
      () async {
        final batch = _firestore.batch();
        operations(batch);
        await batch.commit();
        logger.i('batchWrite: committed successfully');
      },
      operationName: 'batchWrite',
    );
  }

  /// Runs a Firestore transaction.
  ///
  /// [transactionHandler] receives a [Transaction] object and must return
  /// the result value. All reads must happen before writes within the transaction.
  Future<Result<T>> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    return guardedCall(
      () async {
        final result = await _firestore.runTransaction(transactionHandler);
        logger.i('runTransaction: completed successfully');
        return result;
      },
      operationName: 'runTransaction',
    );
  }

  /// Applies [QueryParams] to a Firestore [Query].
  Query<Map<String, dynamic>> _applyQueryParams(
    Query<Map<String, dynamic>> query,
    QueryParams? params,
  ) {
    if (params == null) return query;

    // Apply where conditions.
    if (params.where != null) {
      for (final condition in params.where!) {
        query = _applyWhereCondition(query, condition);
      }
    }

    // Apply ordering.
    if (params.orderBy != null) {
      query = query.orderBy(params.orderBy!, descending: params.descending);
    }

    // Apply pagination.
    if (params.startAfter != null) {
      query = query.startAfterDocument(params.startAfter!);
    }
    if (params.endBefore != null) {
      query = query.endBeforeDocument(params.endBefore!);
    }

    // Apply limit.
    if (params.limit != null) {
      query = query.limit(params.limit!);
    }

    return query;
  }

  /// Applies a single [WhereCondition] to a Firestore [Query].
  Query<Map<String, dynamic>> _applyWhereCondition(
    Query<Map<String, dynamic>> query,
    WhereCondition condition,
  ) {
    switch (condition.operator) {
      case WhereOperator.isEqualTo:
        return query.where(condition.field, isEqualTo: condition.value);
      case WhereOperator.isNotEqualTo:
        return query.where(condition.field, isNotEqualTo: condition.value);
      case WhereOperator.isLessThan:
        return query.where(condition.field, isLessThan: condition.value);
      case WhereOperator.isLessThanOrEqualTo:
        return query.where(condition.field, isLessThanOrEqualTo: condition.value);
      case WhereOperator.isGreaterThan:
        return query.where(condition.field, isGreaterThan: condition.value);
      case WhereOperator.isGreaterThanOrEqualTo:
        return query.where(condition.field, isGreaterThanOrEqualTo: condition.value);
      case WhereOperator.arrayContains:
        return query.where(condition.field, arrayContains: condition.value);
      case WhereOperator.arrayContainsAny:
        return query.where(condition.field, arrayContainsAny: condition.value as List<dynamic>);
      case WhereOperator.whereIn:
        return query.where(condition.field, whereIn: condition.value as List<dynamic>);
      case WhereOperator.whereNotIn:
        return query.where(condition.field, whereNotIn: condition.value as List<dynamic>);
      case WhereOperator.isNull:
        return query.where(condition.field, isNull: condition.value as bool);
    }
  }
}
