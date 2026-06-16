import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/models/product_model.dart';

class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.createdAt,
    this.product,
    this.business,
  });

  final String id;
  final String itemId;
  final String itemType;
  final DateTime createdAt;
  final ProductModel? product;
  final BusinessLocationModel? business;

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    final itemType = json['item_type'] as String? ?? '';
    final item = json['item'];

    return FavoriteItem(
      id: json['id'] as String? ?? '',
      itemId: json['item_id'] as String? ?? '',
      itemType: itemType,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      product: itemType == 'product' && item is Map
          ? ProductModel.fromJson(Map<String, dynamic>.from(item))
          : null,
      business: itemType == 'business' && item is Map
          ? BusinessLocationModel.fromJson(Map<String, dynamic>.from(item))
          : null,
    );
  }
}

/// Service to manage user's favorite products and businesses.
class FavoritesService {
  FavoritesService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Result<List<FavoriteItem>>> getFavoriteItems({String? itemType}) {
    return _api.get('/favorites', (json) {
      final data = json is Map ? json['data'] : json;
      return (data as List)
          .map(
            (item) =>
                FavoriteItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }, query: {'item_type': itemType});
  }

  Future<Result<void>> addFavoriteItem(String itemId, String itemType) {
    return _api.post('/favorites/create', {
      'item_id': itemId,
      'item_type': itemType,
    }, (_) {});
  }

  Future<Result<void>> removeFavoriteItem(String itemId, String itemType) {
    return _api.delete('/favorites/$itemType/$itemId');
  }

  Future<Result<bool>> toggleFavoriteItem(
    String itemId,
    String itemType,
  ) async {
    final favorite = await isFavoriteItem(itemId, itemType);

    if (favorite) {
      final result = await removeFavoriteItem(itemId, itemType);
      return result.map((_) => false);
    }

    final result = await addFavoriteItem(itemId, itemType);
    return result.map((_) => true);
  }

  Future<bool> isFavoriteItem(String itemId, String itemType) async {
    final result = await getFavoriteItems(itemType: itemType);
    return result
        .getOrElse(const [])
        .any((favorite) => favorite.itemId == itemId);
  }

  Future<List<String>> getFavoriteIds(String itemType) async {
    final result = await getFavoriteItems(itemType: itemType);
    return result
        .getOrElse(const [])
        .map((favorite) => favorite.itemId)
        .toList();
  }

  Future<List<String>> getFavorites() => getFavoriteIds('business');

  Future<void> addFavorite(String storeId) async {
    await addFavoriteItem(storeId, 'business');
  }

  Future<void> removeFavorite(String storeId) async {
    await removeFavoriteItem(storeId, 'business');
  }

  Future<bool> toggleFavorite(String storeId) async {
    final result = await toggleFavoriteItem(storeId, 'business');
    return result.getOrElse(false);
  }

  Future<bool> isFavorite(String storeId) {
    return isFavoriteItem(storeId, 'business');
  }

  Future<void> clearFavorites() async {}
}
