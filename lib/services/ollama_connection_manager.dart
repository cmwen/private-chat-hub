import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/models/connection.dart';

/// Manages Ollama connections and provides a configured OllamaClient.
///
/// This is a simple wrapper that bridges the app's Connection model
/// with the OllamaClient from the toolkit.
class OllamaConnectionManager {
  Connection? _connection;
  OllamaClient? _client;
  Duration _timeout = const Duration(seconds: 120); // Default: 2 minutes

  /// Gets the current connection configuration.
  Connection? get connection => _connection;

  /// Gets the configured OllamaClient, or null if no connection is set.
  OllamaClient? get client => _client;

  /// Gets the current timeout duration
  Duration get timeout => _timeout;

  /// Sets the timeout for requests
  void setTimeout(Duration timeout) {
    _timeout = timeout;
    // Recreate client with new timeout if connection is set
    if (_connection != null) {
      _client = OllamaClient(baseUrl: _connection!.url, timeout: _timeout);
    }
  }

  /// Sets the connection and creates a new OllamaClient.
  void setConnection(Connection connection) {
    _connection = connection;
    _client = OllamaClient(baseUrl: connection.url, timeout: _timeout);
  }

  /// Tests the connection to the Ollama server.
  Future<bool> testConnection([Connection? connection]) async {
    if (connection != null) {
      final tempClient = OllamaClient(
        baseUrl: connection.url,
        timeout: const Duration(seconds: 5),
      );
      return await tempClient.testConnection();
    }

    if (_client == null) {
      return false;
    }

    return await _client!.testConnection();
  }

  /// Lists all available models from the connected Ollama instance.
  Future<List<OllamaModelInfo>> listModels() async {
    if (_client == null) {
      throw Exception('No connection configured');
    }

    final response = await _client!.listModels();
    return response.models;
  }

  /// Shows information about a specific model.
  Future<OllamaModelInfo> showModel(String modelName) async {
    if (_client == null) {
      throw Exception('No connection configured');
    }

    return await _client!.showModel(modelName);
  }

  /// Pulls (downloads) a model from the Ollama registry.
  Future<void> pullModel(
    String modelName, {
    void Function(double)? onProgress,
  }) async {
    if (_client == null) {
      throw Exception('No connection configured');
    }

    await _client!.pullModel(modelName, onProgress: onProgress);
  }

  /// Deletes a model from the Ollama instance.
  Future<void> deleteModel(String modelName) async {
    if (_client == null) {
      throw Exception('No connection configured');
    }

    await _client!.deleteModel(modelName);
  }

  /// Clears the current connection.
  void clearConnection() {
    _connection = null;
    _client = null;
  }
}
