import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/routes/route_guard.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';

// Screen imports
import 'package:alpaca_mobile/views/splash_screen.dart';
import 'package:alpaca_mobile/views/auth/login_screen.dart';
import 'package:alpaca_mobile/views/auth/register_screen.dart';
import 'package:alpaca_mobile/views/auth/business_onboarding_screen.dart';
import 'package:alpaca_mobile/views/owner/owner_main_screen.dart';
import 'package:alpaca_mobile/views/owner/owner_dashboard_screen.dart';
import 'package:alpaca_mobile/views/owner/inventory_screen.dart';
import 'package:alpaca_mobile/views/owner/bookkeeping_screen.dart';
import 'package:alpaca_mobile/views/owner/media_screen.dart';
import 'package:alpaca_mobile/views/owner/location_screen.dart';
import 'package:alpaca_mobile/views/owner/products_screen.dart';
import 'package:alpaca_mobile/views/owner/waste_tracking_screen.dart';
import 'package:alpaca_mobile/views/owner/profile_screen.dart';
import 'package:alpaca_mobile/views/showcase/public_showcase_screen.dart';
import 'package:alpaca_mobile/views/showcase/customer_main_screen.dart';
import 'package:alpaca_mobile/views/showcase/product_detail_screen.dart';
import 'package:alpaca_mobile/views/showcase/business_map_screen.dart';
import 'package:alpaca_mobile/views/showcase/store_profile_screen.dart';

/// Application router configuration using go_router.
///
/// Defines all navigation routes for the ALPACA app with
/// authentication and role-based redirect logic.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Creates and returns the configured [GoRouter] instance.
  ///
  /// Requires [BuildContext] to access the [AuthViewModel] from the
  /// provider tree for redirect logic.
  static GoRouter router(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    final locationViewModel = context.read<LocationViewModel>();

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: RouteNames.splash,
      debugLogDiagnostics: false,
      redirect: (BuildContext context, GoRouterState state) {
        final location = state.matchedLocation;
        return RouteGuard.redirect(
          location: location,
          authViewModel: authViewModel,
          locationViewModel: locationViewModel,
        );
      },
      routes: _routes,
      errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    );
  }

  /// Creates a [GoRouter] instance that listens to auth state changes.
  ///
  /// Use this factory when you need the router to reactively redirect
  /// on authentication state changes.
  static GoRouter createRouter(AuthViewModel authViewModel, LocationViewModel locationViewModel) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: RouteNames.splash,
      debugLogDiagnostics: false,
      refreshListenable: authViewModel,
      redirect: (BuildContext context, GoRouterState state) {
        final location = state.matchedLocation;
        return RouteGuard.redirect(
          location: location,
          authViewModel: authViewModel,
          locationViewModel: locationViewModel,
        );
      },
      routes: _routes,
      errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    );
  }

  /// All application routes.
  static final List<RouteBase> _routes = [
    // Splash
    GoRoute(
      path: RouteNames.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Auth routes
    GoRoute(
      path: RouteNames.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.register,
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: RouteNames.businessOnboarding,
      name: 'businessOnboarding',
      builder: (context, state) => const BusinessOnboardingScreen(),
    ),

    // Owner routes
    GoRoute(
      path: RouteNames.ownerDashboard,
      name: 'ownerDashboard',
      builder: (context, state) => const OwnerMainScreen(initialIndex: 0),
    ),
    GoRoute(
      path: RouteNames.ownerInventory,
      name: 'ownerInventory',
      builder: (context, state) => const InventoryScreen(),
    ),
    GoRoute(
      path: RouteNames.ownerBookkeeping,
      name: 'ownerBookkeeping',
      builder: (context, state) => const OwnerMainScreen(initialIndex: 2),
    ),
    GoRoute(
      path: RouteNames.ownerMedia,
      name: 'ownerMedia',
      builder: (context, state) => const MediaScreen(),
    ),
    GoRoute(
      path: RouteNames.ownerLocation,
      name: 'ownerLocation',
      builder: (context, state) => const LocationScreen(),
    ),
    GoRoute(
      path: RouteNames.ownerProducts,
      name: 'ownerProducts',
      builder: (context, state) => const OwnerMainScreen(initialIndex: 1),
    ),
    GoRoute(
      path: RouteNames.ownerWaste,
      name: 'ownerWaste',
      builder: (context, state) => const OwnerMainScreen(initialIndex: 3),
    ),
    GoRoute(
      path: RouteNames.ownerProfile,
      name: 'ownerProfile',
      builder: (context, state) => const ProfileScreen(),
    ),

    // Public showcase routes
    GoRoute(
      path: RouteNames.showcase,
      name: 'showcase',
      builder: (context, state) => const CustomerMainScreen(initialIndex: 0),
    ),
    GoRoute(
      path: RouteNames.showcaseProductDetail, // /showcase/product/:id
      name: 'productDetail',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return ProductDetailScreen(productId: productId);
      },
    ),
    GoRoute(
      path: '/showcase/products', // Ganti ke plural untuk avoid conflict
      name: 'productsList',
      builder: (context, state) => const CustomerMainScreen(initialIndex: 0),
    ),
    GoRoute(
      path: RouteNames.showcaseMap,
      name: 'businessMap',
      builder: (context, state) => const CustomerMainScreen(initialIndex: 1),
    ),
    GoRoute(
      path: RouteNames.showcaseStoreProfile,
      name: 'storeProfile',
      builder: (context, state) {
        final ownerId = state.pathParameters['ownerId']!;
        return StoreProfileScreen(ownerId: ownerId);
      },
    ),
  ];
}

/// Error screen displayed when a route is not found.
class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'The requested page could not be found.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
