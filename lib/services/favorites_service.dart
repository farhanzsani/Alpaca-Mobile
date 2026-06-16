import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user's favorite stores using local storage.
class FavoritesService {
  static const String _favoritesKey = 'favorite_stores';

  /// Get list of favorite store IDs.
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  /// Add a store to favorites.
  Future<void> addFavorite(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    if (!favorites.contains(storeId)) {
      favorites.add(storeId);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  /// Remove a store from favorites.
  Future<void> removeFavorite(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    favorites.remove(storeId);
    await prefs.setStringList(_favoritesKey, favorites);
  }

  /// Toggle favorite status of a store.
  Future<bool> toggleFavorite(String storeId) async {
    final favorites = await getFavorites();
    
    if (favorites.contains(storeId)) {
      await removeFavorite(storeId);
      return false;
    } else {
      await addFavorite(storeId);
      return true;
    }
  }

  /// Check if a store is favorited.
  Future<bool> isFavorite(String storeId) async {
    final favorites = await getFavorites();
    return favorites.contains(storeId);
  }

  /// Clear all favorites.
  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
}
