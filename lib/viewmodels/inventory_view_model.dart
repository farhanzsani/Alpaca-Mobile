import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:alpaca_mobile/models/inventory_model.dart';
import 'package:alpaca_mobile/repositories/inventory_repository.dart';

/// Represents the current state of a view.
enum ViewState { initial, loading, loaded, error, empty }

/// ViewModel for inventory management.
///
/// Manages inventory items, provides low stock alerts, and supports
/// realtime updates via stream subscriptions from Firestore.
class InventoryViewModel extends ChangeNotifier {
  /// Creates an [InventoryViewModel] with the given [InventoryRepository].
  InventoryViewModel({required InventoryRepository inventoryRepository})
      : _inventoryRepository = inventoryRepository;

  final InventoryRepository _inventoryRepository;

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

  List<InventoryModel> _items = [];
  /// All inventory items for the current owner.
  List<InventoryModel> get items => List.unmodifiable(_items);

  /// Items where current quantity is at or below the minimum stock threshold.
  ///
  /// Uses the [InventoryModel.isLowStock] getter which checks
  /// `quantity < minimumStock`.
  List<InventoryModel> get lowStockItems =>
      _items.where((item) => item.quantity <= item.minimumStock).toList();

  StreamSubscription<List<InventoryModel>>? _itemsSubscription;

  // --- Methods ---

  /// Loads all inventory items for the given [ownerId].
  ///
  /// Fetches items from the repository and updates the local state.
  Future<void> loadItems(String ownerId) async {
    _setLoading(true);
    _clearError();

    final result = await _inventoryRepository.getItems(ownerId);

    result.when(
      success: (items) {
        _items = items;
        _viewState = items.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Adds a new inventory item.
  ///
  /// On success, the item (with the generated Firestore ID) is appended
  /// to the local list.
  Future<void> addItem(InventoryModel item) async {
    _setLoading(true);
    _clearError();

    final result = await _inventoryRepository.addItem(item);

    result.when(
      success: (docId) {
        // Add the item with the Firestore-generated ID to the local list.
        final savedItem = item.copyWith(id: docId);
        _items.add(savedItem);
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Updates an existing inventory item.
  ///
  /// Replaces the item in the local list with the updated version.
  Future<void> updateItem(InventoryModel item) async {
    _setLoading(true);
    _clearError();

    final result = await _inventoryRepository.updateItem(item);

    result.when(
      success: (_) {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item;
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

  /// Deletes an inventory item by its [itemId].
  ///
  /// Removes the item from the local list on success.
  Future<void> deleteItem(String itemId) async {
    _setLoading(true);
    _clearError();

    final result = await _inventoryRepository.deleteItem(itemId);

    result.when(
      success: (_) {
        _items.removeWhere((item) => item.id == itemId);
        _viewState = _items.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Subscribes to realtime inventory updates for the given [ownerId].
  ///
  /// Cancels any existing subscription before creating a new one.
  /// The local item list is updated automatically when changes occur
  /// in Firestore.
  void subscribeToItems(String ownerId) {
    _itemsSubscription?.cancel();
    _viewState = ViewState.loading;
    notifyListeners();

    _itemsSubscription = _inventoryRepository.streamItems(ownerId).listen(
      (items) {
        _items = items;
        _viewState = items.isEmpty ? ViewState.empty : ViewState.loaded;
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
    _itemsSubscription?.cancel();
    super.dispose();
  }
}
