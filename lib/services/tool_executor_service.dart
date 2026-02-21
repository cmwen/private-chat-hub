import 'dart:async';
import 'dart:math' show min;
import 'package:http/http.dart' as http;
import 'package:private_chat_hub/models/tool_models.dart';
import 'package:private_chat_hub/services/jina_search_service.dart';
import 'package:private_chat_hub/services/notification_service.dart';
import 'package:private_chat_hub/services/project_service.dart';
import 'package:private_chat_hub/services/status_service.dart';
import 'package:uuid/uuid.dart';

/// Service for executing tool calls from AI models.
///
/// Handles dispatching tool calls to appropriate handlers and
/// returning results back to the model.
class ToolExecutorService {
  static const String _userAgent = 'Mozilla/5.0 (compatible; PrivateChatHub)';
  static const int _fetchUrlMaxLength = 8000;

  final JinaSearchService? _jinaService;
  final ToolConfig config;
  final ProjectService? _projectService;

  /// The ID of the project currently being used in the conversation.
  /// Set by [setCurrentProject] before executing tools.
  String? _currentProjectId;

  ToolExecutorService({
    JinaSearchService? jinaService,
    this.config = const ToolConfig(),
    ProjectService? projectService,
  }) : _jinaService = jinaService,
       _projectService = projectService;

  /// Sets the project context for project-related tools.
  ///
  /// Should be called before executing tools for a conversation that belongs
  /// to a project. Pass `null` when the conversation has no project.
  void setCurrentProject(String? projectId) {
    _currentProjectId = projectId;
  }

  /// Gets the list of available tools based on configuration.
  List<Tool> getAvailableTools() {
    final tools = <Tool>[];

    // Always available
    tools.add(AvailableTools.currentDateTime);
    tools.add(AvailableTools.fetchUrl);
    tools.add(AvailableTools.showNotification);
    _debugLog(
      '✔ Base tools added: get_current_datetime, fetch_url, show_notification',
    );

    // Requires Jina API key
    if (config.webSearchAvailable) {
      tools.add(AvailableTools.webSearch);
      tools.add(AvailableTools.readUrl);
      _debugLog('✔ Web search tools added (Jina key present)');
    } else {
      _debugLog(
        '✗ Web search tools SKIPPED — '
        'webSearchEnabled=${config.webSearchEnabled}, '
        'hasJinaKey=${config.jinaApiKey != null && config.jinaApiKey!.isNotEmpty}',
      );
    }

    // Project tools: only available when inside a project conversation
    if (_projectService != null && _currentProjectId != null) {
      tools.add(AvailableTools.getProjectMemory);
      tools.add(AvailableTools.updateProjectMemory);
      tools.add(AvailableTools.renameProject);
      tools.add(AvailableTools.updateProjectDescription);
      _debugLog('✔ Project tools added — projectId=$_currentProjectId');
    } else {
      _debugLog(
        '✗ Project tools SKIPPED — '
        'projectService=${_projectService != null}, '
        'currentProjectId=$_currentProjectId',
      );
    }

    _debugLog(
      '📋 Final tool list (${tools.length}): ${tools.map((t) => t.name).join(', ')}',
    );
    for (final tool in tools) {
      _debugLog('  • ${tool.name}: ${tool.description.split(".").first}');
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

    _debugLog('▶ Calling tool: $toolName  args: $arguments');

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

      final preview = result.summary != null
          ? result.summary!.substring(0, min(120, result.summary!.length))
          : '(no summary)';
      _debugLog('✅ Tool "$toolName" done in ${executionTime}ms: $preview');
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      toolCall = toolCall.copyWith(
        status: ToolCallStatus.failed,
        errorMessage: e.toString(),
        executionTimeMs: executionTime,
      );

      _debugLog('❌ Tool "$toolName" failed in ${executionTime}ms: $e');
    }

    return toolCall;
  }

