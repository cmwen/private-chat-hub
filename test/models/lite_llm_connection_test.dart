import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/models/lite_llm_connection.dart';

void main() {
  group('LiteLlmConnection', () {
    test('should create with defaults', () {
      final connection = LiteLlmConnection(
        id: 'test-id',
        name: 'Local Gateway',
        baseUrl: 'http://localhost:4000',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(connection.isDefault, isFalse);
      expect(connection.providerType, AiProviderType.liteLlm);
    });

    test('should serialize to and from JSON', () {
      final original = LiteLlmConnection(
        id: 'test-id',
        name: 'Local Gateway',
        baseUrl: 'http://localhost:4000',
        isDefault: true,
        createdAt: DateTime(2025, 1, 1),
        lastConnectedAt: DateTime(2025, 1, 2),
      );

      final json = original.toJson();
      final restored = LiteLlmConnection.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.baseUrl, original.baseUrl);
      expect(restored.isDefault, isTrue);
      expect(restored.createdAt, original.createdAt);
      expect(restored.lastConnectedAt, original.lastConnectedAt);
    });

    test('should copy with updates', () {
      final original = LiteLlmConnection(
        id: 'test-id',
        name: 'Local Gateway',
        baseUrl: 'http://localhost:4000',
        createdAt: DateTime(2025, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Remote Gateway',
        baseUrl: 'http://remote:4000',
        isDefault: true,
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Remote Gateway');
      expect(updated.baseUrl, 'http://remote:4000');
      expect(updated.isDefault, isTrue);
    });
  });
}
