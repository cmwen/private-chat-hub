import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/connection.dart';

void main() {
  group('Connection', () {
    test('should create a connection with required fields', () {
      final connection = Connection(
        id: 'test-id',
        name: 'Home Server',
        host: '192.168.1.100',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(connection.id, 'test-id');
      expect(connection.name, 'Home Server');
      expect(connection.host, '192.168.1.100');
      expect(connection.port, 11434);
      expect(connection.useHttps, isFalse);
      expect(connection.isDefault, isFalse);
    });

    test('should generate correct URL', () {
      final httpConnection = Connection(
        id: 'test-id',
        name: 'HTTP Server',
        host: '192.168.1.100',
        port: 11434,
        useHttps: false,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(httpConnection.url, 'http://192.168.1.100:11434');

      final httpsConnection = Connection(
        id: 'test-id',
        name: 'HTTPS Server',
        host: 'example.com',
        port: 443,
        useHttps: true,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(httpsConnection.url, 'https://example.com:443');
    });

    test('should serialize to and from JSON', () {
      final original = Connection(
        id: 'test-id',
        name: 'Home Server',
        host: '192.168.1.100',
        port: 11434,
        useHttps: false,
        isDefault: true,
        createdAt: DateTime(2025, 1, 1),
        lastConnectedAt: DateTime(2025, 1, 2),
      );

      final json = original.toJson();
      final restored = Connection.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.host, original.host);
      expect(restored.port, original.port);
      expect(restored.useHttps, original.useHttps);
      expect(restored.isDefault, original.isDefault);
      expect(restored.createdAt, original.createdAt);
      expect(restored.lastConnectedAt, original.lastConnectedAt);
    });

    test('should create copy with updated fields', () {
      final original = Connection(
        id: 'test-id',
        name: 'Home Server',
        host: '192.168.1.100',
        createdAt: DateTime(2025, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Office Server',
        host: '10.0.0.1',
        port: 8080,
      );

      expect(updated.name, 'Office Server');
      expect(updated.host, '10.0.0.1');
      expect(updated.port, 8080);
      expect(updated.id, original.id); // Unchanged
    });

    test('should compare equality by id', () {
      final conn1 = Connection(
        id: 'same-id',
        name: 'Server 1',
        host: '192.168.1.100',
        createdAt: DateTime(2025, 1, 1),
      );

      final conn2 = Connection(
        id: 'same-id',
        name: 'Server 2', // Different name
        host: '192.168.1.200', // Different host
        createdAt: DateTime(2025, 1, 2),
      );

      final conn3 = Connection(
        id: 'different-id',
        name: 'Server 1',
        host: '192.168.1.100',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(conn1, equals(conn2)); // Same ID
      expect(conn1, isNot(equals(conn3))); // Different ID
    });
  });
}
