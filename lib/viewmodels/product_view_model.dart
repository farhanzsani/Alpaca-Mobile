import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:alpaca_mobile/models/product_model.dart';
import 'package:alpaca_mobile/repositories/product_repository.dart';

/// Represents the current state of a view.
enum ViewState { initial, loading, loaded, error, empty }

/// ViewModel for product catalog management.
///
/// Manages products listed by business owners, supports realtime updates
/// via stream subscriptions, and provides category filtering for the
/// public product showcase.
class ProductViewModel extends ChangeNotifier {
  /// Creates a [ProductViewModel] with the given [ProductRepository].
  ProductViewModel({required ProductRepository productRepository})
      : _productRepository = productRepository;

  final ProductRepository _productRepository;

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

  List<ProductModel> _products = [];
  /// Products belonging to the current owner.
  List<ProductModel> get products => List.unmodifiable(_products);

  List<ProductModel> _allProducts = [];
  /// All public/available products (visible to customers/tourists).
  List<ProductModel> get allProducts => List.unmodifiable(_allProducts);

  StreamSubscription<List<ProductModel>>? _productsSubscription;
  StreamSubscription<List<ProductModel>>? _allProductsSubscription;

  // --- Methods ---

  /// Loads products for the given [ownerId].
  ///
  /// Fetches the owner's product catalog from Firestore.
  Future<void> loadProducts(String ownerId) async {
    _setLoading(true);
    _clearError();

    final result = await _productRepository.getProductsByOwner(ownerId);

    result.when(
      success: (products) {
        _products = products;
        _viewState = products.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Subscribes to all publicly available products in realtime.
  ///
  /// Used by customers/tourists to browse the product catalog.
  /// Only includes products where [ProductModel.isAvailable] is true.
  void loadAllProducts() {
    _allProductsSubscription?.cancel();
    _viewState = ViewState.loading;
    notifyListeners();

    _allProductsSubscription =
        _productRepository.streamAllProducts().listen(
      (products) {
        _allProducts = products;
        _viewState = products.isEmpty ? ViewState.empty : ViewState.loaded;
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

  /// Adds a new product to the catalog.
  ///
  /// On success, the product (with the generated Firestore ID) is
  /// appended to the local owner's product list.
  Future<void> addProduct(ProductModel product) async {
    _setLoading(true);
    _clearError();

    final result = await _productRepository.addProduct(product);

    result.when(
      success: (docId) {
        final savedProduct = product.copyWith(id: docId);
        _products.add(savedProduct);
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Updates an existing product.
  ///
  /// Replaces the product in the local lists with the updated version.
  Future<void> updateProduct(ProductModel product) async {
    _setLoading(true);
    _clearError();

    final result = await _productRepository.updateProduct(product);

    result.when(
      success: (_) {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product;
        }
        // Also update in allProducts if present.
        final allIndex = _allProducts.indexWhere((p) => p.id == product.id);
        if (allIndex != -1) {
          _allProducts[allIndex] = product;
        }
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Deletes a product by its [productId].
  ///
  /// Removes the product from both local lists on success.
  Future<void> deleteProduct(String productId) async {
    _setLoading(true);
    _clearError();

    final result = await _productRepository.deleteProduct(productId);

    result.when(
      success: (_) {
        _products.removeWhere((p) => p.id == productId);
        _allProducts.removeWhere((p) => p.id == productId);
        _viewState = _products.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Filters the all-products list by [category].
  ///
  /// Returns a filtered view without modifying the underlying data.
  /// If [category] is null or empty, returns all products.
  List<ProductModel> filterByCategory(String? category) {
    if (category == null || category.isEmpty) {
      return List.unmodifiable(_allProducts);
    }
    return _allProducts
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Subscribes to realtime product updates for the given [ownerId].
  ///
  /// Cancels any existing subscription before creating a new one.
  /// The local product list is updated automatically when changes occur.
  void subscribeToProducts(String ownerId) {
    _productsSubscription?.cancel();
    _viewState = ViewState.loading;
    notifyListeners();

    _productsSubscription =
        _productRepository.streamProducts(ownerId).listen(
      (products) {
        _products = products;
        _viewState = products.isEmpty ? ViewState.empty : ViewState.loaded;
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
    _productsSubscription?.cancel();
    _allProductsSubscription?.cancel();
    super.dispose();
  }
}
