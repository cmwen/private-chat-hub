import 'dart:convert';

import 'package:private_chat_hub/models/opencode_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service for managing saved OpenCode connection profiles.
class OpenCodeConnectionService {
  final SharedPreferences _prefs;

  static const String _connectionsKey = 'opencode_connections';
  static const String _defaultConnectionKey = 'opencode_default_connection_id';
  static const String _legacyConnectionKey = 'opencode_connection';

  OpenCodeConnectionService(this._prefs);

  List<OpenCodeConnection> getConnections() {
    _migrateLegacyConnectionIfNeeded();

    final jsonString = _prefs.getString(_connectionsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map(
            (json) => OpenCodeConnection.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveConnections(List<OpenCodeConnection> connections) async {
    final jsonString = jsonEncode(connections.map((c) => c.toJson()).toList());
    await _prefs.setString(_connectionsKey, jsonString);
  }

  Future<OpenCodeConnection> addConnection({
    required String name,
    required String host,
    int port = 4096,
    bool useHttps = false,
    String? username,
    String? password,
    bool setAsDefault = false,
  }) async {
    final connections = getConnections();
    final isDefault = connections.isEmpty || setAsDefault;

    final connection = OpenCodeConnection(
      id: const Uuid().v4(),
      name: name,
      host: host,
      port: port,
      useHttps: useHttps,
      username: username,
      password: password,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );

    final updatedConnections = connections.map((existing) {
      return isDefault && existing.isDefault
          ? existing.copyWith(isDefault: false)
          : existing;
    }).toList();

    updatedConnections.add(connection);
    await _saveConnections(updatedConnections);

    if (isDefault) {
      await _prefs.setString(_defaultConnectionKey, connection.id);
    }

    return connection;
  }

  Future<void> updateConnection(OpenCodeConnection connection) async {
    final connections = getConnections();
    final index = connections.indexWhere((c) => c.id == connection.id);
    if (index == -1) return;

    connections[index] = connection;
    await _saveConnections(connections);
  }

  Future<void> deleteConnection(String id) async {
    var connections = getConnections();
    final deletedConnection = connections.firstWhere(
      (connection) => connection.id == id,
      orElse: () => throw Exception('Connection not found'),
    );

    connections = connections
        .where((connection) => connection.id != id)
        .toList();

    if (deletedConnection.isDefault) {
      if (connections.isNotEmpty) {
        connections[0] = connections[0].copyWith(isDefault: true);
        await _prefs.setString(_defaultConnectionKey, connections[0].id);
      } else {
        await _prefs.remove(_defaultConnectionKey);
      }
    }

    await _saveConnections(connections);
  }

  Future<void> setDefaultConnection(String id) async {
    final connections = getConnections();
    final updatedConnections = connections
        .map(
          (connection) => connection.copyWith(isDefault: connection.id == id),
        )
        .toList();

    await _saveConnections(updatedConnections);
    await _prefs.setString(_defaultConnectionKey, id);
  }

  OpenCodeConnection? getDefaultConnection() {
    final connections = getConnections();
    if (connections.isEmpty) return null;

    final defaultId = _prefs.getString(_defaultConnectionKey);
    if (defaultId != null) {
      try {
        return connections.firstWhere(
          (connection) => connection.id == defaultId,
        );
      } catch (_) {}
    }

    try {
      return connections.firstWhere((connection) => connection.isDefault);
    } catch (_) {
      return connections.first;
    }
  }

  Future<void> updateLastConnected(String id) async {
    final connections = getConnections();
    final index = connections.indexWhere((connection) => connection.id == id);
    if (index == -1) return;

    connections[index] = connections[index].copyWith(
      lastConnectedAt: DateTime.now(),
    );
    await _saveConnections(connections);
  }

  void _migrateLegacyConnectionIfNeeded() {
    if (_prefs.getString(_connectionsKey) != null) return;

    final legacyJson = _prefs.getString(_legacyConnectionKey);
    if (legacyJson == null || legacyJson.isEmpty) return;

    try {
      final legacy = OpenCodeConnection.fromJson(
        jsonDecode(legacyJson) as Map<String, dynamic>,
      );
      final migrated = legacy.copyWith(
        id: legacy.id == 'default' ? const Uuid().v4() : legacy.id,
        isDefault: true,
      );
      _prefs.setString(_connectionsKey, jsonEncode([migrated.toJson()]));
      _prefs.setString(_defaultConnectionKey, migrated.id);
      _prefs.remove(_legacyConnectionKey);
    } catch (_) {}
  }
}
