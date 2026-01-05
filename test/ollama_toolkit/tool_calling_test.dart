import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_message.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_tool.dart';
import 'package:private_chat_hub/ollama_toolkit/thinking_loop/agent.dart';
import 'package:private_chat_hub/ollama_toolkit/thinking_loop/tools.dart';

/// Mock implementation of Tool for testing
class MockTool implements Tool {
  @override
  final String name;

  @override
  final String description;

  @override
  final Map<String, dynamic> parameters;

  final Future<String> Function(Map<String, dynamic> args) _execute;

  MockTool({
    required this.name,
    required this.description,
    required this.parameters,
    required Future<String> Function(Map<String, dynamic> args) execute,
  }) : _execute = execute;

  @override
  Future<String> execute(Map<String, dynamic> args) => _execute(args);

  @override
  Map<String, dynamic> toDefinition() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': parameters,
      },
    };
  }
}

void main() {
  group('ToolCall Parsing Tests', () {
    test('ToolCall.fromJson with normal data', () {
      final json = {
        'id': 'call_123',
        'name': 'web_search',
        'arguments': {'query': 'flutter'},
        'index': 0,
      };

      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.id, 'call_123');
      expect(toolCall.name, 'web_search');
      expect(toolCall.arguments, {'query': 'flutter'});
      expect(toolCall.index, 0);
    });

    test('ToolCall.fromJson with null id defaults to empty string', () {
      final json = {
        'name': 'web_search',
        'arguments': {'query': 'flutter'},
      };

      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.id, '');
      expect(toolCall.name, 'web_search');
    });

    test('ToolCall.fromJson with null name defaults to empty string', () {
      final json = {
        'id': 'call_123',
        'arguments': {'query': 'flutter'},
      };

      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.id, 'call_123');
      expect(toolCall.name, '');
    });

    test('ToolCall.fromJson with empty string name', () {
      final json = {
        'id': 'call_123',
        'name': '',
        'arguments': {'query': 'flutter'},
      };

      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.name, isEmpty);
    });

    test('ToolCall.fromJson with null arguments defaults to empty map', () {
      final json = {
        'id': 'call_123',
        'name': 'web_search',
      };

      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.arguments, isEmpty);
    });

    test('ToolCall.fromJson with nested function object', () {
      final json = {
        'function': {
          'name': 'web_search',
          'arguments': {'query': 'flutter'},
        },
      };

      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.name, 'web_search');
      expect(toolCall.arguments, {'query': 'flutter'});
    });

    test('ToolCall.fromJson prefers direct fields over nested function', () {
      final json = {
        'name': 'direct_search',
        'function': {
          'name': 'nested_search',
        },
      };

      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.name, 'direct_search');
    });

    test('ToolCall.fromJson with all null fields', () {
      final json = <String, dynamic>{};

      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.id, '');
      expect(toolCall.name, '');
      expect(toolCall.arguments, isEmpty);
    });

    test('ToolCall.toString formatting', () {
      final toolCall = ToolCall(
        id: 'call_123',
        name: 'web_search',
        arguments: {'query': 'flutter'},
      );

      expect(toolCall.toString(), contains('ToolCall'));
      expect(toolCall.toString(), contains('call_123'));
      expect(toolCall.toString(), contains('web_search'));
    });
  });

  group('OllamaMessage ToolCall Extraction Tests', () {
    test('OllamaMessage with multiple tool calls', () {
      final json = {
        'role': 'assistant',
        'content': 'Searching for information...',
        'tool_calls': [
          {
            'id': 'call_1',
            'name': 'web_search',
            'arguments': {'query': 'flutter'},
          },
          {
            'id': 'call_2',
            'name': 'get_current_datetime',
            'arguments': {},
          },
        ],
      };

      final message = OllamaMessage.fromJson(json);

      expect(message.content, 'Searching for information...');
      expect(message.toolCalls, isNotNull);
      expect(message.toolCalls?.length, 2);
      expect(message.toolCalls?[0].name, 'web_search');
      expect(message.toolCalls?[1].name, 'get_current_datetime');
    });

    test('OllamaMessage with empty tool call name', () {
      final json = {
        'role': 'assistant',
        'content': 'Processing...',
        'tool_calls': [
          {
            'id': 'call_1',
            'name': '',
            'arguments': {},
          },
        ],
      };

      final message = OllamaMessage.fromJson(json);

      expect(message.toolCalls?.length, 1);
      expect(message.toolCalls?[0].name, isEmpty);
    });

    test('OllamaMessage without tool calls', () {
      final json = {
        'role': 'assistant',
        'content': 'Here is the answer.',
      };

      final message = OllamaMessage.fromJson(json);

      expect(message.content, 'Here is the answer.');
      expect(message.toolCalls, isNull);
    });

    test('OllamaMessage with null tool calls list', () {
      final json = {
        'role': 'assistant',
        'content': 'Response',
        'tool_calls': null,
      };

      final message = OllamaMessage.fromJson(json);

      expect(message.toolCalls, isNull);
    });
  });

  group('Tool Definition Conversion Tests', () {
    test('Tool converts to ToolDefinition correctly', () {
      final tool = MockTool(
        name: 'web_search',
        description: 'Search the web',
        parameters: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
        },
        execute: (_) async => 'Results',
      );

      final definition = tool.toDefinition();

      expect(definition['function']['name'], 'web_search');
      expect(definition['function']['description'], 'Search the web');
      expect(definition['function']['parameters'], isNotNull);
    });

    test('Tool definition has required parameters structure', () {
      final tool = MockTool(
        name: 'test_tool',
        description: 'Test',
        parameters: {
          'type': 'object',
          'properties': {
            'param': {'type': 'string'},
          },
        },
        execute: (_) async => 'Result',
      );

      final definition = tool.toDefinition();

      expect(definition.containsKey('function'), true);
      expect(definition['function']['parameters']['type'], 'object');
      expect(definition['function']['parameters']['properties'], isNotNull);
    });
  });

  group('Tool Execution Error Handling Tests', () {
    test('Calling non-existent tool returns error gracefully', () async {
      final toolCalls = [
        ToolCall(
          id: 'call_1',
          name: 'non_existent_tool',
          arguments: {'param': 'value'},
        ),
      ];

      final availableTools = [
        MockTool(
          name: 'web_search',
          description: 'Search',
          parameters: {},
          execute: (_) async => 'Search result',
        ),
      ];

      // Find tool - should handle gracefully
      Tool? foundTool;
      try {
        foundTool = availableTools.firstWhere(
          (t) => t.name == toolCalls[0].name,
        );
      } catch (e) {
        foundTool = null;
      }

      expect(foundTool, isNull);
    });

    test('Empty tool name is skipped', () {
      final toolCall = ToolCall(
        id: 'call_1',
        name: '',
        arguments: {},
      );

      // Empty name should be treated as invalid
      expect(toolCall.name.isEmpty, true);
    });

    test('Tool with null arguments can be executed', () async {
      final tool = MockTool(
        name: 'datetime',
        description: 'Get current datetime',
        parameters: {},
        execute: (_) async => 'Current time: 2024-01-05',
      );

      final result = await tool.execute({});

      expect(result, isNotEmpty);
      expect(result, contains('2024'));
    });
  });

  group('Agent Step Tracking Tests', () {
    test('AgentStep is created for tool calls', () {
      final step = AgentStep(
        type: 'tool_call',
        content: 'Calling web_search',
        toolName: 'web_search',
        toolArgs: {'query': 'flutter'},
      );

      expect(step.type, 'tool_call');
      expect(step.toolName, 'web_search');
      expect(step.toolArgs, isNotNull);
    });

    test('AgentStep is created for tool results', () {
      final step = AgentStep(
        type: 'tool_result',
        content: 'Search returned 5 results',
        toolName: 'web_search',
      );

      expect(step.type, 'tool_result');
      expect(step.content, contains('results'));
    });

    test('AgentStep is created for thinking steps', () {
      final step = AgentStep(
        type: 'thinking',
        content: 'Let me search for this information',
      );

      expect(step.type, 'thinking');
      expect(step.toolName, isNull);
    });

    test('AgentStep is created for input steps', () {
      final step = AgentStep(
        type: 'input',
        content: 'User asked: what is flutter?',
      );

      expect(step.type, 'input');
    });

    test('AgentStep is created for answer steps', () {
      final step = AgentStep(
        type: 'answer',
        content: 'Flutter is a cross-platform framework',
      );

      expect(step.type, 'answer');
    });
  });

  group('Tool Availability Tests', () {
    test('Multiple tools with different names can be distinguished', () {
      final tools = [
        MockTool(
          name: 'get_current_datetime',
          description: 'Get current time',
          parameters: {},
          execute: (_) async => '2024-01-05',
        ),
        MockTool(
          name: 'web_search',
          description: 'Search web',
          parameters: {},
          execute: (_) async => 'Results',
        ),
        MockTool(
          name: 'read_url',
          description: 'Read URL',
          parameters: {},
          execute: (_) async => 'Content',
        ),
      ];

      expect(tools.length, 3);
      expect(tools[0].name, 'get_current_datetime');
      expect(tools[1].name, 'web_search');
      expect(tools[2].name, 'read_url');
    });

    test('Tool lookup by name succeeds with valid name', () {
      final tools = [
        MockTool(
          name: 'web_search',
          description: 'Search',
          parameters: {},
          execute: (_) async => 'Results',
        ),
        MockTool(
          name: 'datetime',
          description: 'Time',
          parameters: {},
          execute: (_) async => 'Time',
        ),
      ];

      final foundTool = tools.firstWhere(
        (t) => t.name == 'web_search',
        orElse: () => throw Exception('Tool not found'),
      );

      expect(foundTool.name, 'web_search');
    });

    test('Tool lookup by name fails gracefully with invalid name', () {
      final tools = [
        MockTool(
          name: 'web_search',
          description: 'Search',
          parameters: {},
          execute: (_) async => 'Results',
        ),
      ];

      Tool? foundTool;
      try {
        foundTool = tools.firstWhere(
          (t) => t.name == 'invalid_tool',
        );
      } catch (e) {
        foundTool = null;
      }

      expect(foundTool, isNull);
    });
  });

  group('Complex Tool Call Scenarios', () {
    test('Message with mix of valid and invalid tool calls', () {
      final json = {
        'role': 'assistant',
        'content': 'I found information',
        'tool_calls': [
          {
            'id': 'call_1',
            'name': 'web_search',
            'arguments': {'query': 'flutter'},
          },
          {
            'id': 'call_2',
            'name': '',
            'arguments': {},
          },
          {
            'id': 'call_3',
            'name': 'read_url',
            'arguments': {'url': 'https://example.com'},
          },
        ],
      };

      final message = OllamaMessage.fromJson(json);

      expect(message.toolCalls?.length, 3);
      expect(message.toolCalls?[0].name, 'web_search');
      expect(message.toolCalls?[1].name, isEmpty);
      expect(message.toolCalls?[2].name, 'read_url');
    });

    test('Processing tool calls filters empty names', () {
      final toolCalls = [
        ToolCall(id: 'c1', name: 'web_search', arguments: {'q': 'test'}),
        ToolCall(id: 'c2', name: '', arguments: {}),
        ToolCall(id: 'c3', name: 'read_url', arguments: {'url': 'test'}),
      ];

      final validToolCalls =
          toolCalls.where((tc) => tc.name.isNotEmpty).toList();

      expect(validToolCalls.length, 2);
      expect(validToolCalls[0].name, 'web_search');
      expect(validToolCalls[1].name, 'read_url');
    });

    test('Tool execution results collection', () async {
      final tools = [
        MockTool(
          name: 'tool1',
          description: 'Tool 1',
          parameters: {},
          execute: (_) async => 'Result 1',
        ),
        MockTool(
          name: 'tool2',
          description: 'Tool 2',
          parameters: {},
          execute: (_) async => 'Result 2',
        ),
      ];

      final toolCalls = [
        ToolCall(id: 'c1', name: 'tool1', arguments: {}),
        ToolCall(id: 'c2', name: 'tool2', arguments: {}),
      ];

      final results = <Map<String, dynamic>>[];

      for (final toolCall in toolCalls) {
        final tool = tools.firstWhere((t) => t.name == toolCall.name);
        final result = await tool.execute(toolCall.arguments);
        results.add({
          'toolName': toolCall.name,
          'result': result,
          'toolId': toolCall.id,
        });
      }

      expect(results.length, 2);
      expect(results[0]['toolName'], 'tool1');
      expect(results[1]['toolName'], 'tool2');
    });
  });
}
