/// Firebase collection names and document paths for the ALPACA application.
///
/// Centralizes all Firestore collection references to avoid
/// hardcoded strings throughout the codebase.
library;

/// Firestore collection name constants.
abstract final class FirebaseCollections {
  /// Users collection - stores user profiles and authentication data.
  static const String users = 'users';

  /// Inventory collection - tracks stock and supplies for SMEs.
  static const String inventory = 'inventory';

  /// Transactions collection - records sales, purchases, and transfers.
  static const String transactions = 'transactions';

  /// Media collection - stores references to uploaded images and documents.
  static const String media = 'media';

  /// Business locations collection - physical locations of businesses.
  static const String businessLocations = 'business_locations';

  /// Products collection - items offered by SMEs.
  static const String products = 'products';

  /// Waste resources collection - tracks agricultural waste for reuse/recycling.
  static const String wasteResources = 'waste_resources';

  /// Categories collection - product and business categories.
  static const String categories = 'categories';

  /// Orders collection - customer orders.
  static const String orders = 'orders';

  /// Reviews collection - customer reviews and ratings.
  static const String reviews = 'reviews';

  /// Notifications collection - user notifications.
  static const String notifications = 'notifications';
}

/// Firestore sub-collection name constants.
abstract final class FirebaseSubCollections {
  /// Transaction items sub-collection under transactions.
  static const String transactionItems = 'items';

  /// Inventory history sub-collection under inventory.
  static const String inventoryHistory = 'history';

  /// Media variants sub-collection under media.
  static const String mediaVariants = 'variants';

  /// Business hours sub-collection under business_locations.
  static const String businessHours = 'hours';

  /// Product variants sub-collection under products.
  static const String productVariants = 'variants';
}

/// Firebase Storage path constants.
abstract final class FirebaseStoragePaths {
  /// Root path for user profile images.
  static const String profileImages = 'profile_images';

  /// Root path for product images.
  static const String productImages = 'product_images';

  /// Root path for inventory images.
  static const String inventoryImages = 'inventory_images';

  /// Root path for business location images.
  static const String businessImages = 'business_images';

  /// Root path for transaction receipts.
  static const String receipts = 'receipts';

  /// Root path for general media uploads.
  static const String uploads = 'uploads';

  /// Generates a user-specific profile image path.
  static String userProfileImage(String userId) =>
      '$profileImages/$userId/avatar';

  /// Generates a product image path.
  static String productImage(String productId, String fileName) =>
      '$productImages/$productId/$fileName';

  /// Generates an inventory image path.
  static String inventoryImage(String inventoryId, String fileName) =>
      '$inventoryImages/$inventoryId/$fileName';

  /// Generates a business location image path.
  static String businessImage(String locationId, String fileName) =>
      '$businessImages/$locationId/$fileName';
}

/// Firestore field name constants for common fields.
abstract final class FirebaseFields {
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
  static const String isActive = 'is_active';
  static const String userId = 'user_id';
  static const String name = 'name';
  static const String description = 'description';
  static const String imageUrl = 'image_url';
  static const String price = 'price';
  static const String quantity = 'quantity';
  static const String status = 'status';
}
