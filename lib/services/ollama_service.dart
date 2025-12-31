import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Represents an Ollama model.
class OllamaModel {
  final String name;
  final String? modifiedAt;
  final int? size;
  final String? digest;
  final Map<String, dynamic>? details;

  const OllamaModel({
    required this.name,
    this.modifiedAt,
    this.size,
    this.digest,
    this.details,
  });

  factory OllamaModel.fromJson(Map<String, dynamic> json) {
    return OllamaModel(
      name: json['name'] as String,
      modifiedAt: json['modified_at'] as String?,
      size: json['size'] as int?,
      digest: json['digest'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Returns the model family (e.g., "llama3.2" from "llama3.2:latest").
  String get family => name.split(':').first;

  /// Returns the tag (e.g., "latest" from "llama3.2:latest").
  String get tag => name.contains(':') ? name.split(':').last : 'latest';

  /// Returns a human-readable size string.
  String get sizeFormatted {
    if (size == null) return 'Unknown';
    final gb = size! / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    final mb = size! / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  /// Returns the parameter count if available (e.g., "8B").
  String? get parameterCount {
    return details?['parameter_size'] as String?;
  }
}

/// Represents the connection configuration for Ollama.
class OllamaConnection {
  final String host;
  final int port;
  final bool useHttps;
  final String? name;

  const OllamaConnection({
    required this.host,
    this.port = 11434,
    this.useHttps = false,
    this.name,
  });

  String get baseUrl => '${useHttps ? 'https' : 'http'}://$host:$port';

  factory OllamaConnection.fromJson(Map<String, dynamic> json) {
    return OllamaConnection(
      host: json['host'] as String,
      port: json['port'] as int? ?? 11434,
      useHttps: json['useHttps'] as bool? ?? false,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'useHttps': useHttps,
      'name': name,
    };
  }

  OllamaConnection copyWith({
    String? host,
    int? port,
    bool? useHttps,
    String? name,
  }) {
    return OllamaConnection(
      host: host ?? this.host,
      port: port ?? this.port,
      useHttps: useHttps ?? this.useHttps,
      name: name ?? this.name,
    );
  }
}

/// Exception thrown when Ollama API request fails.
class OllamaException implements Exception {
  final String message;
  final int? statusCode;

  const OllamaException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'OllamaException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Service for interacting with the Ollama API.
class OllamaService {
  final http.Client _client;
  OllamaConnection? _connection;

  OllamaService({http.Client? client}) : _client = client ?? http.Client();

  /// Gets the current connection configuration.
  OllamaConnection? get connection => _connection;

  /// Sets the connection configuration.
  void setConnection(OllamaConnection connection) {
    _connection = connection;
  }

  /// Gets the base URL for API requests.
  String get _baseUrl {
    if (_connection == null) {
      throw const OllamaException('No connection configured');
    }
    return _connection!.baseUrl;
  }

  /// Tests the connection to Ollama.
  ///
  /// Returns `true` if connection is successful.
  Future<bool> testConnection([OllamaConnection? connection]) async {
    final url = connection?.baseUrl ?? _baseUrl;
    try {
      final response = await _client
          .get(Uri.parse('$url/api/tags'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Lists all available models on the Ollama instance.
  Future<List<OllamaModel>> listModels() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/api/tags'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final models = data['models'] as List<dynamic>? ?? [];
        return models
            .map((m) => OllamaModel.fromJson(m as Map<String, dynamic>))
            .toList();
      } else {
        throw OllamaException('Failed to list models', response.statusCode);
      }
    } on OllamaException {
      rethrow;
    } catch (e) {
      throw OllamaException('Connection error: $e');
    }
  }

  /// Gets information about a specific model.
  Future<Map<String, dynamic>> showModel(String modelName) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/show'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': modelName}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw OllamaException('Failed to show model', response.statusCode);
      }
    } catch (e) {
      throw OllamaException('Error getting model info: $e');
    }
  }

  /// Sends a chat message and returns the complete response.
  ///
  /// Use [sendChatStream] for streaming responses.
  /// Supports tool calling when [tools] is provided.
  Future<String> sendChat({
    required String model,
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  }) async {
    try {
      final body = {
        'model': model,
        'messages': messages,
        'stream': false,
        if (options != null) 'options': options,
        if (tools != null && tools.isNotEmpty) 'tools': tools,
      };
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final message = data['message'] as Map<String, dynamic>?;
        return message?['content'] as String? ?? '';
      } else {
        throw OllamaException('Chat request failed', response.statusCode);
      }
    } catch (e) {
      throw OllamaException('Error sending chat: $e');
    }
  }

  /// Sends a chat message and returns a stream of response chunks.
  ///
  /// Each chunk contains partial content that should be appended
  /// to build the complete response.
  /// Supports tool calling when [tools] is provided.
  Stream<Map<String, dynamic>> sendChatStream({
    required String model,
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  }) async* {
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/api/chat'));
      request.headers['Content-Type'] = 'application/json';
      
      final body = {
        'model': model,
        'messages': messages,
        'stream': true,
        if (options != null) 'options': options,
        if (tools != null && tools.isNotEmpty) 'tools': tools,
      };
      
      request.body = jsonEncode(body);

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw OllamaException(
            'Chat request failed', streamedResponse.statusCode);
      }

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        // Handle multiple JSON objects per chunk (newline-delimited)
        final lines = chunk.split('\n').where((line) => line.isNotEmpty);

        for (final line in lines) {
          try {
            final data = jsonDecode(line) as Map<String, dynamic>;
            yield data;

            // Check if this is the final message
            if (data['done'] == true) {
              return;
            }
          } catch (e) {
            // Skip malformed JSON lines
            continue;
          }
        }
      }
    } catch (e) {
      throw OllamaException('Error in chat stream: $e');
    }
  }

  /// Generates a completion (non-chat format).
  Future<String> generate({
    required String model,
    required String prompt,
    String? system,
    Map<String, dynamic>? options,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'prompt': prompt,
          if (system != null) 'system': system,
          'stream': false,
          if (options != null) 'options': options,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['response'] as String? ?? '';
      } else {
        throw OllamaException('Generate request failed', response.statusCode);
      }
    } catch (e) {
      throw OllamaException('Error generating: $e');
    }
  }

  /// Pulls (downloads) a model from the Ollama library.
  ///
  /// Returns a stream of progress updates.
  Stream<Map<String, dynamic>> pullModel(String modelName) async* {
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/api/pull'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'name': modelName, 'stream': true});

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw OllamaException(
            'Pull request failed', streamedResponse.statusCode);
      }

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n').where((line) => line.isNotEmpty);

        for (final line in lines) {
          try {
            final data = jsonDecode(line) as Map<String, dynamic>;
            yield data;
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      throw OllamaException('Error pulling model: $e');
    }
  }

  /// Deletes a model from the Ollama instance.
  Future<void> deleteModel(String modelName) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/api/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': modelName}),
      );

      if (response.statusCode != 200) {
        throw OllamaException('Delete request failed', response.statusCode);
      }
    } catch (e) {
      throw OllamaException('Error deleting model: $e');
    }
  }

  /// Disposes of the HTTP client.
  void dispose() {
    _client.close();
  }
}
