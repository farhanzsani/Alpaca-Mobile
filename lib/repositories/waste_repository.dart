/// Waste resource repository for the ALPACA application.
///
/// Provides CRUD operations and real-time streaming for waste resources,
/// supporting the circular economy feature of the platform.
library;

import 'dart:async';

import 'package:alpaca_mobile/core/constants/firebase_constants.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/firestore_service.dart';
import 'package:alpaca_mobile/models/waste_resource_model.dart';

/// Repository handling waste resource operations.
///
/// Manages tracking of agricultural waste materials that can potentially
/// be reused or repurposed, supporting sustainability goals.
class WasteRepository {
  /// Creates a [WasteRepository] with the required Firestore service.
  WasteRepository({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  /// Adds a new waste resource record to Firestore.
  ///
  /// Returns the document ID of the created waste resource.
  Future<Result<String>> addWaste(WasteResourceModel waste) async {
    return _firestoreService.addDocument(
      collection: FirebaseCollections.wasteResources,
      data: waste.toJson(),
      id: waste.id.isNotEmpty ? waste.id : null,
    );
  }

  /// Updates an existing waste resource record.
  ///
  /// The [waste] must have a valid [WasteResourceModel.id].
  Future<Result<void>> updateWaste(WasteResourceModel waste) async {
    return _firestoreService.updateDocument(
      collection: FirebaseCollections.wasteResources,
      id: waste.id,
      data: waste.toJson(),
    );
  }

  /// Deletes a waste resource record by its [id].
  Future<Result<void>> deleteWaste(String id) async {
    return _firestoreService.deleteDocument(
      collection: FirebaseCollections.wasteResources,
      id: id,
    );
  }

  /// Retrieves all waste resources for a specific [ownerId].
  Future<Result<List<WasteResourceModel>>> getWasteByOwner(
    String ownerId,
  ) async {
    return _firestoreService.getCollection<WasteResourceModel>(
      collection: FirebaseCollections.wasteResources,
      fromFirestore: (data, docId) =>
          WasteResourceModel.fromJson({...data, 'id': docId}),
      queryParams: QueryParams(
        where: [
          WhereCondition(
            field: 'ownerId',
            operator: WhereOperator.isEqualTo,
            value: ownerId,
          ),
        ],
        orderBy: 'createdAt',
        descending: true,
      ),
    );
  }

  /// Streams all waste resources for a specific [ownerId] in real-time.
  Stream<List<WasteResourceModel>> streamWaste(String ownerId) {
    return _firestoreService
        .streamCollection<WasteResourceModel>(
          collection: FirebaseCollections.wasteResources,
          fromFirestore: (data, docId) =>
              WasteResourceModel.fromJson({...data, 'id': docId}),
          queryParams: QueryParams(
            where: [
              WhereCondition(
                field: 'ownerId',
                operator: WhereOperator.isEqualTo,
                value: ownerId,
              ),
            ],
            orderBy: 'createdAt',
            descending: true,
          ),
        )
        .map((result) => result.dataOrNull ?? []);
  }

  /// Retrieves all reusable waste resources for a specific [ownerId].
  ///
  /// Filters waste items where [WasteResourceModel.reusable] is true,
  /// useful for identifying materials that can be repurposed.
  Future<Result<List<WasteResourceModel>>> getReusableWaste(
    String ownerId,
  ) async {
    return _firestoreService.getCollection<WasteResourceModel>(
      collection: FirebaseCollections.wasteResources,
      fromFirestore: (data, docId) =>
          WasteResourceModel.fromJson({...data, 'id': docId}),
      queryParams: QueryParams(
        where: [
          WhereCondition(
            field: 'ownerId',
            operator: WhereOperator.isEqualTo,
            value: ownerId,
          ),
          WhereCondition(
            field: 'reusable',
            operator: WhereOperator.isEqualTo,
            value: true,
          ),
        ],
        orderBy: 'createdAt',
        descending: true,
      ),
    );
  }
}
