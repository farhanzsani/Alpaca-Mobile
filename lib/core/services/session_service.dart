/// Session management service for the ALPACA application.
///
/// Handles saving, loading, and validating user sessions
/// using SharedPreferences for persistent storage.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User roles available in the ALPACA application.
enum UserRole {
  /// UMKM business owner role.
  ownerUmkm('owner_umkm'),

  /// Customer role.
  customer('customer');

  const UserRole(this.value);

  /// The string value stored in session.
  final String value;

  /// Creates a [UserRole] from a string value.
  static UserRole? fromString(String? value) {
    if (value == null) return null;
    return UserRole.values.cast<UserRole?>().firstWhere(
          (role) => role?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents a user session with authentication details.
@immutable
class UserSession {
  /// Creates a [UserSession] instance.
  const UserSession({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Creates a [UserSession] from a JSON map.
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      uid: json['uid'] as String,
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String?) ?? UserRole.customer,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  /// The Firebase user ID.
  final String uid;

  /// The user's email address.
  final String email;

  /// The user's role in the application.
  final UserRole role;

  /// When the session was created.
  final DateTime createdAt;

  /// When the session expires.
  final DateTime expiresAt;

  /// Whether the session has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the session is still valid.
  bool get isValid => !isExpired && uid.isNotEmpty;

  /// Converts the session to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role.value,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

/// Service responsible for managing user sessions.
///
/// Provides methods to save, load, validate, and clear user sessions
/// stored in SharedPreferences.
///
/// Usage:
/// ```dart
/// final sessionService = SessionService(prefs: sharedPreferences);
/// await sessionService.saveSession(session);
/// final currentSession = await sessionService.loadSession();
/// ```
class SessionService extends ChangeNotifier {
  /// Creates a [SessionService] with the given [SharedPreferences] instance.
  SessionService({
    required SharedPreferences prefs,
    Logger? logger,
  })  : _prefs = prefs,
        _logger = logger ?? Logger();

  final SharedPreferences _prefs;
  final Logger _logger;

  /// SharedPreferences key for storing the session.
  static const String _sessionKey = 'alpaca_user_session';

  /// Default session duration (7 days).
  static const Duration defaultSessionDuration = Duration(days: 7);

  /// The currently loaded session, if any.
  UserSession? _currentSession;

  /// Returns the current session, or null if not loaded or invalid.
  UserSession? get currentSession => _currentSession;

  /// Whether a valid session exists.
  bool get hasValidSession => _currentSession?.isValid ?? false;

  /// Returns the current user's role, or null if no session.
  UserRole? get currentRole => _currentSession?.role;

  /// Returns the current user's UID, or null if no session.
  String? get currentUid => _currentSession?.uid;

  /// Returns the current user's email, or null if no session.
  String? get currentEmail => _currentSession?.email;

  /// Saves a user session to SharedPreferences.
  ///
  /// [uid] - The Firebase user ID.
  /// [email] - The user's email address.
  /// [role] - The user's role in the application.
  /// [duration] - How long the session should last. Defaults to 7 days.
  Future<bool> saveSession({
    required String uid,
    required String email,
    required UserRole role,
    Duration duration = defaultSessionDuration,
  }) async {
    try {
      final now = DateTime.now();
      final session = UserSession(
        uid: uid,
        email: email,
        role: role,
        createdAt: now,
        expiresAt: now.add(duration),
      );

      final jsonString = jsonEncode(session.toJson());
      final success = await _prefs.setString(_sessionKey, jsonString);

      if (success) {
        _currentSession = session;
        notifyListeners();
        _logger.d('Session saved for user: $email (role: ${role.value})');
      }

      return success;
    } catch (e, st) {
      _logger.e('Failed to save session', error: e, stackTrace: st);
      return false;
    }
  }

  /// Loads the user session from SharedPreferences.
  ///
  /// Returns the [UserSession] if found and valid, or null otherwise.
  Future<UserSession?> loadSession() async {
    try {
      final jsonString = _prefs.getString(_sessionKey);
      if (jsonString == null) {
        _logger.d('No session found in storage');
        _currentSession = null;
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final session = UserSession.fromJson(json);

      if (session.isExpired) {
        _logger.w('Session expired for user: ${session.email}');
        await clearSession();
        return null;
      }

      _currentSession = session;
      notifyListeners();
      _logger.d('Session loaded for user: ${session.email}');
      return session;
    } catch (e, st) {
      _logger.e('Failed to load session', error: e, stackTrace: st);
      await clearSession();
      return null;
    }
  }

  /// Clears the current session from memory and storage.
  Future<bool> clearSession() async {
    try {
      final success = await _prefs.remove(_sessionKey);
      _currentSession = null;
      notifyListeners();
      _logger.d('Session cleared');
      return success;
    } catch (e, st) {
      _logger.e('Failed to clear session', error: e, stackTrace: st);
      return false;
    }
  }

  /// Checks if the current session is valid (exists and not expired).
  ///
  /// If no session is loaded in memory, attempts to load from storage.
  Future<bool> isSessionValid() async {
    if (_currentSession != null) {
      if (_currentSession!.isValid) {
        return true;
      }
      // Session exists but is expired
      await clearSession();
      return false;
    }

    // Try loading from storage
    final session = await loadSession();
    return session?.isValid ?? false;
  }

  /// Refreshes the session expiry time without changing other details.
  ///
  /// Useful for extending the session when the user is active.
  Future<bool> refreshSession({
    Duration duration = defaultSessionDuration,
  }) async {
    if (_currentSession == null) return false;

    return saveSession(
      uid: _currentSession!.uid,
      email: _currentSession!.email,
      role: _currentSession!.role,
      duration: duration,
    );
  }
}
