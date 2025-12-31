import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/message.dart';

void main() {
  group('Message', () {
    test('creates a message with required fields', () {
      final timestamp = DateTime.now();
      final message = Message(
        id: '1',
        text: 'Hello',
        isMe: true,
        timestamp: timestamp,
      );

      expect(message.id, '1');
      expect(message.text, 'Hello');
      expect(message.isMe, true);
      expect(message.timestamp, timestamp);
    });

    test('converts to JSON correctly', () {
      final timestamp = DateTime(2025, 1, 1, 12, 0, 0);
      final message = Message(
        id: '1',
        text: 'Hello',
        isMe: true,
        timestamp: timestamp,
      );

      final json = message.toJson();

      expect(json['id'], '1');
      expect(json['text'], 'Hello');
      expect(json['isMe'], true);
      expect(json['timestamp'], '2025-01-01T12:00:00.000');
    });

    test('creates from JSON correctly', () {
      final json = {
        'id': '1',
        'text': 'Hello',
        'isMe': true,
        'timestamp': '2025-01-01T12:00:00.000',
      };

      final message = Message.fromJson(json);

      expect(message.id, '1');
      expect(message.text, 'Hello');
      expect(message.isMe, true);
      expect(message.timestamp, DateTime(2025, 1, 1, 12, 0, 0));
    });

    test('equality based on id', () {
      final message1 = Message(
        id: '1',
        text: 'Hello',
        isMe: true,
        timestamp: DateTime.now(),
      );

      final message2 = Message(
        id: '1',
        text: 'Different text',
        isMe: false,
        timestamp: DateTime.now(),
      );

      expect(message1, equals(message2));
      expect(message1.hashCode, equals(message2.hashCode));
    });

    test('inequality when different ids', () {
      final message1 = Message(
        id: '1',
        text: 'Hello',
        isMe: true,
        timestamp: DateTime.now(),
      );

      final message2 = Message(
        id: '2',
        text: 'Hello',
        isMe: true,
        timestamp: DateTime.now(),
      );

      expect(message1, isNot(equals(message2)));
    });
  });
}
