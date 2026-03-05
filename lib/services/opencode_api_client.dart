import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:private_chat_hub/models/opencode_connection.dart';
import 'package:private_chat_hub/models/opencode_models.dart';

/// Low-level HTTP client for the OpenCode server API.
class OpenCodeApiClient {
  OpenCodeConnection? _connection;
  http.Client? _httpClient;

  /// Timeout for regular API requests.
  Duration timeout = const Duration(seconds: 30);

  /// Set the active connection.
  void setConnection(OpenCodeConnection connection) {
    _connection = connection;
    _httpClient?.close();
    _httpClient = http.Client();
  }

  /// Clear the active connection.
  void clearConnection() {
    _connection = null;
    _httpClient?.close();
    _httpClient = null;
  }

  /// The current connection, if any.
  OpenCodeConnection? get connection => _connection;

  /// Base URL for API requests.
  String? get baseUrl => _connection?.url;

  /// Build auth headers for HTTP basic auth.
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_connection?.hasAuth == true) {
      final username = _connection!.username ?? 'opencode';
      final password = _connection!.password!;
      final credentials = base64Encode(utf8.encode('$username:$password'));
      headers['Authorization'] = 'Basic $credentials';
    }
    return headers;
  }

  /// Check server health.
  Future<bool> checkHealth() async {
    try {
      final response = await _get('/global/health');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['healthy'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get server version.
  Future<String?> getVersion() async {
    try {
      final response = await _get('/global/health');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['version'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// List all providers with their models.
  Future<OpenCodeProviderResponse> getProviders() async {
    final response = await _get('/provider');
    if (response.statusCode != 200) {
      throw OpenCodeApiException(
        'Failed to fetch providers',
        response.statusCode,
        response.body,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return OpenCodeProviderResponse.fromJson(body);
  }

  /// Create a new session.
  Future<Map<String, dynamic>> createSession({String? title}) async {
    final response = await _post('/session', body: {
      if (title != null) 'title': title,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw OpenCodeApiException(
        'Failed to create session',
        response.statusCode,
        response.body,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Send a message to a session and wait for response.
  Future<Map<String, dynamic>> sendMessage(
    String sessionId, {
    required String text,
    String? providerModelId,
  }) async {
    final parts = [
      {'type': 'text', 'text': text},
    ];

    final body = <String, dynamic>{'parts': parts};
    if (providerModelId != null) {
      body['model'] = buildModelSelection(providerModelId);
    }

    final response = await _post(
      '/session/$sessionId/message',
      body: body,
      longTimeout: true,
    );
    if (response.statusCode != 200) {
      throw OpenCodeApiException(
        'Failed to send message',
        response.statusCode,
        response.body,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Send a message asynchronously (returns immediately).
  Future<void> sendMessageAsync(
    String sessionId, {
    required String text,
    String? providerModelId,
  }) async {
    final parts = [
      {'type': 'text', 'text': text},
    ];

    final body = <String, dynamic>{'parts': parts};
    if (providerModelId != null) {
      body['model'] = buildModelSelection(providerModelId);
    }

    final response = await _post(
      '/session/$sessionId/prompt_async',
      body: body,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw OpenCodeApiException(
        'Failed to send async message',
        response.statusCode,
        response.body,
      );
    }
  }

  /// Abort a running session.
  Future<void> abortSession(String sessionId) async {
    await _post('/session/$sessionId/abort', body: {});
  }

  /// Delete a session.
  Future<void> deleteSession(String sessionId) async {
    final url = Uri.parse('$baseUrl/session/$sessionId');
    final response = await _httpClient!.delete(url, headers: _headers);
    if (response.statusCode != 200) {
      throw OpenCodeApiException(
        'Failed to delete session',
        response.statusCode,
        response.body,
      );
    }
  }

  /// Open an SSE stream for events.
  /// Returns a stream of parsed SSE events.
  Stream<OpenCodeSSEEvent> eventStream() async* {
    if (_connection == null) {
      throw OpenCodeApiException('No connection configured', 0);
    }

    final url = Uri.parse('$baseUrl/event');
    final request = http.Request('GET', url);
    request.headers.addAll({
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      if (_connection?.hasAuth == true) ...{
        'Authorization': _headers['Authorization']!,
      },
    });

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw OpenCodeApiException(
          'Failed to open event stream',
          streamedResponse.statusCode,
        );
      }

      String buffer = '';
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // Parse SSE events from buffer
        while (buffer.contains('\n\n')) {
          final eventEnd = buffer.indexOf('\n\n');
          final eventText = buffer.substring(0, eventEnd);
          buffer = buffer.substring(eventEnd + 2);

          final event = _parseSSEEvent(eventText);
          if (event != null) {
            yield event;
          }
        }
      }
    } finally {
      client.close();
    }
  }

  /// Parse a single SSE event from text.
  OpenCodeSSEEvent? _parseSSEEvent(String text) {
    String? eventType;
    String? data;

    for (final line in text.split('\n')) {
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        data = line.substring(5).trim();
      }
    }

    if (data == null) return null;

    Map<String, dynamic>? properties;
    try {
      properties = jsonDecode(data) as Map<String, dynamic>?;
    } catch (_) {
      // Non-JSON data
    }

    return OpenCodeSSEEvent(
      type: eventType ?? 'unknown',
      data: data,
      properties: properties,
    );
  }

  // ── HTTP helpers ───────────────────────────────────────────────

  Future<http.Response> _get(String path) async {
    _ensureConnection();
    final url = Uri.parse('$baseUrl$path');
    return _httpClient!.get(url, headers: _headers).timeout(timeout);
  }

  Future<http.Response> _post(
    String path, {
    Map<String, dynamic>? body,
    bool longTimeout = false,
  }) async {
    _ensureConnection();
    final url = Uri.parse('$baseUrl$path');
    final requestTimeout =
        longTimeout ? const Duration(minutes: 5) : timeout;
    return _httpClient!
        .post(url, headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(requestTimeout);
  }

  void _ensureConnection() {
    if (_connection == null || _httpClient == null) {
      throw OpenCodeApiException('No connection configured', 0);
    }
  }

  /// Build OpenCode `model` payload from `provider/model` or raw model IDs.
  static Map<String, dynamic> buildModelSelection(String providerModelId) {
    final slashIndex = providerModelId.indexOf('/');
    if (slashIndex > 0 && slashIndex < providerModelId.length - 1) {
      return {
        'providerID': providerModelId.substring(0, slashIndex),
        'modelID': providerModelId.substring(slashIndex + 1),
      };
    }
    return {'modelID': providerModelId};
  }

  /// Dispose of resources.
  void dispose() {
    _httpClient?.close();
    _httpClient = null;
  }
}

/// SSE event from the OpenCode server.
class OpenCodeSSEEvent {
  final String type;
  final String data;
  final Map<String, dynamic>? properties;

  const OpenCodeSSEEvent({
    required this.type,
    required this.data,
    this.properties,
  });
}

/// Exception thrown by OpenCode API calls.
class OpenCodeApiException implements Exception {
  final String message;
  final int statusCode;
  final String? responseBody;

  const OpenCodeApiException(this.message, this.statusCode, [this.responseBody]);

  @override
  String toString() {
    final buffer = StringBuffer('OpenCodeApiException($statusCode): $message');
    if (responseBody != null && responseBody!.trim().isNotEmpty) {
      buffer..write(' - ')..write(responseBody!.trim());
    }
    return buffer.toString();
  }
}
