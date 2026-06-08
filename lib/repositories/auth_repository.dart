import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alpaca_mobile/core/constants/firebase_constants.dart';
import 'package:alpaca_mobile/core/exceptions/app_exception.dart';
import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/firebase/auth_service.dart';
import 'package:alpaca_mobile/firebase/firestore_service.dart';
import 'package:alpaca_mobile/models/user_model.dart';

class AuthRepository {
  AuthRepository({
    required AuthService authService,
    required FirestoreService firestoreService,
    required ApiClient apiClient,
  })  : _authService = authService,
        _firestoreService = firestoreService,
        _api = apiClient;

  final AuthService _authService;
  final FirestoreService _firestoreService;
  final ApiClient _api;

  /// Sync user: simpan ke Firestore (primary) + backend (secondary)
  Future<UserModel> _syncUser(User firebaseUser, {String? role}) async {
    final uid = firebaseUser.uid;
    
    // 1. Cek Firestore dulu
    final firestoreResult = await _firestoreService.getDocument<UserModel>(
      collection: FirebaseCollections.users,
      id: uid,
      fromFirestore: (data, id) => UserModel.fromJson({...data, 'id': id}),
    );

    if (firestoreResult.isSuccess) {
      final user = firestoreResult.dataOrNull!;
      print('[Auth] User found in Firestore: ${user.email}, role=${user.role.toJson()}');
      return user;
    }

    // 2. User belum ada - buat baru
    final now = DateTime.now();
    final newUser = UserModel(
      id: uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      role: UserRole.fromJson(role ?? 'customer'),
      photoUrl: firebaseUser.photoURL,
      createdAt: now,
      updatedAt: now,
    );

    // 3. Simpan ke Firestore (primary)
    await _firestoreService.addDocument(
      collection: FirebaseCollections.users,
      id: uid,
      data: newUser.toFirestoreJson(),
    );

    // 4. Simpan ke backend (secondary, fire-and-forget)
    _api.post('/users/create', {...newUser.toJson(), 'id': uid}, (_) => {}).catchError((e) {
      print('[Auth] Backend sync failed (non-critical): $e');
    });

    print('[Auth] User created: ${newUser.email}, role=${newUser.role.toJson()}');
    return newUser;
  }

  Future<Result<UserModel>> login(String email, String password) async {
    final authResult = await _authService.signInWithEmail(email, password);
    return authResult.when(
      success: (user) async {
        try {
          return Result.success(await _syncUser(user));
        } catch (e) {
          return Result.failure(AuthException(message: 'Login berhasil tapi gagal sync: $e'));
        }
      },
      failure: (e) => Result.failure(e),
    );
  }

  Future<Result<UserModel>> register(
      String email, String password, String displayName, String role) async {
    final authResult = await _authService.registerWithEmail(email, password, displayName, role);
    return authResult.when(
      success: (user) async {
        try {
          return Result.success(await _syncUser(user, role: role));
        } catch (e) {
          return Result.failure(AuthException(message: 'Register berhasil tapi gagal sync: $e'));
        }
      },
      failure: (e) => Result.failure(e),
    );
  }

  Future<Result<UserModel>> signInWithGoogle() async {
    final authResult = await _authService.signInWithGoogle();
    return authResult.when(
      success: (user) async {
        try {
          return Result.success(await _syncUser(user));
        } catch (e) {
          return Result.failure(AuthException(message: 'Google login berhasil tapi gagal sync: $e'));
        }
      },
      failure: (e) => Result.failure(e),
    );
  }

  Future<Result<UserModel?>> getCurrentUser() async {
    final authResult = await _authService.getCurrentUser();
    return authResult.when(
      success: (user) async {
        if (user == null) return Result.success(null);
        final result = await _firestoreService.getDocument<UserModel>(
          collection: FirebaseCollections.users,
          id: user.uid,
          fromFirestore: (data, id) => UserModel.fromJson({...data, 'id': id}),
        );
        return result.when(
          success: (u) => Result<UserModel?>.success(u),
          failure: (e) => Result<UserModel?>.failure(e),
        );
      },
      failure: (e) => Result.failure(e),
    );
  }

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

  Future<Result<void>> logout() => _authService.signOut();
  Future<Result<void>> resetPassword(String email) => _authService.resetPassword(email);

  Future<Result<void>> updateProfile({String? displayName, String? photoUrl}) async {
    final authResult = await _authService.updateProfile(displayName: displayName, photoUrl: photoUrl);
    return authResult.when(
      success: (user) async {
        final data = <String, dynamic>{};
        if (displayName != null) data['displayName'] = displayName;
        if (photoUrl != null) data['photoUrl'] = photoUrl;
        if (data.isEmpty) return Result<void>.success(null);
        return _firestoreService.updateDocument(
          collection: FirebaseCollections.users,
          id: user.uid,
          data: data,
        );
      },
      failure: (e) => Result.failure(e),
    );
  }
}

