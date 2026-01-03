import 'dart:convert';

/// Represents a tool that can be called by an AI model.
class Tool {
  /// Unique identifier for the tool.
  final String name;

  /// Human-readable description of what the tool does.
  final String description;

  /// JSON schema defining the parameters this tool accepts.
  final Map<String, dynamic> parameters;

  const Tool({
    required this.name,
    required this.description,
    required this.parameters,
  });

  /// Converts to Ollama API tool format.
  Map<String, dynamic> toOllamaFormat() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': parameters,
      },
    };
  }

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      name: json['name'] as String,
      description: json['description'] as String,
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'parameters': parameters,
    };
  }
}

/// Status of a tool call execution.
enum ToolCallStatus {
  pending,
  executing,
  success,
  failed,
}

/// Represents a tool call made by an AI model.
class ToolCall {
  /// Unique identifier for this tool call.
  final String id;

  /// Name of the tool being called.
  final String toolName;

  /// Arguments passed to the tool.
  final Map<String, dynamic> arguments;

  /// Status of the tool call execution.
  final ToolCallStatus status;

  /// Result of the tool call (if completed).
  final ToolResult? result;

  /// Error message if the tool call failed.
  final String? errorMessage;

  /// When the tool call was initiated.
  final DateTime createdAt;

  /// How long the tool call took to execute (in milliseconds).
  final int? executionTimeMs;

  const ToolCall({
    required this.id,
    required this.toolName,
    required this.arguments,
    this.status = ToolCallStatus.pending,
    this.result,
    this.errorMessage,
    required this.createdAt,
    this.executionTimeMs,
  });

  ToolCall copyWith({
    String? id,
    String? toolName,
    Map<String, dynamic>? arguments,
    ToolCallStatus? status,
    ToolResult? result,
    String? errorMessage,
    DateTime? createdAt,
    int? executionTimeMs,
  }) {
    return ToolCall(
      id: id ?? this.id,
      toolName: toolName ?? this.toolName,
      arguments: arguments ?? this.arguments,
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
    );
  }

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      toolName: json['toolName'] as String,
      arguments: json['arguments'] as Map<String, dynamic>? ?? {},
      status: ToolCallStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ToolCallStatus.pending,
      ),
      result: json['result'] != null
          ? ToolResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      executionTimeMs: json['executionTimeMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toolName': toolName,
      'arguments': arguments,
      'status': status.name,
      'result': result?.toJson(),
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'executionTimeMs': executionTimeMs,
    };
  }

  /// Creates a tool response message for Ollama.
  Map<String, dynamic> toOllamaToolResponse() {
    return {
      'role': 'tool',
      'content': result != null
          ? jsonEncode(result!.toJson())
          : errorMessage ?? 'No result',
    };
  }
}

/// Result of a tool execution.
class ToolResult {
  /// Whether the tool execution was successful.
  final bool success;

  /// The data returned by the tool.
  final dynamic data;

  /// Human-readable summary of the result.
  final String? summary;

  const ToolResult({
    required this.success,
    this.data,
    this.summary,
  });

  factory ToolResult.fromJson(Map<String, dynamic> json) {
    return ToolResult(
      success: json['success'] as bool,
      data: json['data'],
      summary: json['summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'summary': summary,
    };
  }
}

/// A single search result from web search.
class SearchResult {
  /// Title of the search result.
  final String title;

  /// URL of the search result.
  final String url;

  /// Snippet/description of the content.
  final String snippet;

  /// Favicon URL (if available).
  final String? favicon;

  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.favicon,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      snippet: json['snippet'] as String? ?? json['description'] as String? ?? '',
      favicon: json['favicon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'snippet': snippet,
      'favicon': favicon,
    };
  }

  @override
  String toString() {
    return '[$title]($url)\n$snippet';
  }
}

/// Collection of search results.
class SearchResults {
  /// The original search query.
  final String query;

  /// List of search results.
  final List<SearchResult> results;

  /// Time taken for the search (in seconds).
  final double? searchTime;

  /// When the results were cached.
  final DateTime? cachedAt;

  const SearchResults({
    required this.query,
    required this.results,
    this.searchTime,
    this.cachedAt,
  });

  /// Whether these results are from cache.
  bool get isCached => cachedAt != null;

