import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/models/user_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';

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
  }) {
    final bool isAuthenticated = authViewModel.isAuthenticated;
    final UserRole? userRole = authViewModel.userRole;
    final bool isAuthRoute = _isAuthRoute(location);
    final bool isOwnerRoute = _isOwnerRoute(location);
    final bool isSplash = location == RouteNames.splash;

    // --- Splash screen logic ---
    // If on splash and auth check is still in progress, stay on splash.
    if (isSplash) {
      // Still loading — stay on splash.
      if (authViewModel.isLoading) {
        return null;
      }
      // Auth resolved — redirect based on state.
      if (isAuthenticated) {
        return _getHomeRoute(userRole);
      } else {
        return RouteNames.login;
      }
    }

    // --- Auth routes (login/register) ---
    // If already authenticated, redirect away from login/register.
    if (isAuthenticated && isAuthRoute) {
      return _getHomeRoute(userRole);
    }

    // --- Protected routes ---
    // If not authenticated and trying to access a protected route.
    if (!isAuthenticated && !_isPublicRoute(location)) {
      return RouteNames.login;
    }

    // --- Owner-only routes ---
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
  static String _getHomeRoute(UserRole? role) {
    switch (role) {
      case UserRole.ownerUmkm:
        return RouteNames.ownerDashboard;
      case UserRole.customer:
        return RouteNames.showcase;
      default:
        return RouteNames.showcase;
    }
  }

  /// Returns the home route for a given role. Public API for external use.
  static String getHomeRouteForRole(UserRole? role) => _getHomeRoute(role);
}
