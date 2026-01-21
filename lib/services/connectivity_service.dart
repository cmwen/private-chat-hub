import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:private_chat_hub/services/ai_connection_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/services/provider_client_factory.dart';

/// Status of the provider connection.

enum OllamaConnectivityStatus {
  connected, // Online and Ollama server is reachable
  disconnected, // Network available but Ollama server unreachable
  offline, // No network connectivity
  checking, // Testing connection
}

/// Service for monitoring network connectivity and provider reachability.
///
/// This service combines network connectivity monitoring with provider
/// server health checks to provide accurate connection status.

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final OllamaConnectionManager _ollamaManager;
  final AiConnectionService _connectionService;
  final ProviderClientFactory _clientFactory;

  // Stream controllers
  final _statusController =
      StreamController<OllamaConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // State tracking
  OllamaConnectivityStatus _currentStatus = OllamaConnectivityStatus.checking;
  Timer? _debounceTimer;
  Timer? _periodicCheckTimer;
  bool _isDisposed = false;

  // Configuration
  static const Duration _debounceDelay = Duration(seconds: 3);
  static const Duration _periodicCheckInterval = Duration(seconds: 30);

  ConnectivityService(
    this._ollamaManager,
    this._connectionService,
    this._clientFactory,
  ) {
    _initialize();
  }

  /// Gets the current connectivity status.
  OllamaConnectivityStatus get currentStatus => _currentStatus;

  /// Stream of connectivity status changes.
  Stream<OllamaConnectivityStatus> get statusStream => _statusController.stream;

  /// Whether the service is currently online (connected to Ollama).
  bool get isOnline => _currentStatus == OllamaConnectivityStatus.connected;

  /// Whether the service is completely offline (no network).
  bool get isOffline => _currentStatus == OllamaConnectivityStatus.offline;

  void _initialize() {
    // Start listening to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        debugPrint('[ConnectivityService] Connectivity error: $error');
      },
    );

    // Perform initial connectivity check
    _checkConnectivity();

    // Set up periodic connectivity checks (fallback)
    _periodicCheckTimer = Timer.periodic(_periodicCheckInterval, (_) {
      if (!_isDisposed) {
        _checkConnectivity();
      }
    });
  }

  /// Handles connectivity changes from the system.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    debugPrint('[ConnectivityService] Connectivity changed: $results');

    // Debounce rapid changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (!_isDisposed) {
        _checkConnectivity();
      }
    });
  }

  /// Checks current connectivity and updates status.
  Future<void> _checkConnectivity() async {
    if (_isDisposed) return;

    try {
      // Update to checking status
      _updateStatus(OllamaConnectivityStatus.checking);

      // First check network connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasNetwork = connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );

      if (!hasNetwork) {
        _updateStatus(OllamaConnectivityStatus.offline);
        return;
      }

      // Network is available, now check Ollama server
      final ollamaReachable = await _testOllamaConnection();

      if (ollamaReachable) {
        _updateStatus(OllamaConnectivityStatus.connected);
      } else {
        _updateStatus(OllamaConnectivityStatus.disconnected);
      }
    } catch (e) {
      debugPrint('[ConnectivityService] Error checking connectivity: $e');
      _updateStatus(OllamaConnectivityStatus.disconnected);
    }
  }

  /// Tests if the active provider is reachable.
  Future<bool> _testOllamaConnection() async {
    try {
      final connection = _connectionService.getActiveConnection();
      final client = await _clientFactory.createClient(connection);
      if (client == null) return false;
      return await client.testConnection();
    } catch (e) {
      debugPrint('[ConnectivityService] Connection test failed: $e');
      return false;
    }
  }

  /// Updates the current status and notifies listeners.
  void _updateStatus(OllamaConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      final oldStatus = _currentStatus;
      _currentStatus = newStatus;

      debugPrint(
        '[ConnectivityService] Status changed: ${oldStatus.name} -> ${newStatus.name}',
      );

      if (!_statusController.isClosed) {
        _statusController.add(newStatus);
      }
    }
  }

  /// Manually triggers a connectivity check.
  ///
  /// Useful for retrying after failed operations or when user requests refresh.
  Future<void> refresh() async {
    debugPrint('[ConnectivityService] Manual refresh requested');
    await _checkConnectivity();
  }

  /// Disposes of resources.
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _periodicCheckTimer?.cancel();
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}

/// Helper for debug printing.
void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
