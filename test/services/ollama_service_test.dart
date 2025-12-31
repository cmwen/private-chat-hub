import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/ollama_service.dart';

void main() {
  group('OllamaModel', () {
    test('should create model from JSON', () {
      final json = {
        'name': 'llama3.2:latest',
        'modified_at': '2025-01-01T00:00:00Z',
        'size': 4_500_000_000,
        'digest': 'abc123',
        'details': {
          'parameter_size': '3B',
        },
      };

      final model = OllamaModel.fromJson(json);

      expect(model.name, 'llama3.2:latest');
      expect(model.family, 'llama3.2');
      expect(model.tag, 'latest');
      expect(model.parameterCount, '3B');
      expect(model.sizeFormatted, '4.2 GB');
    });

    test('should handle model without tag', () {
      final json = {
        'name': 'phi3',
        'size': 2_000_000_000,
      };

      final model = OllamaModel.fromJson(json);

      expect(model.name, 'phi3');
      expect(model.family, 'phi3');
      expect(model.tag, 'latest');
    });

    test('should format size correctly', () {
      expect(
        OllamaModel.fromJson({'name': 'test', 'size': 500_000_000}).sizeFormatted,
        '477 MB',
      );
      expect(
        OllamaModel.fromJson({'name': 'test', 'size': 1_500_000_000}).sizeFormatted,
        '1.4 GB',
      );
      expect(
        OllamaModel.fromJson({'name': 'test'}).sizeFormatted,
        'Unknown',
      );
    });
  });

  group('OllamaConnection', () {
    test('should create connection with defaults', () {
      final conn = OllamaConnection(host: 'localhost');

      expect(conn.host, 'localhost');
      expect(conn.port, 11434);
      expect(conn.useHttps, isFalse);
      expect(conn.baseUrl, 'http://localhost:11434');
    });

    test('should create HTTPS connection', () {
      final conn = OllamaConnection(
        host: 'ollama.example.com',
        port: 443,
        useHttps: true,
      );

      expect(conn.baseUrl, 'https://ollama.example.com:443');
    });

    test('should serialize to and from JSON', () {
      final original = OllamaConnection(
        host: '192.168.1.100',
        port: 11434,
        useHttps: false,
        name: 'Home Server',
      );

      final json = original.toJson();
      final restored = OllamaConnection.fromJson(json);

      expect(restored.host, original.host);
      expect(restored.port, original.port);
      expect(restored.useHttps, original.useHttps);
      expect(restored.name, original.name);
    });

    test('should create copy with updated fields', () {
      final original = OllamaConnection(host: 'localhost');
      final updated = original.copyWith(
        host: '192.168.1.100',
        port: 8080,
      );

      expect(updated.host, '192.168.1.100');
      expect(updated.port, 8080);
      expect(updated.useHttps, isFalse); // Unchanged
    });
  });

  group('OllamaException', () {
    test('should format exception with status code', () {
      final exception = OllamaException('Connection failed', 500);

      expect(exception.toString(),
          'OllamaException: Connection failed (Status: 500)');
    });

    test('should format exception without status code', () {
      final exception = OllamaException('Network error');

      expect(exception.toString(), 'OllamaException: Network error');
    });
  });
}
