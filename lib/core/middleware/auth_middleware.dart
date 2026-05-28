/// Authentication middleware for the ALPACA application.
///
/// Handles session validation, role-based access control,
/// and automatic redirection when sessions expire.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'package:alpaca_mobile/core/services/session_service.dart';

/// Callback type for navigation actions triggered by the middleware.
typedef AuthNavigationCallback = void Function(String route);

/// Authentication middleware that manages session state and access control.
///
/// Provides:
/// - Login status checking
/// - Automatic redirect to login on session expiry
/// - Session storage via [SessionService]
/// - Unauthorized access handling
/// - Role-based access control (owner_umkm, customer)
///
/// Usage:
/// ```dart
/// final authMiddleware = AuthMiddleware(sessionService: sessionService);
/// await authMiddleware.initialize();
///
/// // Check access before navigating
/// if (authMiddleware.canAccess(requiredRole: UserRole.ownerUmkm)) {
///   // Allow navigation
/// }
///
/// // Guard a route
/// authMiddleware.guardRoute(
///   requiredRole: UserRole.ownerUmkm,
///   onUnauthorized: () => navigator.pushReplacementNamed('/login'),
///   onForbidden: () => navigator.pushReplacementNamed('/forbidden'),
/// );
/// ```
class AuthMiddleware extends ChangeNotifier {
  /// Creates an [AuthMiddleware] with the required [SessionService].
  AuthMiddleware({
    required SessionService sessionService,
    Logger? logger,
    this.loginRoute = '/login',
    this.forbiddenRoute = '/forbidden',
  })  : _sessionService = sessionService,
        _logger = logger ?? Logger();

  final SessionService _sessionService;
  final Logger _logger;

  /// Route to redirect to when session is expired or user is not logged in.
  final String loginRoute;

  /// Route to redirect to when user lacks required role.
  final String forbiddenRoute;

  /// Callback invoked when navigation is required (e.g., redirect to login).
  AuthNavigationCallback? onNavigationRequired;

  /// Timer for periodic session validity checks.
  Timer? _sessionCheckTimer;

  /// Whether the middleware has been initialized.
  bool _isInitialized = false;

  /// Whether the user is currently logged in with a valid session.
  bool get isLoggedIn => _sessionService.hasValidSession;

  /// The current user's role, or null if not logged in.
  UserRole? get currentRole => _sessionService.currentRole;

  /// The current user's UID, or null if not logged in.
  String? get currentUid => _sessionService.currentUid;

  /// The current user's email, or null if not logged in.
  String? get currentEmail => _sessionService.currentEmail;

  /// The underlying session service.
  SessionService get sessionService => _sessionService;

  /// Initializes the middleware by loading any existing session.
  ///
  /// Optionally starts periodic session validity checks.
  /// [checkInterval] - How often to verify session validity.
  Future<void> initialize({
    Duration checkInterval = const Duration(minutes: 5),
  }) async {
    if (_isInitialized) return;

    await _sessionService.loadSession();

    // Start periodic session check
    _sessionCheckTimer = Timer.periodic(checkInterval, (_) async {
      await _checkSessionValidity();
    });

    _isInitialized = true;
    _logger.d('AuthMiddleware initialized (logged in: $isLoggedIn)');
  }

  /// Checks if the user is logged in with a valid session.
  ///
  /// Returns `true` if a valid, non-expired session exists.
  Future<bool> checkLoginStatus() async {
    return _sessionService.isSessionValid();
  }

  /// Stores a new authentication session after successful login.
  ///
  /// [uid] - Firebase user ID.
  /// [email] - User's email address.
  /// [role] - User's role in the application.
  /// [duration] - Session duration. Defaults to 7 days.
  Future<bool> storeSession({
    required String uid,
    required String email,
    required UserRole role,
    Duration duration = SessionService.defaultSessionDuration,
  }) async {
    final success = await _sessionService.saveSession(
      uid: uid,
      email: email,
      role: role,
      duration: duration,
    );

    if (success) {
      notifyListeners();
      _logger.i('Session stored for: $email (role: ${role.value})');
    }

    return success;
  }

  /// Clears the current session (logout).
  ///
  /// Optionally triggers navigation to the login route.
  Future<void> logout({bool navigate = true}) async {
    await _sessionService.clearSession();
    notifyListeners();
    _logger.i('User logged out');

    if (navigate) {
      onNavigationRequired?.call(loginRoute);
    }
  }

  /// Checks if the current user can access a resource with the given [requiredRole].
  ///
  /// Returns `true` if:
  /// - The user is logged in with a valid session
  /// - The user's role matches [requiredRole] (if specified)
  ///
  /// If [requiredRole] is null, only login status is checked.
  bool canAccess({UserRole? requiredRole}) {
    if (!isLoggedIn) return false;
    if (requiredRole == null) return true;
    return currentRole == requiredRole;
  }

  /// Guards a route by checking authentication and authorization.
  ///
  /// [requiredRole] - The role required to access the route. Null means any authenticated user.
  /// [onUnauthorized] - Called when the user is not logged in.
  /// [onForbidden] - Called when the user lacks the required role.
  /// [onAuthorized] - Called when access is granted.
  ///
  /// Returns `true` if access is granted.
  Future<bool> guardRoute({
    UserRole? requiredRole,
    VoidCallback? onUnauthorized,
    VoidCallback? onForbidden,
    VoidCallback? onAuthorized,
  }) async {
    // Check login status
    final isValid = await checkLoginStatus();

    if (!isValid) {
      _logger.w('Unauthorized access attempt - session invalid');
      onUnauthorized?.call();
      onNavigationRequired?.call(loginRoute);
      return false;
    }

    // Check role-based access
    if (requiredRole != null && currentRole != requiredRole) {
      _logger.w(
        'Forbidden access attempt - required: ${requiredRole.value}, '
        'current: ${currentRole?.value}',
      );
      onForbidden?.call();
      onNavigationRequired?.call(forbiddenRoute);
      return false;
    }

    onAuthorized?.call();
    return true;
  }

  /// Handles an unauthorized response from the server.
  ///
  /// Clears the session and redirects to login.
  Future<void> handleUnauthorized() async {
    _logger.w('Unauthorized response received - clearing session');
    await logout(navigate: true);
  }

  /// Periodically checks session validity and handles expiry.
  Future<void> _checkSessionValidity() async {
    if (!isLoggedIn) return;

    final isValid = await _sessionService.isSessionValid();
    if (!isValid) {
      _logger.w('Session expired during periodic check');
      await logout(navigate: true);
    }
  }

  /// Disposes of the middleware and cancels timers.
  @override
  void dispose() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = null;
    super.dispose();
    _logger.d('AuthMiddleware disposed');
  }
}
