/// Represents a tool/function that can be called by the LLM.
class Tool {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const Tool({
    required this.name,
    required this.description,
    required this.parameters,
  });

  /// Converts tool to Ollama API format.
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
      parameters: json['parameters'] as Map<String, dynamic>,
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

/// Represents a tool call made by the LLM.
class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      name: json['name'] as String,
      arguments: json['arguments'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arguments': arguments,
    };
  }
}

/// Represents the result of a tool call.
class ToolResult {
  final String toolCallId;
  final String content;
  final bool isError;

  const ToolResult({
    required this.toolCallId,
    required this.content,
    this.isError = false,
  });

  factory ToolResult.fromJson(Map<String, dynamic> json) {
    return ToolResult(
      toolCallId: json['toolCallId'] as String,
      content: json['content'] as String,
      isError: json['isError'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toolCallId': toolCallId,
      'content': content,
      'isError': isError,
    };
  }

  /// Converts to Ollama API message format.
  Map<String, dynamic> toOllamaMessage() {
    return {
      'role': 'tool',
      'content': content,
      'tool_call_id': toolCallId,
    };
  }
}

/// Web search tool definition.
class WebSearchTool extends Tool {
  WebSearchTool()
      : super(
          name: 'web_search',
          description:
              'Search the internet for current information, news, facts, or answers to questions. Use this when you need up-to-date information or when the user asks about recent events.',
          parameters: {
            'type': 'object',
            'properties': {
              'query': {
                'type': 'string',
                'description':
                    'The search query to look up on the internet. Be specific and clear.',
              },
            },
            'required': ['query'],
          },
        );
}
