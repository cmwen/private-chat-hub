import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/tool_models.dart';

void main() {
  group('Tool', () {
    test('should create tool with required fields', () {
      const tool = Tool(
        name: 'test_tool',
        description: 'A test tool',
        parameters: {'type': 'object'},
      );

      expect(tool.name, 'test_tool');
      expect(tool.description, 'A test tool');
      expect(tool.parameters['type'], 'object');
    });

    test('should convert to Ollama format', () {
      const tool = Tool(
        name: 'web_search',
        description: 'Search the web',
        parameters: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
        },
      );

      final ollamaFormat = tool.toOllamaFormat();
      expect(ollamaFormat['type'], 'function');
      expect(ollamaFormat['function']['name'], 'web_search');
      expect(ollamaFormat['function']['description'], 'Search the web');
    });

    test('should serialize to and from JSON', () {
      const tool = Tool(
        name: 'test_tool',
        description: 'Test description',
        parameters: {'type': 'object'},
      );

      final json = tool.toJson();
      final restored = Tool.fromJson(json);

      expect(restored.name, tool.name);
      expect(restored.description, tool.description);
    });
  });

  group('ToolCall', () {
    test('should create tool call with required fields', () {
      final toolCall = ToolCall(
        id: 'call-1',
        toolName: 'web_search',
        arguments: {'query': 'test'},
        createdAt: DateTime.now(),
      );

      expect(toolCall.id, 'call-1');
      expect(toolCall.toolName, 'web_search');
      expect(toolCall.status, ToolCallStatus.pending);
    });

    test('should copy with updated status', () {
      final toolCall = ToolCall(
        id: 'call-1',
        toolName: 'web_search',
        arguments: {'query': 'test'},
        createdAt: DateTime.now(),
      );

      final updated = toolCall.copyWith(status: ToolCallStatus.success);
      expect(updated.status, ToolCallStatus.success);
      expect(updated.id, toolCall.id);
    });

    test('should serialize to and from JSON', () {
      final toolCall = ToolCall(
        id: 'call-1',
        toolName: 'web_search',
        arguments: {'query': 'test'},
        status: ToolCallStatus.success,
        createdAt: DateTime(2026, 1, 1),
        executionTimeMs: 500,
      );

      final json = toolCall.toJson();
      final restored = ToolCall.fromJson(json);

      expect(restored.id, toolCall.id);
      expect(restored.toolName, toolCall.toolName);
      expect(restored.status, ToolCallStatus.success);
      expect(restored.executionTimeMs, 500);
    });
  });

  group('ToolResult', () {
    test('should create successful result', () {
      const result = ToolResult(
        success: true,
        data: {'key': 'value'},
        summary: 'Test summary',
      );

      expect(result.success, true);
      expect(result.summary, 'Test summary');
    });

    test('should serialize to and from JSON', () {
      const result = ToolResult(
        success: true,
        data: 'test data',
        summary: 'Test summary',
      );

      final json = result.toJson();
      final restored = ToolResult.fromJson(json);

      expect(restored.success, true);
      expect(restored.summary, 'Test summary');
    });
  });

  group('SearchResult', () {
    test('should create search result', () {
      const result = SearchResult(
        title: 'Test Title',
        url: 'https://example.com',
        snippet: 'Test snippet',
      );

      expect(result.title, 'Test Title');
      expect(result.url, 'https://example.com');
      expect(result.snippet, 'Test snippet');
    });

    test('should serialize to and from JSON', () {
      const result = SearchResult(
        title: 'Test Title',
        url: 'https://example.com',
        snippet: 'Test snippet',
        favicon: 'https://example.com/favicon.ico',
      );

      final json = result.toJson();
      final restored = SearchResult.fromJson(json);

      expect(restored.title, result.title);
      expect(restored.url, result.url);
      expect(restored.favicon, result.favicon);
    });
  });

  group('SearchResults', () {
    test('should create search results', () {
      const results = SearchResults(
        query: 'test query',
        results: [
          SearchResult(
            title: 'Result 1',
            url: 'https://example.com/1',
            snippet: 'Snippet 1',
          ),
        ],
        searchTime: 0.5,
      );

      expect(results.query, 'test query');
      expect(results.results.length, 1);
      expect(results.searchTime, 0.5);
      expect(results.isCached, false);
    });

    test('should detect cached results', () {
      final results = SearchResults(
        query: 'test',
        results: const [],
        cachedAt: DateTime.now(),
      );

      expect(results.isCached, true);
    });

    test('should detect expired cache', () {
      final results = SearchResults(
        query: 'test',
        results: const [],
        cachedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );

      expect(results.isExpired, true);
    });

    test('should format text summary', () {
      const results = SearchResults(
        query: 'flutter widgets',
        results: [
          SearchResult(
            title: 'Flutter Widgets',
            url: 'https://flutter.dev/widgets',
            snippet: 'Learn about Flutter widgets',
          ),
        ],
      );

      final summary = results.toTextSummary();
      expect(summary.contains('flutter widgets'), true);
      expect(summary.contains('Flutter Widgets'), true);
      expect(summary.contains('https://flutter.dev/widgets'), true);
    });

    test('should serialize to and from JSON', () {
      const results = SearchResults(
        query: 'test',
        results: [
          SearchResult(
            title: 'Result',
            url: 'https://example.com',
            snippet: 'Snippet',
          ),
        ],
        searchTime: 0.5,
      );

      final json = results.toJson();
      final restored = SearchResults.fromJson(json);

      expect(restored.query, results.query);
      expect(restored.results.length, 1);
    });
  });

  group('ToolConfig', () {
    test('should create with defaults', () {
      const config = ToolConfig();
      expect(config.enabled, false);
      expect(config.webSearchEnabled, false);
      expect(config.webSearchAvailable, false);
    });

    test('should check web search availability', () {
      const config = ToolConfig(
        enabled: true,
        webSearchEnabled: true,
        jinaApiKey: 'test-key',
      );

      expect(config.webSearchAvailable, true);
    });

    test('should not be available without API key', () {
      const config = ToolConfig(
        enabled: true,
        webSearchEnabled: true,
      );

      expect(config.webSearchAvailable, false);
    });

    test('should copy with updated values', () {
      const config = ToolConfig();
      final updated = config.copyWith(enabled: true, webSearchEnabled: true);

      expect(updated.enabled, true);
      expect(updated.webSearchEnabled, true);
    });

    test('should serialize to and from JSON', () {
      const config = ToolConfig(
        enabled: true,
        webSearchEnabled: true,
        maxSearchResults: 10,
      );

      final json = config.toJson();
      final restored = ToolConfig.fromJson(json);

      expect(restored.enabled, true);
      expect(restored.webSearchEnabled, true);
      expect(restored.maxSearchResults, 10);
    });
  });

  group('AvailableTools', () {
    test('should have web search tool', () {
      expect(AvailableTools.webSearch.name, 'web_search');
      expect(AvailableTools.webSearch.description.isNotEmpty, true);
    });

    test('should have current datetime tool', () {
      expect(AvailableTools.currentDateTime.name, 'get_current_datetime');
    });

    test('should have read url tool', () {
      expect(AvailableTools.readUrl.name, 'read_url');
    });

    test('should list all tools', () {
      expect(AvailableTools.all.length, 3);
    });

    test('should get tool by name', () {
      final tool = AvailableTools.getByName('web_search');
      expect(tool.name, 'web_search');
    });

    test('should throw for unknown tool', () {
      expect(
        () => AvailableTools.getByName('unknown'),
        throwsArgumentError,
      );
    });
  });
}
