import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_message.dart';

void main() {
  group('OllamaMessage', () {
    test('creates system message', () {
      final message = OllamaMessage.system('You are helpful');

      expect(message.role, 'system');
      expect(message.content, 'You are helpful');
      expect(message.images, null);
      expect(message.toolCalls, null);
    });

    test('creates user message', () {
      final message = OllamaMessage.user('Hello!');

      expect(message.role, 'user');
      expect(message.content, 'Hello!');
    });

    test('creates user message with images', () {
      final message = OllamaMessage.user(
        'What is this?',
        images: ['base64...'],
      );

      expect(message.role, 'user');
      expect(message.images, ['base64...']);
    });

    test('creates assistant message', () {
      final message = OllamaMessage.assistant('I am here to help');

      expect(message.role, 'assistant');
      expect(message.content, 'I am here to help');
    });

    test('creates assistant message with tool calls', () {
      final toolCall = ToolCall(
        id: '1',
        name: 'calculator',
        arguments: {'expression': '2+2'},
      );
      final message = OllamaMessage.assistant(
        'Let me calculate',
        toolCalls: [toolCall],
      );

      expect(message.toolCalls, hasLength(1));
      expect(message.toolCalls![0].name, 'calculator');
    });

    test('creates assistant message with thinking', () {
      final message = OllamaMessage.assistant(
        'The answer is 4',
        thinking: 'First I need to add 2+2...',
      );

      expect(message.role, 'assistant');
      expect(message.content, 'The answer is 4');
      expect(message.thinking, 'First I need to add 2+2...');
    });

    test('creates tool message', () {
      final message = OllamaMessage.tool('Result: 4', toolName: 'calculator');

      expect(message.role, 'tool');
      expect(message.content, 'Result: 4');
      expect(message.toolName, 'calculator');
    });

    test('serializes to JSON', () {
      final message = OllamaMessage.user('Hello', images: ['img1']);
      final json = message.toJson();

      expect(json['role'], 'user');
      expect(json['content'], 'Hello');
      expect(json['images'], ['img1']);
    });

    test('deserializes from JSON', () {
      final json = {'role': 'assistant', 'content': 'Hi there'};
      final message = OllamaMessage.fromJson(json);

      expect(message.role, 'assistant');
      expect(message.content, 'Hi there');
    });

    test('serializes tool calls to JSON', () {
      final toolCall = ToolCall(
        id: '1',
        name: 'test',
        arguments: {'key': 'value'},
      );
      final message = OllamaMessage.assistant(
        'Calling tool',
        toolCalls: [toolCall],
      );
      final json = message.toJson();

      expect(json['tool_calls'], isNotEmpty);
      expect(json['tool_calls'][0]['name'], 'test');
    });

    test('serializes thinking to JSON', () {
      final message = OllamaMessage.assistant(
        'Answer',
        thinking: 'Reasoning trace',
      );
      final json = message.toJson();

      expect(json['thinking'], 'Reasoning trace');
    });

    test('serializes tool message with tool_name to JSON', () {
      final message = OllamaMessage.tool(
        'Result',
        toolName: 'calculator',
        toolId: 'call_123',
      );
      final json = message.toJson();

      expect(json['role'], 'tool');
      expect(json['tool_name'], 'calculator');
      expect(json['tool_id'], 'call_123');
    });
  });

  group('ToolCall', () {
    test('creates tool call', () {
      final toolCall = ToolCall(
        id: 'call_123',
        name: 'calculator',
        arguments: {'expression': '10 * 5'},
      );

      expect(toolCall.id, 'call_123');
      expect(toolCall.name, 'calculator');
      expect(toolCall.arguments['expression'], '10 * 5');
    });

    test('creates tool call with index for parallel calling', () {
      final toolCall = ToolCall(
        id: 'call_123',
        name: 'calculator',
        arguments: {'expression': '10 * 5'},
        index: 0,
      );

      expect(toolCall.index, 0);
    });

    test('serializes to JSON', () {
      final toolCall = ToolCall(
        id: '1',
        name: 'test',
        arguments: {'a': 1, 'b': 2},
      );
      final json = toolCall.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'test');
      expect(json['arguments']['a'], 1);
    });

    test('serializes to JSON with index', () {
      final toolCall = ToolCall(
        id: 'call_abc',
        name: 'get_weather',
        arguments: {'city': 'London'},
        index: 2,
      );
      final json = toolCall.toJson();

      expect(json['index'], 2);
    });

    test('deserializes from JSON', () {
      final json = {
        'id': 'call_456',
        'name': 'weather',
        'arguments': {'city': 'Paris'},
      };
      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.id, 'call_456');
      expect(toolCall.name, 'weather');
      expect(toolCall.arguments['city'], 'Paris');
    });
  });
}