  /// Logs a debug message to the console and, when developer mode is active,
  /// to the in-app UI via a SnackBar.
  ///
  /// [StatusService.showTransient] is a no-op when developer mode is off,
  /// so no extra guard is needed here.
  static void _debugLog(String message) {
    // ignore: avoid_print
    print('[ToolExecutor] $message');
    StatusService().showTransient('[Tools] $message');
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
      case 'fetch_url':
        return _handleFetchUrl(arguments);
      case 'show_notification':
        return _handleShowNotification(arguments);
      case 'get_project_memory':
        return _handleGetProjectMemory(arguments);
      case 'update_project_memory':
        return _handleUpdateProjectMemory(arguments);
      case 'rename_project':
        return _handleRenameProject(arguments);
      case 'update_project_description':
        return _handleUpdateProjectDescription(arguments);
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

  /// Handles read_url tool calls (Jina-powered reader).
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

  /// Handles fetch_url tool calls using a direct HTTP request.
  ///
  /// Fetches the URL content without requiring an API key.
  /// Returns plain text extracted from the HTML response.
  Future<ToolResult> _handleFetchUrl(Map<String, dynamic> arguments) async {
    final url = arguments['url'] as String?;
    if (url == null || url.trim().isEmpty) {
      return const ToolResult(success: false, summary: 'URL is required.');
    }

    try {
      final uri = Uri.parse(url.trim());
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': _userAgent,
              'Accept': 'text/html,application/xhtml+xml,text/plain',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ToolResult(
          success: false,
          summary: 'Failed to fetch URL: HTTP ${response.statusCode}',
        );
      }

      var content = response.body;
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('html')) {
        content = _stripHtml(content);
      }

      const maxLength = _fetchUrlMaxLength;
      final truncated = content.length > maxLength
          ? '${content.substring(0, maxLength)}\n\n[Content truncated - showing first $maxLength characters]'
          : content;

      return ToolResult(
        success: true,
        data: {
          'url': url,
          'content': truncated,
          'contentLength': content.length,
        },
        summary: truncated,
      );
    } on TimeoutException {
      return const ToolResult(
        success: false,
        summary: 'Request timed out while fetching URL.',
      );
    } catch (e) {
      return ToolResult(
        success: false,
        summary: 'Failed to fetch URL: ${e.toString()}',
      );
    }
  }

  /// Handles show_notification tool calls.
  ///
  /// Triggers a system notification to alert the user.
  Future<ToolResult> _handleShowNotification(
    Map<String, dynamic> arguments,
  ) async {
    final title = arguments['title'] as String? ?? 'AI Assistant';
    final message = arguments['message'] as String?;
    if (message == null || message.trim().isEmpty) {
      return const ToolResult(
        success: false,
        summary: 'Notification message is required.',
      );
    }

    try {
      await NotificationService().showCustomNotification(
        title: title,
        message: message,
      );
      return ToolResult(
        success: true,
        data: {'title': title, 'message': message},
        summary: 'Notification sent: $title — $message',
      );
    } catch (e) {
      return ToolResult(
        success: false,
        summary: 'Failed to show notification: $e',
      );
    }
  }

  /// Handles get_project_memory tool calls.
  Future<ToolResult> _handleGetProjectMemory(
    Map<String, dynamic> arguments,
  ) async {
    final projectService = _projectService;
    final projectId = _currentProjectId;

    if (projectService == null || projectId == null) {
      return const ToolResult(
        success: false,
        summary:
            'No project context available. This tool only works within a project conversation.',
      );
    }

    final project = projectService.getProject(projectId);
    if (project == null) {
      return const ToolResult(success: false, summary: 'Project not found.');
    }

    final memory = project.instructions;
    if (memory == null || memory.isEmpty) {
      return ToolResult(
        success: true,
        data: {'name': project.name, 'instructions': null},
        summary:
            'Project "${project.name}" has no saved memory or instructions yet.',
      );
    }

    return ToolResult(
      success: true,
      data: {'name': project.name, 'instructions': memory},
      summary: 'Project "${project.name}" memory:\n\n$memory',
    );
  }

  /// Handles update_project_memory tool calls.
  Future<ToolResult> _handleUpdateProjectMemory(
    Map<String, dynamic> arguments,
  ) async {
    final projectService = _projectService;
    final projectId = _currentProjectId;

    if (projectService == null || projectId == null) {
      return const ToolResult(
        success: false,
        summary:
            'No project context available. This tool only works within a project conversation.',
      );
    }

    final instructions = arguments['instructions'] as String?;
    if (instructions == null) {
      return const ToolResult(
        success: false,
        summary: 'Instructions content is required.',
      );
    }

    final project = projectService.getProject(projectId);
    if (project == null) {
      return const ToolResult(success: false, summary: 'Project not found.');
    }

    final updatedProject = project.copyWith(instructions: instructions);
    await projectService.updateProject(updatedProject);

    return ToolResult(
      success: true,
      data: {'name': project.name, 'instructions': instructions},
      summary: 'Project "${project.name}" memory updated successfully.',
    );
  }

  /// Handles rename_project tool calls.
  Future<ToolResult> _handleRenameProject(
    Map<String, dynamic> arguments,
  ) async {
    final projectService = _projectService;
    final projectId = _currentProjectId;

    if (projectService == null || projectId == null) {
      return const ToolResult(
        success: false,
        summary:
            'No project context available. This tool only works within a project conversation.',
      );
    }

    final newName = arguments['name'] as String?;
    if (newName == null || newName.trim().isEmpty) {
      return const ToolResult(
        success: false,
        summary: 'New project name is required.',
      );
    }

    final project = projectService.getProject(projectId);
    if (project == null) {
      return const ToolResult(success: false, summary: 'Project not found.');
    }

    final oldName = project.name;
    final updatedProject = project.copyWith(name: newName.trim());
    await projectService.updateProject(updatedProject);

    return ToolResult(
      success: true,
      data: {'oldName': oldName, 'newName': newName.trim()},
      summary:
          'Project renamed from "$oldName" to "${newName.trim()}" successfully.',
    );
  }

  /// Handles update_project_description tool calls.
  Future<ToolResult> _handleUpdateProjectDescription(
    Map<String, dynamic> arguments,
  ) async {
    final projectService = _projectService;
    final projectId = _currentProjectId;

    if (projectService == null || projectId == null) {
      return const ToolResult(
        success: false,
        summary:
            'No project context available. This tool only works within a project conversation.',
      );
    }

    final newDescription = arguments['description'] as String?;
    if (newDescription == null || newDescription.trim().isEmpty) {
      return const ToolResult(
        success: false,
        summary: 'New project description is required.',
      );
    }

    final project = projectService.getProject(projectId);
    if (project == null) {
      return const ToolResult(success: false, summary: 'Project not found.');
    }

    final updatedProject = project.copyWith(description: newDescription.trim());
    await projectService.updateProject(updatedProject);

    return ToolResult(
      success: true,
      data: {'description': newDescription.trim()},
      summary: 'Project description updated to: "${newDescription.trim()}".',
    );
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

  /// Strips HTML tags from a string, returning plain text.
  String _stripHtml(String html) {
    // Remove script and style blocks (including their content)
    var text = html.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false),
      '',
    );
    // Remove all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    // Decode common HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    // Collapse whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
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
