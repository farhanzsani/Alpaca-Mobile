/// Low-level connectivity service for the ALPACA application.
///
/// Provides real-time connectivity status monitoring using
/// the connectivity_plus package.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Represents the current network connectivity status.
enum ConnectivityStatus {
  /// Device is connected to the internet.
  connected,

  /// Device has no internet connection.
  disconnected,
}

/// Low-level service for monitoring network connectivity.
///
/// Wraps the connectivity_plus package to provide a simplified
/// interface for checking and streaming connectivity status.
///
/// Usage:
/// ```dart
/// final service = ConnectivityService();
/// await service.initialize();
///
/// // Check current status
/// if (service.isConnected) {
///   // Perform network operation
/// }
///
/// // Listen to changes
/// service.statusStream.listen((status) {
///   print('Connectivity: $status');
/// });
///
/// // Dispose when done
/// service.dispose();
/// ```
class ConnectivityService {
  /// Creates a [ConnectivityService] with an optional [Connectivity] instance.
  ConnectivityService({
    Connectivity? connectivity,
    Logger? logger,
  })  : _connectivity = connectivity ?? Connectivity(),
        _logger = logger ?? Logger();

  final Connectivity _connectivity;
  final Logger _logger;

  /// Stream controller for broadcasting connectivity status changes.
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  /// Subscription to the connectivity_plus stream.
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// The current connectivity status.
  ConnectivityStatus _currentStatus = ConnectivityStatus.disconnected;

  /// Whether the service has been initialized.
  bool _isInitialized = false;

  /// Returns the current connectivity status.
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether the device is currently connected to the internet.
  bool get isConnected => _currentStatus == ConnectivityStatus.connected;

  /// Whether the device is currently disconnected.
  bool get isDisconnected => _currentStatus == ConnectivityStatus.disconnected;

  /// Stream of connectivity status changes.
  ///
  /// Emits a new [ConnectivityStatus] whenever the network state changes.
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the connectivity service.
  ///
  /// Checks the current connectivity state and starts listening
  /// for changes. Must be called before using the service.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check initial connectivity
      final results = await _connectivity.checkConnectivity();
      _currentStatus = _mapResults(results);
      _logger.d('Initial connectivity: $_currentStatus');

      // Listen for changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (Object error) {
          _logger.e('Connectivity stream error', error: error);
        },
      );

      _isInitialized = true;
    } catch (e, st) {
      _logger.e('Failed to initialize connectivity service',
          error: e, stackTrace: st);
    }
  }

  /// Manually checks the current connectivity status.
  ///
  /// Updates the internal state and notifies listeners if changed.
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final newStatus = _mapResults(results);

      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _statusController.add(_currentStatus);
      }

      return _currentStatus;
    } catch (e, st) {
      _logger.e('Failed to check connectivity', error: e, stackTrace: st);
      return _currentStatus;
    }
  }

  /// Handles connectivity change events from connectivity_plus.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final newStatus = _mapResults(results);

    if (newStatus != _currentStatus) {
      _logger.i('Connectivity changed: $_currentStatus -> $newStatus');
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
    }
  }

  /// Maps connectivity_plus results to our [ConnectivityStatus].
  ConnectivityStatus _mapResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      return ConnectivityStatus.disconnected;
    }
    return ConnectivityStatus.connected;
  }

  /// Disposes of the service and releases resources.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _statusController.close();
    _isInitialized = false;
    _logger.d('ConnectivityService disposed');
  }
}
