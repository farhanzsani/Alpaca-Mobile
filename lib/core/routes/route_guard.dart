import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/models/user_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';

/// Route guard helper for authentication and role-based access control.
///
/// Provides redirect logic based on the user's authentication state
/// and their assigned role within the ALPACA app.
class RouteGuard {
  RouteGuard._();

  /// Determines the redirect path based on auth state and target location.
  ///
  /// Returns `null` if navigation should proceed, or a redirect path string
  /// if the user should be redirected elsewhere.
  static String? redirect({
    required String location,
    required AuthViewModel authViewModel,
    LocationViewModel? locationViewModel,
  }) {
    final bool isAuthenticated = authViewModel.isAuthenticated;
    final UserRole? userRole = authViewModel.userRole;
    final bool isAuthRoute = _isAuthRoute(location);
    final bool isOwnerRoute = _isOwnerRoute(location);
    final bool isOnboarding = location == RouteNames.businessOnboarding;
    final bool isSplash = location == RouteNames.splash;

    // --- Splash screen logic ---
    // If on splash and auth check is still in progress, stay on splash.
    if (isSplash) {
      // Still loading auth — stay on splash.
      if (authViewModel.isLoading) {
        print('[RouteGuard] Splash: Auth still loading');
        return null;
      }
      // If authenticated as owner and location still loading, stay on splash
      if (isAuthenticated && 
          userRole == UserRole.ownerUmkm && 
          locationViewModel != null &&
          locationViewModel.isLoading) {
        print('[RouteGuard] Splash: Location still loading');
        return null;
      }
      // Auth resolved — redirect based on state.
      if (isAuthenticated) {
        print('[RouteGuard] Splash: Authenticated, businessLocation = ${locationViewModel?.businessLocation}');
        final redirect = _getHomeRoute(userRole, locationViewModel);
        print('[RouteGuard] Splash: Redirecting to $redirect');
        return redirect;
      } else {
        return RouteNames.login;
      }
    }

    // --- Auth routes (login/register) ---
    // If already authenticated, redirect away from login/register.
    if (isAuthenticated && isAuthRoute) {
      // For owner, always go to onboarding first (they can skip if already set up)
      if (userRole == UserRole.ownerUmkm) {
        return RouteNames.businessOnboarding;
      }
      return _getHomeRoute(userRole, locationViewModel);
    }

    // --- Onboarding logic ---
    // Allow access to onboarding if authenticated as owner
    if (isOnboarding && isAuthenticated && userRole == UserRole.ownerUmkm) {
      return null;
    }

    // --- Protected routes ---
    // If not authenticated and trying to access a protected route.
    if (!isAuthenticated && !_isPublicRoute(location)) {
      return RouteNames.login;
    }

    // --- Owner-only routes ---
    // If authenticated as owner and trying to access owner routes,
    // check if business setup is complete
    if (isAuthenticated && isOwnerRoute && userRole == UserRole.ownerUmkm) {
      // If locationViewModel is available, check if business exists
      if (locationViewModel != null && 
          !locationViewModel.isLoading &&
          locationViewModel.businessLocation == null &&
          !isOnboarding) {
        return RouteNames.businessOnboarding;
      }
      return null;
    }

    // If authenticated but not an owner trying to access owner routes.
    if (isAuthenticated && isOwnerRoute && userRole != UserRole.ownerUmkm) {
      return RouteNames.showcase;
    }

    // Allow navigation to proceed.
    return null;
  }

  /// Checks if the given [location] is a public route that doesn't need auth.
  static bool _isPublicRoute(String location) {
    // Check exact matches first
    if (RouteNames.publicRoutes.contains(location)) return true;

    // Check product detail route pattern
    if (location.startsWith('/showcase/product/')) return true;

    return false;
  }

  /// Checks if the given [location] is an owner-only route.
  static bool _isOwnerRoute(String location) {
    return location.startsWith('/owner/');
  }

  /// Checks if the given [location] is an auth-related route (login/register).
  static bool _isAuthRoute(String location) {
    return location == RouteNames.login || location == RouteNames.register;
  }

  /// Returns the appropriate home route based on the user's [role].
  static String _getHomeRoute(UserRole? role, LocationViewModel? locationViewModel) {
    print('[RouteGuard] _getHomeRoute: role=$role, locationVM=${locationViewModel != null}, isLoading=${locationViewModel?.isLoading}, businessLocation=${locationViewModel?.businessLocation}');
    switch (role) {
      case UserRole.ownerUmkm:
        // Check if owner has business location set up
        if (locationViewModel != null && 
            !locationViewModel.isLoading &&
            locationViewModel.businessLocation == null) {
          print('[RouteGuard] _getHomeRoute: No business location, redirect to onboarding');
          return RouteNames.businessOnboarding;
        }
        print('[RouteGuard] _getHomeRoute: Has business location, redirect to dashboard');
        return RouteNames.ownerDashboard;
      case UserRole.customer:
        return RouteNames.showcase;
      default:
        return RouteNames.showcase;
    }
  }

  /// Returns the home route for a given role. Public API for external use.
  static String getHomeRouteForRole(UserRole? role) {
    switch (role) {
      case UserRole.ownerUmkm:
        return RouteNames.ownerDashboard;
      case UserRole.customer:
        return RouteNames.showcase;
      default:
        return RouteNames.showcase;
    }
  }
}
