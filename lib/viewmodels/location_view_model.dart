import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/repositories/business_repository.dart';
import 'package:alpaca_mobile/core/services/cache_service.dart';
import 'package:alpaca_mobile/core/exceptions/app_exception.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/core/enums/view_state.dart';

/// ViewModel for business location and GPS management.
///
/// Handles current position retrieval, and CRUD operations for
/// business locations on the local culinary tourism map.
class LocationViewModel extends ChangeNotifier {
  /// Creates a [LocationViewModel] with the given [BusinessRepository].
  LocationViewModel({
    required BusinessRepository businessRepository,
    CacheService? cacheService,
  }) : _businessRepository = businessRepository,
       _cacheService = cacheService;

  final BusinessRepository _businessRepository;
  final CacheService? _cacheService;

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

  BusinessLocationModel? _profileBusiness;
  /// A single business location loaded for store profile view.
  BusinessLocationModel? get profileBusiness => _profileBusiness;

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
    print('[LocationViewModel] getCurrentLocation: ownerId=$ownerId');
    _setLoading(true);
    _clearError();

    final result = await _businessRepository.getBusinessByOwner(ownerId);

    result.when(
      success: (business) {
        print('[LocationViewModel] getCurrentLocation: success, business=$business');
        _businessLocation = business;
        _viewState = business != null ? ViewState.loaded : ViewState.empty;
      },
      failure: (exception) {
        print('[LocationViewModel] getCurrentLocation: failure, error=${exception.message}');
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
    print('[LocationViewModel] getCurrentLocation: done, businessLocation=$_businessLocation');
  }

  /// Saves a new business location to Firestore.
  ///
  /// [location] contains all the business location details to persist.
  Future<void> saveBusinessLocation(BusinessLocationModel location) async {
    _setLoading(true);
    _clearError();

    final result = await _businessRepository.createBusiness(location);

    result.when(
      success: (savedLocation) { _businessLocation = savedLocation;
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

  /// Loads a single business location by [ownerId] for store profile view.
  Future<void> loadProfileBusiness(String ownerId) async {
    print('[LocationViewModel] loadProfileBusiness: ownerId=$ownerId');
    _setLoading(true);
    _clearError();

    try {
      final result = await _businessRepository.getBusinessByOwner(ownerId).timeout(
        const Duration(seconds: 10),
        onTimeout: () => Result.failure(AppException(message: 'Timeout: Gagal memuat data toko')),
      );

      result.when(
        success: (business) {
          print('[LocationViewModel] loadProfileBusiness: success, business=${business?.businessName ?? 'null'}');
          _profileBusiness = business;
          _viewState = business != null ? ViewState.loaded : ViewState.empty;
        },
        failure: (exception) {
          print('[LocationViewModel] loadProfileBusiness: failure, error=${exception.message}');
          _error = exception.message;
          _viewState = ViewState.error;
        },
      );
    } catch (e) {
      print('[LocationViewModel] loadProfileBusiness: exception, error=$e');
      _error = 'Terjadi kesalahan saat memuat data toko';
      _viewState = ViewState.error;
    }

    _setLoading(false);
    print('[LocationViewModel] loadProfileBusiness: done, profileBusiness=${_profileBusiness?.businessName ?? 'null'}');
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

  // Cache for ongoing requests to prevent duplicate API calls
  final Map<String, Future<String?>> _ongoingRequests = {};

  /// Gets business name by owner ID for quick lookups.
  Future<String?> getBusinessNameByOwner(String ownerId) async {
    // Check if there's already an ongoing request for this owner
    if (_ongoingRequests.containsKey(ownerId)) {
      return _ongoingRequests[ownerId]!;
    }
    
    final cacheKey = 'business_name_$ownerId';
    
    // Try cache first
    if (_cacheService != null) {
      final cachedName = _cacheService!.load<String>(cacheKey);
      if (cachedName != null) {
        print('[LocationViewModel] Cache hit for business name: $ownerId -> $cachedName');
        return cachedName;
      }
    }
    
    // Create and store the request future
    final requestFuture = _fetchBusinessName(ownerId, cacheKey);
    _ongoingRequests[ownerId] = requestFuture;
    
    try {
      final result = await requestFuture;
      return result;
    } finally {
      // Clean up the ongoing request
      _ongoingRequests.remove(ownerId);
    }
  }

  Future<String?> _fetchBusinessName(String ownerId, String cacheKey) async {
    try {
      print('[LocationViewModel] Cache miss, fetching business name for: $ownerId');
      final result = await _businessRepository.getBusinessByOwner(ownerId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => Result.failure(AppException(message: 'Timeout')),
      );
      
      return result.when(
        success: (business) {
          final businessName = business?.businessName;
          // Cache the result if we have a cache service and got a name
          if (_cacheService != null && businessName != null) {
            _cacheService!.save(
              key: cacheKey,
              data: businessName,
              ttl: const Duration(minutes: 30), // Cache for 30 minutes
            );
            print('[LocationViewModel] Cached business name: $ownerId -> $businessName');
          }
          return businessName;
        },
        failure: (_) => null,
      );
    } catch (e) {
      print('[LocationViewModel] getBusinessNameByOwner error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _businessesSubscription?.cancel();
    _ongoingRequests.clear();
    super.dispose();
  }
}

