/// Business location repository for the ALPACA application.
///
/// Provides CRUD operations and real-time streaming for business locations,
/// supporting the local culinary tourism map feature.
library;

import 'dart:async';

import 'package:alpaca_mobile/core/constants/firebase_constants.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/firestore_service.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';

/// Repository handling business location operations.
///
/// Manages geographic business data for the tourism map and
/// business profile features.
class BusinessRepository {
  /// Creates a [BusinessRepository] with the required Firestore service.
  BusinessRepository({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  /// Creates a new business location in Firestore.
  ///
  /// Returns the document ID of the created business location.
  Future<Result<String>> createBusiness(BusinessLocationModel business) async {
    return _firestoreService.addDocument(
      collection: FirebaseCollections.businessLocations,
      data: business.toJson(),
      id: business.id.isNotEmpty ? business.id : null,
    );
  }

  /// Updates an existing business location.
  ///
  /// The [business] must have a valid [BusinessLocationModel.id].
  Future<Result<void>> updateBusiness(BusinessLocationModel business) async {
    return _firestoreService.updateDocument(
      collection: FirebaseCollections.businessLocations,
      id: business.id,
      data: business.toJson(),
    );
  }

  /// Retrieves a single business location by its [id].
  Future<Result<BusinessLocationModel>> getBusiness(String id) async {
    return _firestoreService.getDocument<BusinessLocationModel>(
      collection: FirebaseCollections.businessLocations,
      id: id,
      fromFirestore: (data, docId) =>
          BusinessLocationModel.fromJson({...data, 'id': docId}),
    );
  }

  /// Retrieves the business location owned by a specific [ownerId].
  ///
  /// Returns null if the owner has no registered business location.
  Future<Result<BusinessLocationModel?>> getBusinessByOwner(
    String ownerId,
  ) async {
    final result =
        await _firestoreService.getCollection<BusinessLocationModel>(
      collection: FirebaseCollections.businessLocations,
      fromFirestore: (data, docId) =>
          BusinessLocationModel.fromJson({...data, 'id': docId}),
      queryParams: QueryParams(
        where: [
          WhereCondition(
            field: 'ownerId',
            operator: WhereOperator.isEqualTo,
            value: ownerId,
          ),
        ],
        limit: 1,
      ),
    );

    return result.when(
      success: (businesses) {
        if (businesses.isEmpty) {
          return Result<BusinessLocationModel?>.success(null);
        }
        return Result<BusinessLocationModel?>.success(businesses.first);
      },
      failure: (exception) => Result.failure(exception),
    );
  }

  /// Streams all business locations in real-time.
  ///
  /// Used for the public tourism map to display all registered businesses.
  Stream<List<BusinessLocationModel>> getAllBusinesses() {
    return _firestoreService
        .streamCollection<BusinessLocationModel>(
          collection: FirebaseCollections.businessLocations,
          fromFirestore: (data, docId) =>
              BusinessLocationModel.fromJson({...data, 'id': docId}),
          queryParams: const QueryParams(
            orderBy: 'createdAt',
            descending: true,
          ),
        )
        .map((result) => result.dataOrNull ?? []);
  }

  /// Deletes a business location by its [id].
  Future<Result<void>> deleteBusiness(String id) async {
    return _firestoreService.deleteDocument(
      collection: FirebaseCollections.businessLocations,
      id: id,
    );
  }
}
