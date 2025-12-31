import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/tool.dart';

void main() {
  group('Tool', () {
    test('should create a tool with required fields', () {
      const tool = Tool(
        name: 'test_tool',
        description: 'A test tool',
        parameters: {
          'type': 'object',
          'properties': {},
        },
      );

      expect(tool.name, 'test_tool');
      expect(tool.description, 'A test tool');
      expect(tool.parameters['type'], 'object');
    });

    test('should convert to Ollama format correctly', () {
      const tool = Tool(
        name: 'test_tool',
        description: 'A test tool',
        parameters: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
        },
      );

      final ollamaFormat = tool.toOllamaFormat();

      expect(ollamaFormat['type'], 'function');
      expect(ollamaFormat['function']['name'], 'test_tool');
      expect(ollamaFormat['function']['description'], 'A test tool');
      expect(ollamaFormat['function']['parameters']['type'], 'object');
    });

    test('should serialize to and from JSON', () {
      const tool = Tool(
        name: 'test_tool',
        description: 'A test tool',
        parameters: {'type': 'object'},
      );

      final json = tool.toJson();
      final recreated = Tool.fromJson(json);

      expect(recreated.name, tool.name);
      expect(recreated.description, tool.description);
      expect(recreated.parameters, tool.parameters);
    });
  });

  group('ToolCall', () {
    test('should create a tool call with required fields', () {
      const toolCall = ToolCall(
        id: 'call_123',
        name: 'web_search',
        arguments: {'query': 'test'},
      );

      expect(toolCall.id, 'call_123');
      expect(toolCall.name, 'web_search');
      expect(toolCall.arguments['query'], 'test');
    });

    test('should serialize to and from JSON', () {
      const toolCall = ToolCall(
        id: 'call_123',
        name: 'web_search',
        arguments: {'query': 'test'},
      );

      final json = toolCall.toJson();
      final recreated = ToolCall.fromJson(json);

      expect(recreated.id, toolCall.id);
      expect(recreated.name, toolCall.name);
      expect(recreated.arguments, toolCall.arguments);
    });
  });

  group('ToolResult', () {
    test('should create a tool result', () {
      const result = ToolResult(
        toolCallId: 'call_123',
        content: 'Search results',
      );

      expect(result.toolCallId, 'call_123');
      expect(result.content, 'Search results');
      expect(result.isError, false);
    });

    test('should create an error result', () {
      const result = ToolResult(
        toolCallId: 'call_123',
        content: 'Error message',
        isError: true,
      );

      expect(result.isError, true);
    });

    test('should convert to Ollama message format', () {
      const result = ToolResult(
        toolCallId: 'call_123',
        content: 'Search results',
      );

      final message = result.toOllamaMessage();

      expect(message['role'], 'tool');
      expect(message['content'], 'Search results');
      expect(message['tool_call_id'], 'call_123');
    });

    test('should serialize to and from JSON', () {
      const result = ToolResult(
        toolCallId: 'call_123',
        content: 'Search results',
        isError: false,
      );

      final json = result.toJson();
      final recreated = ToolResult.fromJson(json);

      expect(recreated.toolCallId, result.toolCallId);
      expect(recreated.content, result.content);
      expect(recreated.isError, result.isError);
    });
  });

  group('WebSearchTool', () {
    test('should create web search tool with correct configuration', () {
      final tool = WebSearchTool();

      expect(tool.name, 'web_search');
      expect(tool.description, contains('Search the internet'));
      expect(tool.parameters['type'], 'object');
      expect(tool.parameters['properties']['query'], isNotNull);
      expect(tool.parameters['required'], contains('query'));
    });
  });
}
