import 'package:private_chat_hub/models/connection.dart';
import 'package:private_chat_hub/repositories/connection_profile_repository.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Service for managing Ollama connection profiles.
class ConnectionService {
  final ConnectionProfileRepository _repository;

  ConnectionService(
    StorageService _, {
    ConnectionProfileRepository? repository,
    KnowledgeStoreService? knowledgeStoreService,
  }) : _repository =
           repository ??
           MarkdownConnectionProfileRepository(
             knowledgeStoreService ?? KnowledgeStoreService.instance,
           );

  /// Gets all saved connections.
  List<Connection> getConnections() {
    return _repository.getConnections();
  }

  /// Saves connections to storage.
  Future<void> _saveConnections(List<Connection> connections) async {
    final existingIds = _repository.getConnections().map((c) => c.id).toSet();
    final updatedIds = connections.map((c) => c.id).toSet();

    for (final connection in connections) {
      await _repository.saveConnection(connection);
    }

    for (final staleId in existingIds.difference(updatedIds)) {
      await _repository.deleteConnection(staleId);
    }
  }

  /// Adds a new connection profile.
  Future<Connection> addConnection({
    required String name,
    required String host,
    int port = 11434,
    bool useHttps = false,
    bool setAsDefault = false,
  }) async {
    final connections = getConnections();

    // If this is the first connection or setAsDefault, make it default
    final isDefault = connections.isEmpty || setAsDefault;

    final connection = Connection(
      id: const Uuid().v4(),
      name: name,
      host: host,
      port: port,
      useHttps: useHttps,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );

    // If setting as default, clear other defaults
    final updatedConnections = connections.map((c) {
      return isDefault && c.isDefault ? c.copyWith(isDefault: false) : c;
    }).toList();

    updatedConnections.add(connection);
    await _saveConnections(updatedConnections);

    return connection;
  }

  /// Updates an existing connection.
  Future<void> updateConnection(Connection connection) async {
    final connections = getConnections();
    final index = connections.indexWhere((c) => c.id == connection.id);

    if (index != -1) {
      connections[index] = connection;
      await _saveConnections(connections);
    }
  }

  /// Deletes a connection by ID.
  Future<void> deleteConnection(String id) async {
    var connections = getConnections();
    final deletedConnection = connections.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Connection not found'),
    );

    connections = connections.where((c) => c.id != id).toList();

    // If we deleted the default, make the first remaining one default
    if (deletedConnection.isDefault && connections.isNotEmpty) {
      connections[0] = connections[0].copyWith(isDefault: true);
    }

    await _saveConnections(connections);
  }

  /// Sets a connection as the default.
  Future<void> setDefaultConnection(String id) async {
    final connections = getConnections();
    final updatedConnections = connections.map((c) {
      return c.copyWith(isDefault: c.id == id);
    }).toList();

    await _saveConnections(updatedConnections);
  }

  /// Gets the default connection, or null if none set.
  Connection? getDefaultConnection() {
    final connections = getConnections();
    if (connections.isEmpty) return null;

    // Try to find the default
    try {
      return connections.firstWhere((c) => c.isDefault);
    } catch (_) {
      // Fall back to first connection
      return connections.first;
    }
  }

  /// Updates the last connected timestamp for a connection.
  Future<void> updateLastConnected(String id) async {
    final connections = getConnections();
    final index = connections.indexWhere((c) => c.id == id);

    if (index != -1) {
      connections[index] = connections[index].copyWith(
        lastConnectedAt: DateTime.now(),
      );
      await _saveConnections(connections);
    }
  }

  /// Gets the currently selected model name.
  String? getSelectedModel() {
    return _repository.getSelectedModel();
  }

  /// Sets the selected model name.
  Future<void> setSelectedModel(String modelName) async {
    await _repository.setSelectedModel(modelName);
  }
}