  /// Whether the cached results have expired (older than 24 hours).
  bool get isExpired {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt!).inHours > 24;
  }

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    final resultsJson = json['results'] as List<dynamic>? ??
        json['data'] as List<dynamic>? ??
        [];
    return SearchResults(
      query: json['query'] as String? ?? '',
      results: resultsJson
          .map((r) => SearchResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      searchTime: (json['searchTime'] as num?)?.toDouble(),
      cachedAt: json['cachedAt'] != null
          ? DateTime.parse(json['cachedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'results': results.map((r) => r.toJson()).toList(),
      'searchTime': searchTime,
      'cachedAt': cachedAt?.toIso8601String(),
    };
  }

  /// Formats results as a text summary for the AI model.
  String toTextSummary() {
    if (results.isEmpty) {
      return 'No search results found for "$query".';
    }

    final buffer = StringBuffer();
    buffer.writeln('Web search results for "$query":');
    buffer.writeln();

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('${i + 1}. ${result.title}');
      buffer.writeln('   URL: ${result.url}');
      buffer.writeln('   ${result.snippet}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}

/// Configuration for tool calling.
class ToolConfig {
  /// Whether tool calling is enabled.
  final bool enabled;

  /// Whether web search is enabled.
  final bool webSearchEnabled;

  /// Jina API key for web search.
  final String? jinaApiKey;

  /// Maximum number of search results to return.
  final int maxSearchResults;

  /// Whether to cache search results.
  final bool cacheSearchResults;

  const ToolConfig({
    this.enabled = false,
    this.webSearchEnabled = false,
    this.jinaApiKey,
    this.maxSearchResults = 5,
    this.cacheSearchResults = true,
  });

  /// Whether web search is available (enabled and has API key).
  bool get webSearchAvailable =>
      enabled && webSearchEnabled && jinaApiKey != null && jinaApiKey!.isNotEmpty;

  ToolConfig copyWith({
    bool? enabled,
    bool? webSearchEnabled,
    String? jinaApiKey,
    int? maxSearchResults,
    bool? cacheSearchResults,
  }) {
    return ToolConfig(
      enabled: enabled ?? this.enabled,
      webSearchEnabled: webSearchEnabled ?? this.webSearchEnabled,
      jinaApiKey: jinaApiKey ?? this.jinaApiKey,
      maxSearchResults: maxSearchResults ?? this.maxSearchResults,
      cacheSearchResults: cacheSearchResults ?? this.cacheSearchResults,
    );
  }

  factory ToolConfig.fromJson(Map<String, dynamic> json) {
    return ToolConfig(
      enabled: json['enabled'] as bool? ?? false,
      webSearchEnabled: json['webSearchEnabled'] as bool? ?? false,
      jinaApiKey: json['jinaApiKey'] as String?,
      maxSearchResults: json['maxSearchResults'] as int? ?? 5,
      cacheSearchResults: json['cacheSearchResults'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'webSearchEnabled': webSearchEnabled,
      'jinaApiKey': jinaApiKey,
      'maxSearchResults': maxSearchResults,
      'cacheSearchResults': cacheSearchResults,
    };
  }
}

/// Predefined tools available in the app.
class AvailableTools {
  AvailableTools._();

  /// Web search tool definition.
  static const Tool webSearch = Tool(
    name: 'web_search',
    description:
        'Search the web for current information. Use this when you need up-to-date information, '
        'facts, news, or when the user asks about recent events or topics that may have changed '
        'since your training data.',
    parameters: {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description': 'The search query to find relevant information',
        },
        'num_results': {
          'type': 'integer',
          'description': 'Number of results to return (1-10, default 5)',
        },
      },
      'required': ['query'],
    },
  );

  /// Get current date/time tool definition.
  static const Tool currentDateTime = Tool(
    name: 'get_current_datetime',
    description:
        'Get the current date and time. Use this when you need to know the current time or date.',
    parameters: {
      'type': 'object',
      'properties': {
        'timezone': {
          'type': 'string',
          'description': 'Timezone (e.g., "UTC", "America/New_York"). Default is local time.',
        },
      },
    },
  );

  /// Read URL content tool definition.
  static const Tool readUrl = Tool(
    name: 'read_url',
    description:
        'Fetch and read the content of a web page. Use this when you need to read specific '
        'content from a URL the user provided or from search results.',
    parameters: {
      'type': 'object',
      'properties': {
        'url': {
          'type': 'string',
          'description': 'The URL to fetch and read',
        },
      },
      'required': ['url'],
    },
  );

  /// All available tools.
  static List<Tool> get all => [webSearch, currentDateTime, readUrl];

  /// Tools that require an API key.
    static List<Tool> get requiresApiKey => [webSearch, readUrl];

  /// Gets a tool by name.
  /// 
  /// Throws [ArgumentError] if the tool is not found.
  static Tool getByName(String name) {
    for (final tool in all) {
      if (tool.name == name) {
        return tool;
      }
    }
    throw ArgumentError('Unknown tool: $name');
  }
}
