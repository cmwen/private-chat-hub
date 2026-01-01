import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';

void main() {
  group('Conversation', () {
    test('should create a conversation with required fields', () {
      final conversation = Conversation(
        id: 'test-id',
        title: 'Test Conversation',
        modelName: 'llama3.2:latest',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      expect(conversation.id, 'test-id');
      expect(conversation.title, 'Test Conversation');
      expect(conversation.modelName, 'llama3.2:latest');
      expect(conversation.messages, isEmpty);
      expect(conversation.messageCount, 0);
    });

    test('should serialize to and from JSON', () {
      final original = Conversation(
        id: 'test-id',
        title: 'Test Conversation',
        modelName: 'llama3.2:latest',
        messages: [
          Message.user(
            id: 'msg-1',
            text: 'Hello',
            timestamp: DateTime(2025, 1, 1, 10, 0),
          ),
        ],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1, 10, 5),
        systemPrompt: 'You are a helpful assistant.',
      );

      final json = original.toJson();
      final restored = Conversation.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.modelName, original.modelName);
      expect(restored.messages.length, 1);
      expect(restored.systemPrompt, original.systemPrompt);
    });

    test('should add message to conversation', () {
      var conversation = Conversation(
        id: 'test-id',
        title: 'Test',
        modelName: 'llama3.2:latest',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      final message = Message.user(
        id: 'msg-1',
        text: 'Hello!',
        timestamp: DateTime.now(),
      );

      conversation = conversation.addMessage(message);

      expect(conversation.messages.length, 1);
      expect(conversation.messages.first.text, 'Hello!');
    });

    test('should generate title from first message', () {
      final shortTitle = Conversation.generateTitle('Hello world');
      expect(shortTitle, 'Hello world');

      final longMessage =
          'This is a very long message that should be truncated because it exceeds the maximum length';
      final truncatedTitle = Conversation.generateTitle(longMessage);
      expect(truncatedTitle.length, 43); // 40 + "..."
      expect(truncatedTitle.endsWith('...'), isTrue);
    });

    test('should return last message preview', () {
      final conversation = Conversation(
        id: 'test-id',
        title: 'Test',
        modelName: 'llama3.2:latest',
        messages: [
          Message.user(
            id: 'msg-1',
            text: 'First message',
            timestamp: DateTime(2025, 1, 1),
          ),
          Message.assistant(
            id: 'msg-2',
            text: 'This is a response from the assistant',
            timestamp: DateTime(2025, 1, 1),
          ),
        ],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      expect(
        conversation.lastMessagePreview,
        'This is a response from the assistant',
      );
    });

    test('should return "No messages yet" for empty conversation', () {
      final conversation = Conversation(
        id: 'test-id',
        title: 'Test',
        modelName: 'llama3.2:latest',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      expect(conversation.lastMessagePreview, 'No messages yet');
    });
  });
}
