import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:alpaca_mobile/models/user_model.dart';
import 'package:alpaca_mobile/repositories/auth_repository.dart';

/// Represents the current state of a view.
enum ViewState { initial, loading, loaded, error, empty }

/// ViewModel for authentication and user session management.
///
/// Manages login, registration, logout, and auth state observation.
/// Provides role-based access helpers for owner and customer roles.
class AuthViewModel extends ChangeNotifier {
  /// Creates an [AuthViewModel] with the given [AuthRepository].
  ///
  /// Automatically starts listening to auth state changes on creation.
  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository {
    _listenToAuthStateChanges();
  }

  final AuthRepository _authRepository;

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

  UserModel? _currentUser;
  /// The currently authenticated user, or null if not signed in.
  UserModel? get currentUser => _currentUser;

  /// Whether a user is currently authenticated (Firestore data loaded).
  bool get isAuthenticated => _currentUser != null;

  /// Instant sync check: Firebase has a cached session from a previous login.
  /// True immediately on app start if user was previously logged in.
  /// Does NOT require Firestore or any network call.
  bool get hasFirebaseSession => _authRepository.hasActiveSession;

  /// The role of the current user, or null if not authenticated.
  UserRole? get userRole => _currentUser?.role;

  /// Whether the current user is a business owner (UMKM owner).
  bool get isOwner => _currentUser?.role == UserRole.ownerUmkm;

  /// Whether the current user is a customer/tourist.
  bool get isCustomer => _currentUser?.role == UserRole.customer;

  StreamSubscription<UserModel?>? _authStateSubscription;

  // --- Methods ---

  /// Listens to authentication state changes from the repository.
  ///
  /// Updates [currentUser] reactively whenever the auth state changes.
  void _listenToAuthStateChanges() {
    _authStateSubscription = _authRepository.authStateChanges().listen(
      (user) {
        _currentUser = user;
        _viewState = user != null ? ViewState.loaded : ViewState.initial;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error.toString();
        _viewState = ViewState.error;
        notifyListeners();
      },
    );
  }

  /// Signs in a user with email and password.
  ///
  /// Sets [isLoading] to true during the operation and updates
  /// [currentUser] on success or [error] on failure.
  Future<void> login(String email, String password) async {
    _setLoading(true);
    clearError();

    final result = await _authRepository.login(email, password);

    result.when(
      success: (user) {
        _currentUser = user;
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Registers a new user with the provided credentials and profile info.
  ///
  /// [email] and [password] are required for authentication.
  /// [displayName] is the user's display name.
  /// [role] determines the user's access level in the platform
  /// (passed as the string value, e.g. 'owner_umkm' or 'customer').
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    _setLoading(true);
    clearError();

    final result = await _authRepository.register(
      email,
      password,
      displayName,
      role.toJson(),
    );

    result.when(
      success: (user) {
        _currentUser = user;
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Signs out the current user and clears local state.
  Future<void> logout() async {
    _setLoading(true);
    clearError();

    final result = await _authRepository.logout();

    result.when(
      success: (_) {
        _currentUser = null;
        _viewState = ViewState.initial;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Signs in a user with their Google account.
  ///
  /// Opens the Google Sign-In flow and authenticates with Firebase.
  /// Creates a Firestore user document if it doesn't exist.
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    clearError();

    final result = await _authRepository.signInWithGoogle();

    result.when(
      success: (user) {
        _currentUser = user;
        _viewState = ViewState.loaded;
      },
      failure: (exception) {
        _error = exception.message;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Checks the current authentication status.
  ///
  /// Useful for app startup to determine if the user is still signed in.
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    clearError();

    final result = await _authRepository.getCurrentUser();

    result.when(
      success: (user) {
        _currentUser = user;
        _viewState = user != null ? ViewState.loaded : ViewState.initial;
      },
      failure: (exception) {
        _error = exception.message;
        _currentUser = null;
        _viewState = ViewState.error;
      },
    );

    _setLoading(false);
  }

  /// Waits until Firestore user data is fully loaded (or times out).
  /// Use this in splash to ensure [currentUser] and [userRole] are populated.
  Future<void> waitForAuthResolution() async {
    // Already have user data — done immediately.
    if (_currentUser != null) return;

    final completer = Completer<void>();
    void listener() {
      // Resolved when we have a user OR when viewState is no longer initial/loading
      if (_currentUser != null || (_viewState != ViewState.initial && !_isLoading)) {
        if (!completer.isCompleted) completer.complete();
      }
    }
    addListener(listener);

    await Future.any([
      completer.future,
      Future.delayed(const Duration(seconds: 8)), // safety timeout
    ]);

    removeListener(listener);
  }

  /// Updates the user's profile information.
  Future<void> updateProfile({String? displayName, String? photoUrl, String? phoneNumber}) async {
    _setLoading(true);
    clearError();

    final result = await _authRepository.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      phoneNumber: phoneNumber,
    );

    result.when(
      success: (_) {
        // We can just rely on checkAuthStatus to reload, or authStateChanges will trigger.
      },
      failure: (exception) {
        _error = exception.message;
      },
    );
    
    // Refresh user data
    await checkAuthStatus();

    _setLoading(false);
  }

  /// Clears the current error message.
  void clearError() {
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
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
