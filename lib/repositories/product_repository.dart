/// Product repository for the ALPACA application.
///
/// Provides CRUD operations, category filtering, and real-time streaming
/// for products listed by agrarian SME owners.
library;

import 'dart:async';

import 'package:alpaca_mobile/core/constants/firebase_constants.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/firestore_service.dart';
import 'package:alpaca_mobile/models/product_model.dart';

/// Repository handling product operations.
///
/// Manages product listings for the marketplace and public showcase,
/// including category-based filtering and availability tracking.
class ProductRepository {
  /// Creates a [ProductRepository] with the required Firestore service.
  ProductRepository({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  /// Adds a new product to Firestore.
  ///
  /// Returns the document ID of the created product.
  Future<Result<String>> addProduct(ProductModel product) async {
    return _firestoreService.addDocument(
      collection: FirebaseCollections.products,
      data: product.toJson(),
      id: product.id.isNotEmpty ? product.id : null,
    );
  }

  /// Updates an existing product.
  ///
  /// The [product] must have a valid [ProductModel.id].
  Future<Result<void>> updateProduct(ProductModel product) async {
    return _firestoreService.updateDocument(
      collection: FirebaseCollections.products,
      id: product.id,
      data: product.toJson(),
    );
  }

  /// Deletes a product by its [id].
  Future<Result<void>> deleteProduct(String id) async {
    return _firestoreService.deleteDocument(
      collection: FirebaseCollections.products,
      id: id,
    );
  }

  /// Retrieves a single product by its [id].
  Future<Result<ProductModel>> getProduct(String id) async {
    return _firestoreService.getDocument<ProductModel>(
      collection: FirebaseCollections.products,
      id: id,
      fromFirestore: (data, docId) =>
          ProductModel.fromJson({...data, 'id': docId}),
    );
  }

  /// Retrieves all products for a specific [ownerId].
  Future<Result<List<ProductModel>>> getProductsByOwner(String ownerId) async {
    return _firestoreService.getCollection<ProductModel>(
      collection: FirebaseCollections.products,
      fromFirestore: (data, docId) =>
          ProductModel.fromJson({...data, 'id': docId}),
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

  /// Streams all products for a specific [ownerId] in real-time.
  Stream<List<ProductModel>> streamProducts(String ownerId) {
    return _firestoreService
        .streamCollection<ProductModel>(
          collection: FirebaseCollections.products,
          fromFirestore: (data, docId) =>
              ProductModel.fromJson({...data, 'id': docId}),
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

  /// Streams all available products for the public showcase.
  ///
  /// Only includes products where [ProductModel.isAvailable] is true.
  Stream<List<ProductModel>> streamAllProducts() {
    return _firestoreService
        .streamCollection<ProductModel>(
          collection: FirebaseCollections.products,
          fromFirestore: (data, docId) =>
              ProductModel.fromJson({...data, 'id': docId}),
          queryParams: QueryParams(
            where: [
              WhereCondition(
                field: 'isAvailable',
                operator: WhereOperator.isEqualTo,
                value: true,
              ),
            ],
            orderBy: 'createdAt',
            descending: true,
          ),
        )
        .map((result) => result.dataOrNull ?? []);
  }

  /// Retrieves all products in a specific [category].
  Future<Result<List<ProductModel>>> getProductsByCategory(
    String category,
  ) async {
    return _firestoreService.getCollection<ProductModel>(
      collection: FirebaseCollections.products,
      fromFirestore: (data, docId) =>
          ProductModel.fromJson({...data, 'id': docId}),
      queryParams: QueryParams(
        where: [
          WhereCondition(
            field: 'category',
            operator: WhereOperator.isEqualTo,
            value: category,
          ),
          WhereCondition(
            field: 'isAvailable',
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
