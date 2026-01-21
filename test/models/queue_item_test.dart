import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/models/queue_item.dart';

void main() {
  group('QueueItem', () {
    test('should serialize provider type', () {
      final original = QueueItem(
        id: 'queue-1',
        conversationId: 'conv-1',
        messageId: 'msg-1',
        providerType: AiProviderType.liteLlm,
        queuedAt: DateTime(2025, 1, 1),
      );

      final json = original.toJson();
      final restored = QueueItem.fromJson(json);

      expect(restored.providerType, AiProviderType.liteLlm);
      expect(restored.id, original.id);
      expect(restored.messageId, original.messageId);
    });
  });
}
