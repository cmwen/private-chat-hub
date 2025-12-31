import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/message.dart';

void main() {
  group('Attachment', () {
    test('should create an image attachment', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final attachment = Attachment(
        id: 'att-1',
        name: 'test.jpg',
        mimeType: 'image/jpeg',
        data: data,
        size: data.length,
      );

      expect(attachment.id, 'att-1');
      expect(attachment.name, 'test.jpg');
      expect(attachment.mimeType, 'image/jpeg');
      expect(attachment.isImage, true);
      expect(attachment.size, 5);
    });

    test('should identify non-image attachments', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final attachment = Attachment(
        id: 'att-2',
        name: 'document.pdf',
        mimeType: 'application/pdf',
        data: data,
        size: data.length,
      );

      expect(attachment.isImage, false);
    });

    test('should format size correctly', () {
      // Bytes
      final small = Attachment(
        id: 'att-1',
        name: 'tiny.txt',
        mimeType: 'text/plain',
        data: Uint8List.fromList([1, 2, 3]),
        size: 3,
      );
      expect(small.formattedSize, '3 B');

      // Kilobytes
      final medium = Attachment(
        id: 'att-2',
        name: 'medium.txt',
        mimeType: 'text/plain',
        data: Uint8List(2048),
        size: 2048,
      );
      expect(medium.formattedSize, '2.0 KB');

      // Megabytes
      final large = Attachment(
        id: 'att-3',
        name: 'large.bin',
        mimeType: 'application/octet-stream',
        data: Uint8List(1),
        size: 1048576,
      );
      expect(large.formattedSize, '1.0 MB');
    });

    test('should serialize to and from JSON', () {
      final data = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
      final original = Attachment(
        id: 'att-json',
        name: 'hello.txt',
        mimeType: 'text/plain',
        data: data,
        size: data.length,
      );

      final json = original.toJson();
      final restored = Attachment.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.mimeType, original.mimeType);
      expect(restored.size, original.size);
      expect(restored.data, data);
    });
  });

  group('Message with attachments', () {
    test('should create message with attachments', () {
      final attachment = Attachment(
        id: 'att-1',
        name: 'photo.jpg',
        mimeType: 'image/jpeg',
        data: Uint8List.fromList([1, 2, 3]),
        size: 3,
      );

      final message = Message.user(
        id: 'msg-1',
        text: 'Check this out!',
        timestamp: DateTime(2025, 1, 1, 10, 0),
        attachments: [attachment],
      );

      expect(message.attachments.length, 1);
      expect(message.hasImages, true);
      expect(message.images.length, 1);
    });

    test('should include images in Ollama message format', () {
      final imageData = Uint8List.fromList([0xFF, 0xD8, 0xFF]); // JPEG magic bytes
      final attachment = Attachment(
        id: 'att-1',
        name: 'photo.jpg',
        mimeType: 'image/jpeg',
        data: imageData,
        size: imageData.length,
      );

      final message = Message.user(
        id: 'msg-1',
        text: 'What is in this image?',
        timestamp: DateTime.now(),
        attachments: [attachment],
      );

      final ollamaMessage = message.toOllamaMessage();

      expect(ollamaMessage['role'], 'user');
      expect(ollamaMessage['content'], 'What is in this image?');
      expect(ollamaMessage['images'], isNotNull);
      expect((ollamaMessage['images'] as List).length, 1);
    });

    test('should serialize message with attachments', () {
      final attachment = Attachment(
        id: 'att-1',
        name: 'test.png',
        mimeType: 'image/png',
        data: Uint8List.fromList([1, 2, 3]),
        size: 3,
      );

      final original = Message.user(
        id: 'msg-att',
        text: 'Image message',
        timestamp: DateTime(2025, 1, 1, 12, 0),
        attachments: [attachment],
      );

      final json = original.toJson();
      final restored = Message.fromJson(json);

      expect(restored.attachments.length, 1);
      expect(restored.attachments.first.id, 'att-1');
      expect(restored.attachments.first.name, 'test.png');
    });

    test('should copy message with new attachments', () {
      final attachment1 = Attachment(
        id: 'att-1',
        name: 'one.jpg',
        mimeType: 'image/jpeg',
        data: Uint8List(1),
        size: 1,
      );
      final attachment2 = Attachment(
        id: 'att-2',
        name: 'two.jpg',
        mimeType: 'image/jpeg',
        data: Uint8List(1),
        size: 1,
      );

      final original = Message.user(
        id: 'msg-1',
        text: 'Original',
        timestamp: DateTime.now(),
        attachments: [attachment1],
      );

      final copy = original.copyWith(attachments: [attachment1, attachment2]);

      expect(original.attachments.length, 1);
      expect(copy.attachments.length, 2);
    });
  });
}
