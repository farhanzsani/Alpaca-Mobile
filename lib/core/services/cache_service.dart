/// Local cache service for the ALPACA application.
///
/// Provides caching with TTL (time-to-live) support using
/// SharedPreferences for persistent local storage.
library;

import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metadata for a cached entry, including expiry information.
class _CacheEntry {
  _CacheEntry({
    required this.data,
    required this.createdAt,
    required this.expiresAt,
  });

  factory _CacheEntry.fromJson(Map<String, dynamic> json) {
    return _CacheEntry(
      data: json['data'],
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final dynamic data;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

/// Service for managing local cached data with TTL support.
///
/// Stores data in SharedPreferences with automatic expiry handling.
/// All cache keys are prefixed to avoid conflicts with other stored data.
///
/// Usage:
/// ```dart
/// final cacheService = CacheService(prefs: sharedPreferences);
///
/// // Save data with 5-minute TTL
/// await cacheService.save(
///   key: 'products_list',
///   data: productsJson,
///   ttl: Duration(minutes: 5),
/// );
///
/// // Load cached data
/// final cached = await cacheService.load<List<dynamic>>('products_list');
/// ```
class CacheService {
  /// Creates a [CacheService] with the given [SharedPreferences] instance.
  CacheService({
    required SharedPreferences prefs,
    Logger? logger,
  })  : _prefs = prefs,
        _logger = logger ?? Logger();

  final SharedPreferences _prefs;
  final Logger _logger;

  /// Prefix for all cache keys to avoid collisions.
  static const String _cachePrefix = 'alpaca_cache_';

  /// Default TTL for cached data (10 minutes).
  static const Duration defaultTtl = Duration(minutes: 10);

  /// Saves data to the cache with a specified TTL.
  ///
  /// [key] - Unique identifier for the cached data.
  /// [data] - The data to cache. Must be JSON-serializable.
  /// [ttl] - Time-to-live for the cache entry. Defaults to 10 minutes.
  ///
  /// Returns `true` if the data was saved successfully.
  Future<bool> save({
    required String key,
    required dynamic data,
    Duration ttl = defaultTtl,
  }) async {
    try {
      final now = DateTime.now();
      final entry = _CacheEntry(
        data: data,
        createdAt: now,
        expiresAt: now.add(ttl),
      );

      final jsonString = jsonEncode(entry.toJson());
      final success = await _prefs.setString(_prefixedKey(key), jsonString);

      if (success) {
        _logger.d('Cache saved: $key (TTL: ${ttl.inSeconds}s)');
      }

      return success;
    } catch (e, st) {
      _logger.e('Failed to save cache for key: $key', error: e, stackTrace: st);
      return false;
    }
  }

  /// Loads cached data for the given [key].
  ///
  /// Returns the cached data cast to type [T], or null if:
  /// - No cache exists for the key
  /// - The cache has expired
  /// - The data cannot be cast to [T]
  ///
  /// Expired entries are automatically removed.
  T? load<T>(String key) {
    try {
      final jsonString = _prefs.getString(_prefixedKey(key));
      if (jsonString == null) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final entry = _CacheEntry.fromJson(json);

      if (entry.isExpired) {
        _logger.d('Cache expired: $key');
        // Fire and forget cleanup
        remove(key);
        return null;
      }

      return entry.data as T?;
    } catch (e, st) {
      _logger.e('Failed to load cache for key: $key', error: e, stackTrace: st);
      return null;
    }
  }

  /// Checks if a valid (non-expired) cache entry exists for the given [key].
  bool isValid(String key) {
    try {
      final jsonString = _prefs.getString(_prefixedKey(key));
      if (jsonString == null) return false;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final entry = _CacheEntry.fromJson(json);

      return !entry.isExpired;
    } catch (e) {
      _logger.e('Failed to check cache validity for key: $key', error: e);
      return false;
    }
  }

  /// Checks if a cache entry exists for the given [key], regardless of expiry.
  bool exists(String key) {
    return _prefs.containsKey(_prefixedKey(key));
  }

  /// Checks if the cache entry for [key] has expired.
  ///
  /// Returns `true` if the entry exists and is expired.
  /// Returns `false` if the entry doesn't exist or is still valid.
  bool isExpired(String key) {
    try {
      final jsonString = _prefs.getString(_prefixedKey(key));
      if (jsonString == null) return false;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final entry = _CacheEntry.fromJson(json);

      return entry.isExpired;
    } catch (e) {
      _logger.e('Failed to check cache expiry for key: $key', error: e);
      return false;
    }
  }

  /// Removes a specific cache entry by [key].
  ///
  /// Returns `true` if the entry was removed successfully.
  Future<bool> remove(String key) async {
    try {
      final success = await _prefs.remove(_prefixedKey(key));
      if (success) {
        _logger.d('Cache removed: $key');
      }
      return success;
    } catch (e, st) {
      _logger.e('Failed to remove cache for key: $key', error: e, stackTrace: st);
      return false;
    }
  }

  /// Clears all cache entries managed by this service.
  ///
  /// Only removes keys with the cache prefix, leaving other
  /// SharedPreferences data intact.
  Future<void> clearAll() async {
    try {
      final keys = _prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      for (final key in keys) {
        await _prefs.remove(key);
      }
      _logger.d('All cache cleared (${keys.length} entries)');
    } catch (e, st) {
      _logger.e('Failed to clear all cache', error: e, stackTrace: st);
    }
  }

  /// Removes all expired cache entries.
  ///
  /// Useful for periodic cleanup to free storage space.
  Future<int> removeExpired() async {
    var removedCount = 0;
    try {
      final keys = _prefs.getKeys().where((key) => key.startsWith(_cachePrefix));

      for (final prefixedKey in keys) {
        final jsonString = _prefs.getString(prefixedKey);
        if (jsonString == null) continue;

        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final entry = _CacheEntry.fromJson(json);

          if (entry.isExpired) {
            await _prefs.remove(prefixedKey);
            removedCount++;
          }
        } catch (_) {
          // Corrupted entry, remove it
          await _prefs.remove(prefixedKey);
          removedCount++;
        }
      }

      _logger.d('Removed $removedCount expired cache entries');
    } catch (e, st) {
      _logger.e('Failed to remove expired cache', error: e, stackTrace: st);
    }
    return removedCount;
  }

  /// Returns the prefixed key for storage.
  String _prefixedKey(String key) => '$_cachePrefix$key';
}
