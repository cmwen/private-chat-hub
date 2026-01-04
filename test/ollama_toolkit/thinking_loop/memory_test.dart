import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/ollama_toolkit/thinking_loop/memory.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_message.dart';

void main() {
  group('ConversationMemory', () {
    test('starts empty', () {
      final memory = ConversationMemory();

      expect(memory.length, 0);
      expect(memory.getMessages(), isEmpty);
    });

    test('adds messages', () {
      final memory = ConversationMemory();
      memory.addMessage(OllamaMessage.user('Hello'));
      memory.addMessage(OllamaMessage.assistant('Hi there'));

      expect(memory.length, 2);
      expect(memory.getMessages()[0].content, 'Hello');
      expect(memory.getMessages()[1].content, 'Hi there');
    });

    test('clears messages', () {
      final memory = ConversationMemory();
      memory.addMessage(OllamaMessage.user('Hello'));
      memory.clear();

      expect(memory.length, 0);
      expect(memory.getMessages(), isEmpty);
    });

    test('respects max messages', () {
      final memory = ConversationMemory(maxMessages: 3);
      memory.addMessage(OllamaMessage.user('1'));
      memory.addMessage(OllamaMessage.user('2'));
      memory.addMessage(OllamaMessage.user('3'));
      memory.addMessage(OllamaMessage.user('4'));

      expect(memory.length, 3);
      expect(memory.getMessages()[0].content, '2');
      expect(memory.getMessages()[2].content, '4');
    });

    test('returns unmodifiable list', () {
      final memory = ConversationMemory();
      memory.addMessage(OllamaMessage.user('Hello'));
      final messages = memory.getMessages();

      expect(
        () => messages.add(OllamaMessage.user('test')),
        throwsUnsupportedError,
      );
    });
  });

  group('SlidingWindowMemory', () {
    test('keeps only window size messages', () {
      final memory = SlidingWindowMemory(windowSize: 2);
      memory.addMessage(OllamaMessage.user('1'));
      memory.addMessage(OllamaMessage.user('2'));
      memory.addMessage(OllamaMessage.user('3'));

      expect(memory.length, 2);
      expect(memory.getMessages()[0].content, '2');
      expect(memory.getMessages()[1].content, '3');
    });

    test('maintains window as new messages arrive', () {
      final memory = SlidingWindowMemory(windowSize: 3);
      memory.addMessage(OllamaMessage.user('1'));
      memory.addMessage(OllamaMessage.user('2'));
      memory.addMessage(OllamaMessage.user('3'));
      memory.addMessage(OllamaMessage.user('4'));
      memory.addMessage(OllamaMessage.user('5'));

      expect(memory.length, 3);
      expect(memory.getMessages()[0].content, '3');
      expect(memory.getMessages()[2].content, '5');
    });
  });

  group('SystemPlusSlidingMemory', () {
    test('keeps system messages plus window', () {
      final memory = SystemPlusSlidingMemory(windowSize: 2);
      memory.addMessage(OllamaMessage.system('You are helpful'));
      memory.addMessage(OllamaMessage.user('1'));
      memory.addMessage(OllamaMessage.user('2'));
      memory.addMessage(OllamaMessage.user('3'));

      expect(memory.length, 3);
      final messages = memory.getMessages();
      expect(messages[0].role, 'system');
      expect(messages[1].content, '2');
      expect(messages[2].content, '3');
    });

    test('keeps multiple system messages', () {
      final memory = SystemPlusSlidingMemory(windowSize: 2);
      memory.addMessage(OllamaMessage.system('System 1'));
      memory.addMessage(OllamaMessage.system('System 2'));
      memory.addMessage(OllamaMessage.user('1'));
      memory.addMessage(OllamaMessage.user('2'));
      memory.addMessage(OllamaMessage.user('3'));

      expect(memory.length, 4);
      final messages = memory.getMessages();
      expect(messages.where((m) => m.role == 'system'), hasLength(2));
    });

    test('works with only user messages', () {
      final memory = SystemPlusSlidingMemory(windowSize: 2);
      memory.addMessage(OllamaMessage.user('1'));
      memory.addMessage(OllamaMessage.user('2'));
      memory.addMessage(OllamaMessage.user('3'));

      expect(memory.length, 2);
      expect(memory.getMessages()[0].content, '2');
    });
  });
}
