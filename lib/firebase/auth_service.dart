/// Firebase Authentication service for the ALPACA application.
///
/// Provides methods for user authentication including sign-in, registration,
/// sign-out, password reset, Google Sign-In, and profile management.
/// All methods return [Result<T>] for consistent error handling.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:alpaca_mobile/core/exceptions/app_exception.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/firebase_service.dart';

/// Service class for Firebase Authentication operations.
///
/// Usage:
/// ```dart
/// final authService = AuthService();
/// final result = await authService.signInWithEmail('user@example.com', 'password');
/// result.when(
///   success: (user) => print('Signed in as ${user.email}'),
///   failure: (error) => print('Error: ${error.message}'),
/// );
/// ```
class AuthService extends FirebaseService {
  /// Creates an [AuthService] with an optional [FirebaseAuth] instance.
  ///
  /// If no instance is provided, uses [FirebaseAuth.instance].
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    super.logger,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Signs in a user with email and password.
  ///
  /// Returns the authenticated [User] on success, or an [AuthException] on failure.
  Future<Result<User>> signInWithEmail(String email, String password) async {
    return guardedCall(
      () async {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user;
        if (user == null) {
          throw const AuthException(
            message: 'Gagal mendapatkan data pengguna setelah login.',
            code: 'NULL_USER',
          );
        }
        return user;
      },
      operationName: 'signInWithEmail',
    );
  }

  /// Signs in a user with Google account.
  ///
  /// Opens the Google Sign-In flow, obtains credentials, and authenticates
  /// with Firebase. Returns the authenticated [User] on success.
  ///
  /// Note: Google Sign-In is only supported on Android, iOS, and Web.
  /// On unsupported platforms (Windows, Linux), this will return a failure.
  Future<Result<User>> signInWithGoogle() async {
    return guardedCall(
      () async {
        // Check platform support.
        if (!_isGoogleSignInSupported()) {
          throw const AuthException(
            message: 'Google Sign-In tidak tersedia di platform ini. '
                'Gunakan email dan password untuk login.',
            code: 'PLATFORM_NOT_SUPPORTED',
          );
        }

        // Trigger the Google Sign-In flow.
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw const AuthException(
            message: 'Login Google dibatalkan oleh pengguna.',
            code: 'GOOGLE_SIGN_IN_CANCELLED',
          );
        }

        // Obtain the auth details from the request.
        final googleAuth = await googleUser.authentication;

        // Create a new credential.
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential.
        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user == null) {
          throw const AuthException(
            message: 'Gagal mendapatkan data pengguna setelah login Google.',
            code: 'NULL_USER',
          );
        }

        logger.i(
          'signInWithGoogle: user signed in successfully '
          '(uid: ${user.uid}, email: ${user.email})',
        );
        return user;
      },
      operationName: 'signInWithGoogle',
    );
  }

  /// Checks if Google Sign-In is supported on the current platform.
  bool _isGoogleSignInSupported() {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        kIsWeb;
  }

  /// Registers a new user with email, password, display name, and role.
  ///
  /// Creates the Firebase Auth account and updates the user profile with
  /// the provided [displayName]. The [role] is stored as a custom claim
  /// concept but set via display name metadata until Cloud Functions
  /// handle custom claims.
  ///
  /// Returns the newly created [User] on success.
  Future<Result<User>> registerWithEmail(
    String email,
    String password,
    String displayName,
    String role,
  ) async {
    return guardedCall(
      () async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user;
        if (user == null) {
          throw const AuthException(
            message: 'Gagal membuat akun pengguna.',
            code: 'NULL_USER',
          );
        }

        // Update the user profile with display name.
        await user.updateDisplayName(displayName);

        // Reload user to get updated profile.
        await user.reload();
        final updatedUser = _auth.currentUser;
        if (updatedUser == null) {
          throw const AuthException(
            message: 'Gagal memuat ulang data pengguna.',
            code: 'RELOAD_FAILED',
          );
        }

        logger.i(
          'registerWithEmail: user registered successfully '
          '(uid: ${updatedUser.uid}, role: $role)',
        );
        return updatedUser;
      },
      operationName: 'registerWithEmail',
    );
  }

  /// Signs out the currently authenticated user.
  ///
  /// Also signs out from Google if the user was signed in with Google.
  /// Returns `void` wrapped in [Result] on success.
  Future<Result<void>> signOut() async {
    return guardedCall(
      () async {
        // Sign out from Google if signed in.
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
        await _auth.signOut();
        logger.i('signOut: user signed out successfully');
      },
      operationName: 'signOut',
    );
  }

  /// Returns the currently authenticated user, or `null` if not signed in.
  ///
  /// This is a synchronous check of the cached auth state.
  Future<Result<User?>> getCurrentUser() async {
    return guardedCall(
      () async {
        final user = _auth.currentUser;
        if (user != null) {
          // Reload to ensure we have the latest profile data.
          await user.reload();
          return _auth.currentUser;
        }
        return null;
      },
      operationName: 'getCurrentUser',
    );
  }

  /// Stream of authentication state changes.
  ///
  /// Emits the current [User] when signed in, or `null` when signed out.
  /// This stream is useful for reactive UI updates.
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Sends a password reset email to the specified [email].
  ///
  /// Returns `void` wrapped in [Result] on success.
  Future<Result<void>> resetPassword(String email) async {
    return guardedCall(
      () async {
        await _auth.sendPasswordResetEmail(email: email.trim());
        logger.i('resetPassword: reset email sent to $email');
      },
      operationName: 'resetPassword',
    );
  }

  /// Updates the current user's profile information.
  ///
  /// Both [displayName] and [photoUrl] are optional. Only non-null values
  /// will be updated.
  ///
  /// Returns the updated [User] on success.
  Future<Result<User>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    return guardedCall(
      () async {
        final user = _auth.currentUser;
        if (user == null) {
          throw AuthException.sessionExpired();
        }

        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }

        // Reload to get updated profile.
        await user.reload();
        final updatedUser = _auth.currentUser;
        if (updatedUser == null) {
          throw const AuthException(
            message: 'Gagal memuat ulang data pengguna setelah update.',
            code: 'RELOAD_FAILED',
          );
        }

        logger.i('updateProfile: profile updated successfully');
        return updatedUser;
      },
      operationName: 'updateProfile',
    );
  }

  /// Sends an email verification to the current user.
  ///
  /// Returns `void` wrapped in [Result] on success.
  Future<Result<void>> sendEmailVerification() async {
    return guardedCall(
      () async {
        final user = _auth.currentUser;
        if (user == null) {
          throw AuthException.sessionExpired();
        }
        await user.sendEmailVerification();
        logger.i('sendEmailVerification: verification email sent');
      },
      operationName: 'sendEmailVerification',
    );
  }

  /// Deletes the current user's account.
  ///
  /// This is a destructive operation and cannot be undone.
  /// Returns `void` wrapped in [Result] on success.
  Future<Result<void>> deleteAccount() async {
    return guardedCall(
      () async {
        final user = _auth.currentUser;
        if (user == null) {
          throw AuthException.sessionExpired();
        }
        await user.delete();
        logger.i('deleteAccount: account deleted successfully');
      },
      operationName: 'deleteAccount',
    );
  }
}

