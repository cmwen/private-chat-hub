import 'dart:async';
import 'package:private_chat_hub/models/tool_models.dart';
import 'package:private_chat_hub/services/jina_search_service.dart';
import 'package:uuid/uuid.dart';

/// Service for executing tool calls from AI models.
///
/// Handles dispatching tool calls to appropriate handlers and
/// returning results back to the model.
class ToolExecutorService {
  final JinaSearchService? _jinaService;
  final ToolConfig config;

  ToolExecutorService({
    JinaSearchService? jinaService,
    this.config = const ToolConfig(),
  }) : _jinaService = jinaService;

  /// Gets the list of available tools based on configuration.
  List<Tool> getAvailableTools() {
    final tools = <Tool>[];

    // Always available
    tools.add(AvailableTools.currentDateTime);

    // Requires API key
    if (config.webSearchAvailable) {
      tools.add(AvailableTools.webSearch);
      tools.add(AvailableTools.readUrl);
    }

    return tools;
  }

  /// Gets tool definitions in Ollama format.
  List<Map<String, dynamic>> getToolsForOllama() {
    return getAvailableTools().map((t) => t.toOllamaFormat()).toList();
  }

  /// Executes a tool call and returns the result.
  ///
  /// Parses the tool call from the model response and dispatches
  /// to the appropriate handler.
  Future<ToolCall> executeToolCall({
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    final startTime = DateTime.now();
    final toolCallId = const Uuid().v4();

    var toolCall = ToolCall(
      id: toolCallId,
      toolName: toolName,
      arguments: arguments,
      status: ToolCallStatus.executing,
      createdAt: startTime,
    );

    try {
      final result = await _dispatchToolCall(toolName, arguments);
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      toolCall = toolCall.copyWith(
        status: ToolCallStatus.success,
        result: result,
        executionTimeMs: executionTime,
      );
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      toolCall = toolCall.copyWith(
        status: ToolCallStatus.failed,
        errorMessage: e.toString(),
        executionTimeMs: executionTime,
      );
    }

    return toolCall;
  }

  /// Dispatches a tool call to the appropriate handler.
  Future<ToolResult> _dispatchToolCall(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'web_search':
        return _handleWebSearch(arguments);
      case 'get_current_datetime':
        return _handleGetDateTime(arguments);
      case 'read_url':
        return _handleReadUrl(arguments);
      default:
        throw Exception('Unknown tool: $toolName');
    }
  }

  /// Handles web_search tool calls.
  Future<ToolResult> _handleWebSearch(Map<String, dynamic> arguments) async {
    if (_jinaService == null) {
      return const ToolResult(
        success: false,
        summary:
            '⚙️ Web search is not configured. Please:\n1. Get a free API key at https://jina.ai/?sui=apikey\n2. Add it in Settings > Tools Configuration\n3. Enable "Web Search" toggle\n4. Restart the app',
      );
    }

    final query = arguments['query'] as String?;
    if (query == null || query.trim().isEmpty) {
      return const ToolResult(
        success: false,
        summary: 'Search query is required.',
      );
    }

    final numResults =
        (arguments['num_results'] as int?) ?? config.maxSearchResults;

    try {
      final results = await _jinaService.search(
        query,
        limit: numResults.clamp(1, 10),
      );

      return ToolResult(
        success: true,
        data: results.toJson(),
        summary: results.toTextSummary(),
      );
    } on JinaException catch (e) {
      if (e.isAuthError) {
        return const ToolResult(
          success: false,
          summary:
              '❌ Invalid Jina API key. Please check your settings and ensure the key is correct.',
        );
      }
      if (e.isRateLimited) {
        return const ToolResult(
          success: false,
          summary:
              '⏱️ Search rate limit exceeded. Please wait a moment and try again.',
        );
      }
      if (e.statusCode == 404) {
        return const ToolResult(
          success: false,
          summary:
              '❌ Jina API endpoint not accessible. Your API key may not have web search enabled or subscription is invalid. Check https://jina.ai/?sui=apikey',
        );
      }
      if (e.isNetworkError) {
        return ToolResult(
          success: false,
          summary:
              '🌐 Network error: ${e.message}\n\nPlease check your internet connection and try again.',
        );
      }
      return ToolResult(
        success: false,
        summary:
            '❌ Search failed: ${e.message}\n\nTroubleshooting: Check your Jina API key in Settings > Tools Configuration',
      );
    }
  }

  /// Handles get_current_datetime tool calls.
  Future<ToolResult> _handleGetDateTime(Map<String, dynamic> arguments) async {
    final timezone = arguments['timezone'] as String?;
    final now = DateTime.now();

    String formattedTime;
    if (timezone == 'UTC') {
      formattedTime = now.toUtc().toIso8601String();
    } else {
      // For simplicity, we only support local time and UTC
      // A more complete implementation would use a timezone package
      formattedTime = now.toIso8601String();
    }

    final dayOfWeek = _getDayOfWeek(now.weekday);

    return ToolResult(
      success: true,
      data: {
        'datetime': formattedTime,
        'dayOfWeek': dayOfWeek,
        'timestamp': now.millisecondsSinceEpoch,
      },
      summary: 'Current date and time: $dayOfWeek, $formattedTime',
    );
  }

  /// Handles read_url tool calls.
  Future<ToolResult> _handleReadUrl(Map<String, dynamic> arguments) async {
    if (_jinaService == null) {
      return const ToolResult(
        success: false,
        summary:
            'URL reading is not configured. Please add a Jina API key in settings.',
      );
    }

    final url = arguments['url'] as String?;
    if (url == null || url.trim().isEmpty) {
      return const ToolResult(success: false, summary: 'URL is required.');
    }

    try {
      final content = await _jinaService.fetchContent(url);

      // Truncate very long content
      final truncatedContent = content.length > 10000
          ? '${content.substring(0, 10000)}\n\n[Content truncated - showing first 10,000 characters]'
          : content;

      return ToolResult(
        success: true,
        data: {
          'url': url,
          'content': truncatedContent,
          'contentLength': content.length,
        },
        summary: truncatedContent,
      );
    } on JinaException catch (e) {
      return ToolResult(
        success: false,
        summary: 'Failed to read URL: ${e.message}',
      );
    }
  }

  /// Gets the day of week name.
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  /// Parses tool calls from Ollama response.
  ///
  /// Returns a list of tool calls found in the response,
  /// or an empty list if no tool calls were made.
  List<Map<String, dynamic>> parseToolCallsFromResponse(
    Map<String, dynamic> response,
  ) {
    final message = response['message'] as Map<String, dynamic>?;
    if (message == null) return [];

    final toolCalls = message['tool_calls'] as List<dynamic>?;
    if (toolCalls == null || toolCalls.isEmpty) return [];

    return toolCalls
        .map((tc) {
          final function = tc['function'] as Map<String, dynamic>?;
          if (function == null) return <String, dynamic>{};

          return <String, dynamic>{
            'name': function['name'] as String? ?? '',
            'arguments': function['arguments'] as Map<String, dynamic>? ?? {},
          };
        })
        .where((tc) => tc.isNotEmpty)
        .toList();
  }

  /// Checks if a response contains tool calls.
  bool hasToolCalls(Map<String, dynamic> response) {
    final message = response['message'] as Map<String, dynamic>?;
    if (message == null) return false;

    final toolCalls = message['tool_calls'] as List<dynamic>?;
    return toolCalls != null && toolCalls.isNotEmpty;
  }
}
