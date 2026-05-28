/// Inventory repository for the ALPACA application.
///
/// Provides CRUD operations and real-time streaming for inventory items,
/// bridging ViewModels with the FirestoreService.
library;

import 'dart:async';

import 'package:alpaca_mobile/core/constants/firebase_constants.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/firestore_service.dart';
import 'package:alpaca_mobile/models/inventory_model.dart';

/// Repository handling inventory item operations.
///
/// Manages stock tracking, low-stock alerts, and real-time inventory
/// updates for agrarian SME owners.
class InventoryRepository {
  /// Creates an [InventoryRepository] with the required Firestore service.
  InventoryRepository({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  /// Adds a new inventory item to Firestore.
  ///
  /// Returns the document ID of the created item.
  Future<Result<String>> addItem(InventoryModel item) async {
    return _firestoreService.addDocument(
      collection: FirebaseCollections.inventory,
      data: item.toJson(),
      id: item.id.isNotEmpty ? item.id : null,
    );
  }

  /// Updates an existing inventory item.
  ///
  /// The [item] must have a valid [InventoryModel.id].
  Future<Result<void>> updateItem(InventoryModel item) async {
    return _firestoreService.updateDocument(
      collection: FirebaseCollections.inventory,
      id: item.id,
      data: item.toJson(),
    );
  }

  /// Deletes an inventory item by its [id].
  Future<Result<void>> deleteItem(String id) async {
    return _firestoreService.deleteDocument(
      collection: FirebaseCollections.inventory,
      id: id,
    );
  }

  /// Retrieves a single inventory item by its [id].
  Future<Result<InventoryModel>> getItem(String id) async {
    return _firestoreService.getDocument<InventoryModel>(
      collection: FirebaseCollections.inventory,
      id: id,
      fromFirestore: (data, docId) =>
          InventoryModel.fromJson({...data, 'id': docId}),
    );
  }

  /// Retrieves all inventory items for a specific [ownerId].
  Future<Result<List<InventoryModel>>> getItems(String ownerId) async {
    return _firestoreService.getCollection<InventoryModel>(
      collection: FirebaseCollections.inventory,
      fromFirestore: (data, docId) =>
          InventoryModel.fromJson({...data, 'id': docId}),
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

  /// Streams all inventory items for a specific [ownerId] in real-time.
  ///
  /// Emits a new list whenever any inventory item changes.
  Stream<List<InventoryModel>> streamItems(String ownerId) {
    return _firestoreService
        .streamCollection<InventoryModel>(
          collection: FirebaseCollections.inventory,
          fromFirestore: (data, docId) =>
              InventoryModel.fromJson({...data, 'id': docId}),
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

  /// Streams inventory items that are below their minimum stock threshold.
  ///
  /// Useful for displaying low-stock alerts to business owners.
  Stream<List<InventoryModel>> getLowStockItems(String ownerId) {
    return _firestoreService
        .streamCollection<InventoryModel>(
          collection: FirebaseCollections.inventory,
          fromFirestore: (data, docId) =>
              InventoryModel.fromJson({...data, 'id': docId}),
          queryParams: QueryParams(
            where: [
              WhereCondition(
                field: 'ownerId',
                operator: WhereOperator.isEqualTo,
                value: ownerId,
              ),
            ],
          ),
        )
        .map((result) {
      final items = result.dataOrNull ?? [];
      return items.where((item) => item.isLowStock).toList();
    });
  }
}
