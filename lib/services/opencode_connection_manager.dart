import 'dart:async';
import 'package:private_chat_hub/models/opencode_connection.dart';
import 'package:private_chat_hub/services/opencode_api_client.dart';

/// Manages the OpenCode server connection lifecycle.
///
/// Mirrors the pattern of [OllamaConnectionManager] for consistency.
class OpenCodeConnectionManager {
  final OpenCodeApiClient _client;

  OpenCodeConnection? _connection;
  bool _isConnected = false;

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  OpenCodeConnectionManager({OpenCodeApiClient? client})
    : _client = client ?? OpenCodeApiClient();

  /// Stream of connection status changes.
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Whether the server is currently connected.
  bool get isConnected => _isConnected;

  /// The current connection, if any.
  OpenCodeConnection? get connection => _connection;

  /// The API client.
  OpenCodeApiClient get client => _client;

  /// Set the active connection and test it.
  Future<bool> setConnection(OpenCodeConnection connection) async {
    _connection = connection;
    _client.setConnection(connection);
    final healthy = await _client.checkHealth();
    _isConnected = healthy;
    _connectionStatusController.add(_isConnected);
    return healthy;
  }

  /// Clear the current connection.
  void clearConnection() {
    _connection = null;
    _isConnected = false;
    _client.clearConnection();
    _connectionStatusController.add(false);
  }

  /// Test the current connection without changing state.
  Future<bool> testConnection() async {
    if (_connection == null) return false;
    return _client.checkHealth();
  }

  /// Test a connection configuration without setting it as active.
  Future<({bool healthy, String? version, int? modelCount})>
  testConnectionConfig(OpenCodeConnection connection) async {
    final testClient = OpenCodeApiClient();
    testClient.setConnection(connection);
    try {
      final healthy = await testClient.checkHealth();
      if (!healthy) {
        return (healthy: false, version: null, modelCount: null);
      }
      final version = await testClient.getVersion();
      int? modelCount;
      try {
        final providers = await testClient.getProviders();
        modelCount = providers.allModels.length;
      } catch (_) {}
      return (healthy: true, version: version, modelCount: modelCount);
    } catch (_) {
      return (healthy: false, version: null, modelCount: null);
    } finally {
      testClient.dispose();
    }
  }

  /// Dispose of resources.
  void dispose() {
    _client.dispose();
    _connectionStatusController.close();
  }
}
