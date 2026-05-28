/// Connectivity middleware for the ALPACA application.
///
/// Monitors network connectivity and provides offline mode support,
/// reconnection handling, and auto-sync triggers.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'package:alpaca_mobile/core/network/connectivity_service.dart';

/// Callback type for sync operations triggered on reconnection.
typedef SyncCallback = Future<void> Function();

/// Middleware that manages connectivity state and offline mode behavior.
///
/// Provides:
/// - Online/offline detection using connectivity_plus
/// - Reconnection handling with configurable callbacks
/// - Offline mode support flag
/// - Stream of connectivity status changes
/// - Auto-sync trigger when connectivity is restored
///
/// Usage:
/// ```dart
/// final middleware = ConnectivityMiddleware(
///   connectivityService: connectivityService,
/// );
/// await middleware.initialize();
///
/// // Register sync callbacks
/// middleware.registerSyncCallback('orders', () async {
///   await orderRepository.syncPendingOrders();
/// });
///
/// // Listen to connectivity changes
/// middleware.statusStream.listen((status) {
///   if (status == ConnectivityStatus.connected) {
///     showSnackBar('Back online!');
///   }
/// });
/// ```
class ConnectivityMiddleware extends ChangeNotifier {
  /// Creates a [ConnectivityMiddleware] with the required [ConnectivityService].
  ConnectivityMiddleware({
    required ConnectivityService connectivityService,
    Logger? logger,
    this.offlineModeEnabled = true,
    this.autoSyncOnReconnect = true,
    this.reconnectDebounceDelay = const Duration(seconds: 2),
  })  : _connectivityService = connectivityService,
        _logger = logger ?? Logger();

  final ConnectivityService _connectivityService;
  final Logger _logger;

  /// Whether offline mode is enabled.
  ///
  /// When enabled, the app will attempt to serve cached data
  /// when the device is offline.
  bool offlineModeEnabled;

  /// Whether to automatically trigger sync when connectivity is restored.
  bool autoSyncOnReconnect;

  /// Debounce delay before triggering sync after reconnection.
  ///
  /// Prevents rapid sync triggers during unstable connections.
  final Duration reconnectDebounceDelay;

  /// Subscription to the connectivity service stream.
  StreamSubscription<ConnectivityStatus>? _subscription;

  /// Registered sync callbacks to execute on reconnection.
  final Map<String, SyncCallback> _syncCallbacks = {};

  /// Whether a sync operation is currently in progress.
  bool _isSyncing = false;

  /// Timer for debouncing reconnection events.
  Timer? _reconnectDebounceTimer;

  /// Whether the middleware has been initialized.
  bool _isInitialized = false;

  /// The current connectivity status.
  ConnectivityStatus get currentStatus => _connectivityService.currentStatus;

  /// Whether the device is currently connected.
  bool get isConnected => _connectivityService.isConnected;

  /// Whether the device is currently disconnected.
  bool get isDisconnected => _connectivityService.isDisconnected;

  /// Whether a sync operation is in progress.
  bool get isSyncing => _isSyncing;

  /// Stream of connectivity status changes.
  Stream<ConnectivityStatus> get statusStream =>
      _connectivityService.statusStream;

  /// Whether the middleware has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether the app should operate in offline mode.
  ///
  /// Returns `true` if offline mode is enabled and the device is disconnected.
  bool get shouldUseOfflineMode => offlineModeEnabled && isDisconnected;

  /// Initializes the middleware and starts listening for connectivity changes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _connectivityService.initialize();

    _subscription = _connectivityService.statusStream.listen(
      _onConnectivityChanged,
      onError: (Object error) {
        _logger.e('Connectivity middleware stream error', error: error);
      },
    );

    _isInitialized = true;
    _logger.d(
      'ConnectivityMiddleware initialized '
      '(status: $currentStatus, offlineMode: $offlineModeEnabled)',
    );
  }

  /// Registers a sync callback to be executed when connectivity is restored.
  ///
  /// [key] - Unique identifier for the callback (used for unregistering).
  /// [callback] - Async function to execute on reconnection.
  void registerSyncCallback(String key, SyncCallback callback) {
    _syncCallbacks[key] = callback;
    _logger.d('Sync callback registered: $key');
  }

  /// Unregisters a previously registered sync callback.
  void unregisterSyncCallback(String key) {
    _syncCallbacks.remove(key);
    _logger.d('Sync callback unregistered: $key');
  }

  /// Manually triggers all registered sync callbacks.
  ///
  /// Returns `true` if all sync operations completed successfully.
  Future<bool> triggerSync() async {
    if (_isSyncing) {
      _logger.w('Sync already in progress, skipping');
      return false;
    }

    if (!isConnected) {
      _logger.w('Cannot sync while offline');
      return false;
    }

    if (_syncCallbacks.isEmpty) {
      _logger.d('No sync callbacks registered');
      return true;
    }

    _isSyncing = true;
    notifyListeners();

    var allSucceeded = true;

    try {
      _logger.i('Starting sync (${_syncCallbacks.length} callbacks)');

      for (final entry in _syncCallbacks.entries) {
        try {
          await entry.value();
          _logger.d('Sync completed: ${entry.key}');
        } catch (e, st) {
          _logger.e('Sync failed: ${entry.key}', error: e, stackTrace: st);
          allSucceeded = false;
        }
      }

      _logger.i('Sync finished (success: $allSucceeded)');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    return allSucceeded;
  }

  /// Manually checks the current connectivity status.
  Future<ConnectivityStatus> checkConnectivity() async {
    return _connectivityService.checkConnectivity();
  }

  /// Handles connectivity status changes.
  void _onConnectivityChanged(ConnectivityStatus status) {
    _logger.i('Connectivity changed: $status');
    notifyListeners();

    if (status == ConnectivityStatus.connected && autoSyncOnReconnect) {
      _handleReconnection();
    }
  }

  /// Handles reconnection with debouncing.
  ///
  /// Waits for [reconnectDebounceDelay] before triggering sync
  /// to avoid rapid triggers during unstable connections.
  void _handleReconnection() {
    _reconnectDebounceTimer?.cancel();
    _reconnectDebounceTimer = Timer(reconnectDebounceDelay, () async {
      // Verify still connected after debounce
      if (isConnected) {
        _logger.i('Reconnection confirmed, triggering auto-sync');
        await triggerSync();
      }
    });
  }

  /// Disposes of the middleware and releases resources.
  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _reconnectDebounceTimer?.cancel();
    _reconnectDebounceTimer = null;
    _syncCallbacks.clear();
    _isInitialized = false;
    super.dispose();
    _logger.d('ConnectivityMiddleware disposed');
  }
}
