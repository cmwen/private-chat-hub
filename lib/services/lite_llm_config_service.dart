import 'dart:convert';

import 'package:private_chat_hub/models/lite_llm_connection.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class LiteLlmConfigService {
  static const String _connectionsKey = 'lite_llm_connections';
  static const String _defaultConnectionKey = 'lite_llm_default_connection_id';

  final StorageService _storage;

  LiteLlmConfigService(this._storage);

  List<LiteLlmConnection> getConnections() {
    final jsonString = _storage.getString(_connectionsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map(
            (json) => LiteLlmConnection.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveConnections(List<LiteLlmConnection> connections) async {
    final jsonString = jsonEncode(connections.map((c) => c.toJson()).toList());
    await _storage.setString(_connectionsKey, jsonString);
  }

  Future<LiteLlmConnection> addConnection({
    required String name,
    required String baseUrl,
    bool setAsDefault = false,
  }) async {
    final connections = getConnections();
    final isDefault = connections.isEmpty || setAsDefault;

    final connection = LiteLlmConnection(
      id: const Uuid().v4(),
      name: name,
      baseUrl: baseUrl,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );

    final updatedConnections = connections.map((c) {
      return isDefault && c.isDefault ? c.copyWith(isDefault: false) : c;
    }).toList();

    updatedConnections.add(connection);
    await _saveConnections(updatedConnections);

    if (isDefault) {
      await _storage.setString(_defaultConnectionKey, connection.id);
    }

    return connection;
  }

  Future<void> updateConnection(LiteLlmConnection connection) async {
    final connections = getConnections();
    final index = connections.indexWhere((c) => c.id == connection.id);

    if (index != -1) {
      connections[index] = connection;
      await _saveConnections(connections);
    }
  }

  Future<void> deleteConnection(String id) async {
    var connections = getConnections();
    final deletedConnection = connections.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Connection not found'),
    );

    connections = connections.where((c) => c.id != id).toList();

    if (deletedConnection.isDefault && connections.isNotEmpty) {
      connections[0] = connections[0].copyWith(isDefault: true);
      await _storage.setString(_defaultConnectionKey, connections[0].id);
    }

    await _saveConnections(connections);
  }

  Future<void> setDefaultConnection(String id) async {
    final connections = getConnections();
    final updatedConnections = connections.map((c) {
      return c.copyWith(isDefault: c.id == id);
    }).toList();

    await _saveConnections(updatedConnections);
    await _storage.setString(_defaultConnectionKey, id);
  }

  LiteLlmConnection? getDefaultConnection() {
    final connections = getConnections();
    if (connections.isEmpty) return null;

    try {
      return connections.firstWhere((c) => c.isDefault);
    } catch (_) {
      return connections.first;
    }
  }

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
}
