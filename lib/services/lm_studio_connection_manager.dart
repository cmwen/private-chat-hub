import 'dart:async';
import 'package:private_chat_hub/models/lm_studio_connection.dart';
import 'package:private_chat_hub/services/lm_studio_api_client.dart';

/// Manages the LM Studio server connection lifecycle.
class LmStudioConnectionManager {
  final LmStudioApiClient _client;

  LmStudioConnection? _connection;
  bool _isConnected = false;

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  LmStudioConnectionManager({LmStudioApiClient? client})
    : _client = client ?? LmStudioApiClient();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected => _isConnected;

  LmStudioConnection? get connection => _connection;

  LmStudioApiClient get client => _client;

  Future<bool> setConnection(LmStudioConnection connection) async {
    _connection = connection;
    _client.setConnection(connection);
    final healthy = await _client.checkHealth();
    _isConnected = healthy;
    _connectionStatusController.add(_isConnected);
    return healthy;
  }

  void clearConnection() {
    _connection = null;
    _isConnected = false;
    _client.clearConnection();
    _connectionStatusController.add(false);
  }

  Future<bool> testConnection() async {
    if (_connection == null) return false;
    return _client.checkHealth();
  }

  Future<({bool healthy, int? modelCount})> testConnectionConfig(
    LmStudioConnection connection,
  ) async {
    final testClient = LmStudioApiClient();
    testClient.setConnection(connection);
    try {
      final models = await testClient.listModels();
      return (
        healthy: true,
        modelCount: models.models.where((model) => model.isLlm).length,
      );
    } catch (_) {
      return (healthy: false, modelCount: null);
    } finally {
      testClient.dispose();
    }
  }

  void dispose() {
    _client.dispose();
    _connectionStatusController.close();
  }
}