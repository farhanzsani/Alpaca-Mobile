import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase services
import 'package:alpaca_mobile/firebase/auth_service.dart';
import 'package:alpaca_mobile/firebase/firestore_service.dart';
import 'package:alpaca_mobile/firebase/storage_service.dart';

// Core services
import 'package:alpaca_mobile/core/network/connectivity_service.dart';
import 'package:alpaca_mobile/core/services/session_service.dart';
import 'package:alpaca_mobile/core/services/cache_service.dart';

// Middleware
import 'package:alpaca_mobile/core/middleware/connectivity_middleware.dart';
import 'package:alpaca_mobile/core/middleware/auth_middleware.dart';

// Repositories
import 'package:alpaca_mobile/repositories/auth_repository.dart';
import 'package:alpaca_mobile/repositories/product_repository.dart';
import 'package:alpaca_mobile/repositories/inventory_repository.dart';
import 'package:alpaca_mobile/repositories/transaction_repository.dart';
import 'package:alpaca_mobile/repositories/media_repository.dart';
import 'package:alpaca_mobile/repositories/business_repository.dart';
import 'package:alpaca_mobile/repositories/waste_repository.dart';

// ViewModels
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/inventory_view_model.dart';
import 'package:alpaca_mobile/viewmodels/finance_view_model.dart';
import 'package:alpaca_mobile/viewmodels/media_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';
import 'package:alpaca_mobile/viewmodels/product_view_model.dart';
import 'package:alpaca_mobile/viewmodels/waste_view_model.dart';

/// Central provider configuration for the ALPACA app.
///
/// Creates all service, repository, and ViewModel instances with proper
/// dependency injection and returns them as a list of providers for use
/// with [MultiProvider].
///
/// Requires a [SharedPreferences] instance which must be obtained
/// asynchronously before calling this function.
///
/// Usage:
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// MultiProvider(
///   providers: getAppProviders(prefs),
///   child: MyApp(),
/// )
/// ```
List<SingleChildWidget> getAppProviders(SharedPreferences prefs) {
  // --- Services ---
  final authService = AuthService();
  final firestoreService = FirestoreService();
  final storageService = StorageService();
  final connectivityService = ConnectivityService();
  final sessionService = SessionService(prefs: prefs);
  final cacheService = CacheService(prefs: prefs);

  // --- Repositories ---
  final authRepository = AuthRepository(
    authService: authService,
    firestoreService: firestoreService,
  );

  final productRepository = ProductRepository(
    firestoreService: firestoreService,
  );

  final inventoryRepository = InventoryRepository(
    firestoreService: firestoreService,
  );

  final transactionRepository = TransactionRepository(
    firestoreService: firestoreService,
  );

  final mediaRepository = MediaRepository(
    firestoreService: firestoreService,
    storageService: storageService,
  );

  final businessRepository = BusinessRepository(
    firestoreService: firestoreService,
  );

  final wasteRepository = WasteRepository(
    firestoreService: firestoreService,
  );

  // --- Providers ---
  return [
    // Services
    Provider<AuthService>.value(value: authService),
    Provider<FirestoreService>.value(value: firestoreService),
    Provider<StorageService>.value(value: storageService),
    ChangeNotifierProvider<SessionService>.value(value: sessionService),
    Provider<CacheService>.value(value: cacheService),
    Provider<ConnectivityService>.value(value: connectivityService),

    // Middleware
    ChangeNotifierProvider<ConnectivityMiddleware>(
      create: (_) => ConnectivityMiddleware(
        connectivityService: connectivityService,
      ),
    ),
    ChangeNotifierProvider<AuthMiddleware>(
      create: (_) => AuthMiddleware(
        sessionService: sessionService,
      ),
    ),

    // Repositories
    Provider<AuthRepository>.value(value: authRepository),
    Provider<ProductRepository>.value(value: productRepository),
    Provider<InventoryRepository>.value(value: inventoryRepository),
    Provider<TransactionRepository>.value(value: transactionRepository),
    Provider<MediaRepository>.value(value: mediaRepository),
    Provider<BusinessRepository>.value(value: businessRepository),
    Provider<WasteRepository>.value(value: wasteRepository),

    // ViewModels
    ChangeNotifierProvider<AuthViewModel>(
      create: (_) => AuthViewModel(
        authRepository: authRepository,
      ),
    ),
    ChangeNotifierProvider<InventoryViewModel>(
      create: (_) => InventoryViewModel(
        inventoryRepository: inventoryRepository,
      ),
    ),
    ChangeNotifierProvider<FinanceViewModel>(
      create: (_) => FinanceViewModel(
        transactionRepository: transactionRepository,
      ),
    ),
    ChangeNotifierProvider<MediaViewModel>(
      create: (_) => MediaViewModel(
        mediaRepository: mediaRepository,
      ),
    ),
    ChangeNotifierProvider<LocationViewModel>(
      create: (_) => LocationViewModel(
        businessRepository: businessRepository,
      ),
    ),
    ChangeNotifierProvider<ProductViewModel>(
      create: (_) => ProductViewModel(
        productRepository: productRepository,
      ),
    ),
    ChangeNotifierProvider<WasteViewModel>(
      create: (_) => WasteViewModel(
        wasteRepository: wasteRepository,
      ),
    ),
  ];
}
