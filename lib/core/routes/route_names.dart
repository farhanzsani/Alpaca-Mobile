/// Route name constants for the ALPACA app.
///
/// Contains all route paths as static constants and helper methods
/// for route classification.
class RouteNames {
  RouteNames._();

  // Auth routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String businessOnboarding = '/onboarding/business';

  // Owner routes
  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerInventory = '/owner/inventory';
  static const String ownerBookkeeping = '/owner/bookkeeping';
  static const String ownerMedia = '/owner/media';
  static const String ownerLocation = '/owner/location';
  static const String ownerProducts = '/owner/products';
  static const String ownerWaste = '/owner/waste';
  static const String ownerProfile = '/owner/profile';

  // Public showcase routes
  static const String showcase = '/showcase';
  static const String showcaseProductDetail = '/showcase/product/:id';
  static const String showcaseNearby = '/showcase/nearby';
  static const String showcaseStoreProfile = '/showcase/store/:ownerId';
  
  // Shared
  static const String profileEdit = '/profile/edit';
  static const String customerProfile = '/customer/profile';

  /// Routes that do not require authentication.
  static const List<String> publicRoutes = [
    splash,
    login,
    register,
    businessOnboarding,
    showcase,
    '/showcase/product',
    showcaseNearby,
    showcaseStoreProfile,
  ];

  /// Routes that are restricted to owner_umkm role only.
  static const List<String> ownerOnlyRoutes = [
    ownerDashboard,
    ownerInventory,
    ownerBookkeeping,
    ownerMedia,
    ownerLocation,
    ownerProducts,
    ownerWaste,
    ownerProfile,
  ];

  /// Checks whether the given [route] requires authentication.
  static bool isProtected(String route) {
    // Routes with path parameters need prefix checks
    if (route.startsWith('/showcase/product/')) return false;
    if (route.startsWith('/showcase/store/')) return false;
    return !publicRoutes.contains(route);
  }

  /// Checks whether the given [route] is restricted to owners.
  static bool isOwnerOnly(String route) {
    if (route == profileEdit) return false; // shared
    return ownerOnlyRoutes.contains(route) ||
        route.startsWith('/owner/');
  }

  /// Generates the product detail path for a given [productId].
  static String productDetail(String productId) {
    if (productId.isEmpty) {
      print('[RouteNames] ERROR: productId is empty!');
      return '/showcase'; // Fallback to showcase
    }
    return '/showcase/product/$productId';
  }

  /// Generates the store profile path for a given [ownerId].
  static String storeProfile(String ownerId) =>
      '/showcase/store/$ownerId';
}
