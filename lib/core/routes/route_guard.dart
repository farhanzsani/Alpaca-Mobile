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
    final bool isSplash = location == RouteNames.splash;

    // Handle splash screen only
    if (isSplash && !authViewModel.isLoading) {
      if (isAuthenticated) {
        return userRole == UserRole.ownerUmkm ? RouteNames.ownerDashboard : RouteNames.showcase;
      } else {
        return RouteNames.login;
      }
    }

    // If authenticated and on auth routes, go home
    if (isAuthenticated && isAuthRoute) {
      return userRole == UserRole.ownerUmkm ? RouteNames.ownerDashboard : RouteNames.showcase;
    }

    // If not authenticated and on protected routes, go to login
    if (!isAuthenticated && !_isPublicRoute(location) && !isSplash) {
      return RouteNames.login;
    }

    // Allow all other navigation
    return null;
  }

  /// Checks if the given [location] is a public route that doesn't need auth.
  static bool _isPublicRoute(String location) {
    // Check exact matches first
    if (RouteNames.publicRoutes.contains(location)) return true;

    // Check product detail route pattern
    if (location.startsWith('/showcase/product/')) return true;
    
    // Check store profile route pattern  
    if (location.startsWith('/showcase/store/')) return true;

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
