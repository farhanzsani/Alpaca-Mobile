/// Authentication repository for the ALPACA application.
///
/// Bridges the AuthService and FirestoreService to provide complete
/// authentication workflows including user document management in Firestore.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:alpaca_mobile/core/constants/firebase_constants.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/auth_service.dart';
import 'package:alpaca_mobile/firebase/firestore_service.dart';
import 'package:alpaca_mobile/models/user_model.dart';

/// Repository handling authentication and user profile operations.
///
/// Combines Firebase Auth operations with Firestore user document management
/// to provide a unified authentication API for ViewModels.
class AuthRepository {
  /// Creates an [AuthRepository] with the required Firebase services.
  AuthRepository({
    required AuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService;

  final AuthService _authService;
  final FirestoreService _firestoreService;

  /// Signs in a user with email and password.
  ///
  /// After successful authentication, fetches or creates the user document
  /// from Firestore and returns the [UserModel].
  Future<Result<UserModel>> login(String email, String password) async {
    final authResult = await _authService.signInWithEmail(email, password);

    return authResult.when(
      success: (user) async {
        // Fetch existing user document from Firestore.
        final userDocResult = await _firestoreService.getDocument<UserModel>(
          collection: FirebaseCollections.users,
          id: user.uid,
          fromFirestore: (data, id) => UserModel.fromJson({...data, 'id': id}),
        );

        return userDocResult.when(
          success: (userModel) => Result.success(userModel),
          failure: (exception) async {
            // If user document doesn't exist, create one from auth data.
            final now = DateTime.now();
            final newUser = UserModel(
              id: user.uid,
              email: user.email ?? email,
              displayName: user.displayName ?? '',
              role: UserRole.customer,
              photoUrl: user.photoURL,
              createdAt: now,
              updatedAt: now,
            );

            final createResult = await _firestoreService.addDocument(
              collection: FirebaseCollections.users,
              id: user.uid,
              data: newUser.toJson(),
            );

            return createResult.when(
              success: (_) => Result.success(newUser),
              failure: (e) => Result<UserModel>.failure(e),
            );
          },
        );
      },
      failure: (exception) => Result.failure(exception),
    );
  }

  /// Registers a new user with email, password, display name, and role.
  ///
  /// Creates both the Firebase Auth account and a corresponding user
  /// document in the Firestore 'users' collection.
  Future<Result<UserModel>> register(
    String email,
    String password,
    String displayName,
    String role,
  ) async {
    final authResult = await _authService.registerWithEmail(
      email,
      password,
      displayName,
      role,
    );

    return authResult.when(
      success: (user) async {
        final now = DateTime.now();
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? email,
          displayName: displayName,
          role: UserRole.fromJson(role),
          photoUrl: user.photoURL,
          createdAt: now,
          updatedAt: now,
        );

        // Create user document in Firestore.
        final createResult = await _firestoreService.addDocument(
          collection: FirebaseCollections.users,
          id: user.uid,
          data: userModel.toJson(),
        );

        return createResult.when(
          success: (_) => Result.success(userModel),
          failure: (e) => Result<UserModel>.failure(e),
        );
      },
      failure: (exception) => Result.failure(exception),
    );
  }

  /// Signs out the currently authenticated user.
  Future<Result<void>> logout() async {
    return _authService.signOut();
  }

  /// Signs in a user with Google account.
  ///
  /// After successful Google authentication, fetches or creates the user
  /// document in Firestore. For new Google users, defaults to [UserRole.customer].
  Future<Result<UserModel>> signInWithGoogle() async {
    final authResult = await _authService.signInWithGoogle();

    return authResult.when(
      success: (user) async {
        // Check if user document already exists in Firestore.
        final userDocResult = await _firestoreService.getDocument<UserModel>(
          collection: FirebaseCollections.users,
          id: user.uid,
          fromFirestore: (data, id) => UserModel.fromJson({...data, 'id': id}),
        );

        return userDocResult.when(
          success: (userModel) => Result.success(userModel),
          failure: (exception) async {
            // User document doesn't exist — create one from Google profile.
            final now = DateTime.now();
            final newUser = UserModel(
              id: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? '',
              role: UserRole.customer,
              photoUrl: user.photoURL,
              createdAt: now,
              updatedAt: now,
            );

            final createResult = await _firestoreService.addDocument(
              collection: FirebaseCollections.users,
              id: user.uid,
              data: newUser.toJson(),
            );

            return createResult.when(
              success: (_) => Result.success(newUser),
              failure: (e) => Result<UserModel>.failure(e),
            );
          },
        );
      },
      failure: (exception) => Result.failure(exception),
    );
  }

  /// Returns the current user's [UserModel] from Firestore, or null if not signed in.
  Future<Result<UserModel?>> getCurrentUser() async {
    final authResult = await _authService.getCurrentUser();

    return authResult.when(
      success: (user) async {
        if (user == null) {
          return Result<UserModel?>.success(null);
        }

        final userDocResult = await _firestoreService.getDocument<UserModel>(
          collection: FirebaseCollections.users,
          id: user.uid,
          fromFirestore: (data, id) => UserModel.fromJson({...data, 'id': id}),
        );

        return userDocResult.when(
          success: (userModel) => Result<UserModel?>.success(userModel),
          failure: (exception) => Result<UserModel?>.failure(exception),
        );
      },
      failure: (exception) => Result.failure(exception),
    );
  }

  /// Stream of authentication state changes mapped to [UserModel].
  ///
  /// Emits the current [UserModel] when signed in, or null when signed out.
  /// Fetches the full user profile from Firestore on each auth state change.
  Stream<UserModel?> authStateChanges() {
    return _authService.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;

      final result = await _firestoreService.getDocument<UserModel>(
        collection: FirebaseCollections.users,
        id: user.uid,
        fromFirestore: (data, id) => UserModel.fromJson({...data, 'id': id}),
      );

      return result.dataOrNull;
    });
  }

  /// Sends a password reset email to the specified [email].
  Future<Result<void>> resetPassword(String email) async {
    return _authService.resetPassword(email);
  }

  /// Updates the current user's profile information.
  ///
  /// Updates both Firebase Auth profile and the Firestore user document.
  Future<Result<void>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final authResult = await _authService.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );

    return authResult.when(
      success: (user) async {
        // Update the Firestore user document as well.
        final updateData = <String, dynamic>{};
        if (displayName != null) updateData['displayName'] = displayName;
        if (photoUrl != null) updateData['photoUrl'] = photoUrl;

        if (updateData.isEmpty) return Result<void>.success(null);

        return _firestoreService.updateDocument(
          collection: FirebaseCollections.users,
          id: user.uid,
          data: updateData,
        );
      },
      failure: (exception) => Result.failure(exception),
    );
  }
}
