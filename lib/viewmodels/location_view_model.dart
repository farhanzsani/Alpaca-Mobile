import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/repositories/business_repository.dart';

/// Represents the current state of a view.
enum ViewState { initial, loading, loaded, error, empty }

/// ViewModel for business location and GPS management.
///
/// Handles current position retrieval, and CRUD operations for
/// business locations on the local culinary tourism map.
class LocationViewModel extends ChangeNotifier {
  /// Creates a [LocationViewModel] with the given [BusinessRepository].
  LocationViewModel({required BusinessRepository businessRepository})
      : _businessRepository = businessRepository;

  final BusinessRepository _businessRepository;

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

  BusinessLocationModel? _businessLocation;
  /// The current owner's business location, or null if not set.
  BusinessLocationModel? get businessLocation => _businessLocation;

  List<BusinessLocationModel> _allBusinesses = [];
  /// All registered business locations for the tourism map.
  List<BusinessLocationModel> get allBusinesses =>
      List.unmodifiable(_allBusinesses);

  ({double latitude, double longitude})? _currentPosition;
  /// The device's current GPS position, or null if not yet retrieved.
  ({double latitude, double longitude})? get currentPosition => _currentPosition;

  StreamSubscription<List<BusinessLocationModel>>? _businessesSubscription;

  // --- Methods ---

  /// Sets the current GPS position of the device.
  ///
  /// This should be called by the UI layer after obtaining location
  /// permission and retrieving the device position using a location plugin
  /// (e.g., geolocator).
  void setCurrentPosition({
    required double latitude,
    required double longitude,
  }) {
    _currentPosition = (latitude: latitude, longitude: longitude);
    notifyListeners();
  }

  /// Loads the business location for the given [ownerId].
  ///
  /// Fetches the owner's registered business from Firestore.
  Future<void> getCurrentLocation(String ownerId) async {
    _setLoading(true);
    _clearError();

    final result = await _businessRepository.getBusinessByOwner(ownerId);

    result.when(
      success: (business) {
        _businessLocation = business;
        _viewState = business != null ? ViewState.loaded : ViewState.empty;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Saves a new business location to Firestore.
  ///
  /// [location] contains all the business location details to persist.
  Future<void> saveBusinessLocation(BusinessLocationModel location) async {
    _setLoading(true);
    _clearError();

    final result = await _businessRepository.createBusiness(location);

    result.when(
      success: (docId) {
        _businessLocation = location.copyWith(id: docId);
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Updates an existing business location.
  ///
  /// [location] contains the updated business location data.
  Future<void> updateBusinessLocation(BusinessLocationModel location) async {
    _setLoading(true);
    _clearError();

    final result = await _businessRepository.updateBusiness(location);

    result.when(
      success: (_) {
        _businessLocation = location;
        // Also update in the all businesses list if present.
        final index = _allBusinesses.indexWhere((b) => b.id == location.id);
        if (index != -1) {
          _allBusinesses[index] = location;
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

  /// Subscribes to all business locations for the map display.
  ///
  /// Populates [allBusinesses] with all registered business locations
  /// and updates in realtime as businesses are added or modified.
  void loadAllBusinesses() {
    _businessesSubscription?.cancel();
    _viewState = ViewState.loading;
    notifyListeners();

    _businessesSubscription =
        _businessRepository.getAllBusinesses().listen(
      (businesses) {
        _allBusinesses = businesses;
        _viewState = businesses.isEmpty ? ViewState.empty : ViewState.loaded;
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
    _businessesSubscription?.cancel();
    super.dispose();
  }
}
