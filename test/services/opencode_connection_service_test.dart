import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/opencode_connection.dart';
import 'package:private_chat_hub/services/opencode_connection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late OpenCodeConnectionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = OpenCodeConnectionService(prefs);
  });

  group('OpenCodeConnectionService', () {
    test('first added connection becomes default', () async {
      final connection = await service.addConnection(
        name: 'Primary',
        host: '127.0.0.1',
      );

      final connections = service.getConnections();
      expect(connections, hasLength(1));
      expect(connections.first.id, connection.id);
      expect(connections.first.isDefault, isTrue);
      expect(service.getDefaultConnection()?.id, connection.id);
    });

    test('setDefaultConnection updates stored default', () async {
      final first = await service.addConnection(name: 'One', host: 'one.local');
      final second = await service.addConnection(name: 'Two', host: 'two.local');

      await service.setDefaultConnection(second.id);

      final connections = service.getConnections();
      expect(connections.firstWhere((c) => c.id == first.id).isDefault, isFalse);
      expect(connections.firstWhere((c) => c.id == second.id).isDefault, isTrue);
      expect(service.getDefaultConnection()?.id, second.id);
    });

    test('deleting default promotes first remaining connection', () async {
      final first = await service.addConnection(name: 'One', host: 'one.local');
      final second = await service.addConnection(
        name: 'Two',
        host: 'two.local',
        setAsDefault: true,
      );

      await service.deleteConnection(second.id);

      final connections = service.getConnections();
      expect(connections, hasLength(1));
      expect(connections.first.id, first.id);
      expect(connections.first.isDefault, isTrue);
      expect(service.getDefaultConnection()?.id, first.id);
    });

    test('updateLastConnected stamps the connection', () async {
      final connection = await service.addConnection(name: 'One', host: 'one.local');

      await service.updateLastConnected(connection.id);

      final updated = service.getConnections().first;
      expect(updated.lastConnectedAt, isNotNull);
    });

    test('migrates legacy single connection storage', () async {
      final legacyConnection = OpenCodeConnection(
        id: 'default',
        name: 'Legacy',
        host: 'legacy.local',
        username: 'user',
        password: 'pass',
        createdAt: DateTime.utc(2024, 1, 1),
      );

      SharedPreferences.setMockInitialValues({
        'opencode_connection': jsonEncode(legacyConnection.toJson()),
      });

      prefs = await SharedPreferences.getInstance();
      service = OpenCodeConnectionService(prefs);

      final connections = service.getConnections();
      expect(connections, hasLength(1));
      expect(connections.first.name, 'Legacy');
      expect(connections.first.isDefault, isTrue);
      expect(connections.first.id, isNot('default'));
      expect(service.getDefaultConnection()?.id, connections.first.id);
      expect(prefs.getString('opencode_connection'), isNull);
    });
  });
}