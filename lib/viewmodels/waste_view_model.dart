import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:alpaca_mobile/models/waste_resource_model.dart';
import 'package:alpaca_mobile/repositories/waste_repository.dart';

/// Represents the current state of a view.
enum ViewState { initial, loading, loaded, error, empty }

/// ViewModel for waste resource management.
///
/// Manages waste tracking for the circular economy feature, including
/// categorization and identification of reusable materials that can
/// be repurposed in other processes.
class WasteViewModel extends ChangeNotifier {
  /// Creates a [WasteViewModel] with the given [WasteRepository].
  WasteViewModel({required WasteRepository wasteRepository})
      : _wasteRepository = wasteRepository;

  final WasteRepository _wasteRepository;

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

  List<WasteResourceModel> _wasteItems = [];
  /// All loaded waste resource items.
  List<WasteResourceModel> get wasteItems => List.unmodifiable(_wasteItems);

  /// Items that are marked as reusable for circular economy purposes.
  List<WasteResourceModel> get reusableItems =>
      _wasteItems.where((item) => item.reusable).toList();

  StreamSubscription<List<WasteResourceModel>>? _wasteSubscription;

  // --- Methods ---

  /// Loads all waste resources for the given [ownerId].
  ///
  /// Fetches waste items from Firestore and updates local state.
  Future<void> loadWaste(String ownerId) async {
    _setLoading(true);
    _clearError();

    final result = await _wasteRepository.getWasteByOwner(ownerId);

    result.when(
      success: (items) {
        _wasteItems = items;
        _viewState = items.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Adds a new waste resource record.
  ///
  /// On success, the item (with the generated Firestore ID) is appended
  /// to the local list.
  Future<void> addWaste(WasteResourceModel waste) async {
    _setLoading(true);
    _clearError();

    final result = await _wasteRepository.addWaste(waste);

    result.when(
      success: (savedWaste) {
        _wasteItems.add(savedWaste);
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Updates an existing waste resource record.
  ///
  /// Replaces the item in the local list with the updated version.
  Future<void> updateWaste(WasteResourceModel waste) async {
    _setLoading(true);
    _clearError();

    final result = await _wasteRepository.updateWaste(waste);

    result.when(
      success: (_) {
        final index = _wasteItems.indexWhere((w) => w.id == waste.id);
        if (index != -1) {
          _wasteItems[index] = waste;
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

  /// Deletes a waste resource by its [wasteId].
  ///
  /// Removes the item from the local list on success.
  Future<void> deleteWaste(String wasteId) async {
    _setLoading(true);
    _clearError();

    final result = await _wasteRepository.deleteWaste(wasteId);

    result.when(
      success: (_) {
        _wasteItems.removeWhere((w) => w.id == wasteId);
        _viewState = _wasteItems.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Loads only reusable waste items for the given [ownerId].
  ///
  /// Useful for displaying materials available for circular economy reuse.
  Future<void> loadReusable(String ownerId) async {
    _setLoading(true);
    _clearError();

    final result = await _wasteRepository.getReusableWaste(ownerId);

    result.when(
      success: (items) {
        _wasteItems = items;
        _viewState = items.isEmpty ? ViewState.empty : ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Subscribes to realtime waste resource updates for the given [ownerId].
  ///
  /// Cancels any existing subscription before creating a new one.
  void subscribeToWaste(String ownerId) {
    _wasteSubscription?.cancel();
    _viewState = ViewState.loading;
    notifyListeners();

    _wasteSubscription = _wasteRepository.streamWaste(ownerId).listen(
      (items) {
        _wasteItems = items;
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

  /// Filters waste items by [category].
  ///
  /// Returns a filtered view without modifying the underlying data.
  /// If [category] is null or empty, returns all waste items.
  List<WasteResourceModel> filterByCategory(String? category) {
    if (category == null || category.isEmpty) {
      return List.unmodifiable(_wasteItems);
    }
    return _wasteItems
        .where((w) => w.category.toLowerCase() == category.toLowerCase())
        .toList();
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
    _wasteSubscription?.cancel();
    super.dispose();
  }
}

