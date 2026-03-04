# Architecture: OpenCode LLM Provider Integration

## Metadata

| Field | Value |
|---|---|
| **Document Version** | 1.0 |
| **Created** | 2025-07-15 |
| **Status** | Design Specification |
| **Author** | Architect Agent |
| **Decision ID** | ADR-007 |
| **Supersedes** | N/A |
| **Related Documents** | `ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md`, `ARCHITECTURE_DECISIONS.md` |

---

## 1. Executive Summary

This document specifies the technical architecture for adding **OpenCode** as a third LLM provider in Private Chat Hub, alongside the existing Ollama (remote) and LiteRT (on-device) backends. OpenCode is a local development server (typically running on `localhost`) that aggregates multiple cloud LLM providers (OpenAI, Anthropic, Google, etc.) behind a unified API with session-based chat, SSE streaming, and HTTP basic auth.

The design follows the established pattern set by the Ollama → LiteRT integration: a new `InferenceMode.openCode` enum value, a dedicated `OpenCodeLLMService` implementing the `LLMService` interface, a connection model, and surgical integration into `ChatService`, `UnifiedModelService`, and `InferenceConfigService`.

### Key Design Decisions Summary

| Decision | Choice | Rationale |
|---|---|---|
| Model ID prefix | `opencode:` | Follows `local:` convention for on-device models |
| Session mapping | 1:1 Conversation ↔ OpenCode Session | Natural mapping; sessions are cheap to create |
| Streaming | SSE via `GET /event` + `POST /session/:id/prompt_async` | Non-blocking; matches OpenCode's async architecture |
| Model visibility | `SharedPreferences` string set | Consistent with existing caching patterns |
| Auth storage | `SharedPreferences` (password field) | Consistent with HuggingFace token pattern |
| HTTP client | `http` package | Already a dependency; no new packages needed |
| Connection management | `OpenCodeConnectionManager` (mirrors `OllamaConnectionManager`) | Follows established pattern |

---

## 2. System Architecture Overview

### 2.1 Updated Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              UI Layer                                   │
│  ┌────────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │
│  │ Conversation   │  │ Chat Screen  │  │   Models     │  │ Settings │ │
│  │ List Screen    │  │              │  │   Screen     │  │  Screen  │ │
│  └───────┬────────┘  └──────┬───────┘  └──────┬───────┘  └────┬─────┘ │
└──────────┼──────────────────┼──────────────────┼───────────────┼───────┘
           │                  │                  │               │
┌──────────┼──────────────────┼──────────────────┼───────────────┼───────┐
│          ▼                  ▼                  ▼               ▼       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                 ChatService (Central Router)                    │   │
│  │  Routes to: Ollama | LiteRT | OpenCode based on model prefix   │   │
│  └──┬──────────────────────┬──────────────────────┬───────────────┘   │
│     │                      │                      │                   │
│     ▼                      ▼                      ▼                   │
│  ┌──────────────┐  ┌───────────────┐  ┌─────────────────────────┐    │
│  │ Ollama       │  │ OnDevice      │  │ OpenCode                │    │
│  │ LLMService   │  │ LLMService    │  │ LLMService       [NEW]  │    │
│  │              │  │               │  │                         │    │
│  │ • chatStream │  │ • LiteRT      │  │ • SSE events            │    │
│  │ • Ollama API │  │ • Platform Ch │  │ • Session-based         │    │
│  │              │  │               │  │ • Multi-provider        │    │
│  └──────┬───────┘  └───────┬───────┘  └──────────┬──────────────┘    │
│         │                  │                     │                    │
│         ▼                  ▼                     ▼                    │
│  ┌──────────────┐  ┌───────────────┐  ┌─────────────────────────┐    │
│  │ OllamaConn   │  │ LiteRT       │  │ OpenCodeConnection      │    │
│  │ Manager      │  │ PlatformCh   │  │ Manager          [NEW]  │    │
│  └──────────────┘  └───────────────┘  └─────────────────────────┘    │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │              UnifiedModelService (updated)                      │  │
│  │  Combines: Ollama models + local: models + opencode: models     │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────┐  ┌────────────────────────────────────┐  │
│  │ InferenceConfigService  │  │ OpenCodeModelVisibilityService     │  │
│  │ (updated)               │  │                           [NEW]    │  │
│  └─────────────────────────┘  └────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
```

### 2.2 Routing Logic (Updated)

The existing `ChatService` routes by **model name prefix**, not by `InferenceMode`. This is the correct and established pattern — the user selects a specific model, and the router infers the backend:

```
Model Name                  │  Route To
────────────────────────────┼──────────────────────
"llama3.2:3b"               │  Ollama (no prefix → remote)
"local:gemma3-1b"           │  LiteRT on-device
"opencode:anthropic/claude" │  OpenCode server
```

The `InferenceMode` enum only affects the **default model selection** when creating a new conversation, not the routing of an existing conversation's messages.

---

## 3. New Files to Create

### 3.1 File Inventory

```
lib/
├── models/
│   ├── opencode_connection.dart              [NEW] Connection model
│   ├── opencode_models.dart                  [NEW] API response models
│   └── opencode_model_capabilities.dart      [NEW] Capabilities registry
├── services/
│   ├── opencode_connection_manager.dart       [NEW] Connection manager
│   ├── opencode_llm_service.dart              [NEW] LLMService implementation
│   ├── opencode_api_client.dart               [NEW] Low-level HTTP + SSE client
│   └── opencode_model_visibility_service.dart [NEW] Model visibility persistence
```

### 3.2 Modified Files

```
lib/
├── services/
│   ├── llm_service.dart                       [MODIFY] Add InferenceMode.openCode
│   ├── inference_config_service.dart           [MODIFY] Add openCode mode + last model
│   ├── unified_model_service.dart              [MODIFY] Include OpenCode models
│   ├── chat_service.dart                       [MODIFY] Add OpenCode routing branch
│   └── connection_service.dart                 [MODIFY] (optional) or keep separate
├── models/
│   └── model_capability_resolver.dart          [MODIFY] Add opencode: prefix detection
├── screens/
│   └── settings_screen.dart                    [MODIFY] Add OpenCode connection config
│   └── models_screen.dart                      [MODIFY] Show OpenCode models section
├── main.dart                                   [MODIFY] Initialize OpenCode services
```

---

## 4. Data Model Definitions

### 4.1 `lib/models/opencode_connection.dart`

```dart
/// Represents a saved OpenCode server connection profile.
///
/// Mirrors [Connection] for Ollama but with OpenCode-specific fields.
/// OpenCode uses HTTP basic auth (password-only, username is empty string).
class OpenCodeConnection {
  final String id;
  final String name;
  final String host;
  final int port;
  final bool useHttps;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastConnectedAt;

  /// OpenCode server password (OPENCODE_SERVER_PASSWORD).
  /// Stored as-is; sent as HTTP basic auth (username: '', password: this).
  /// Null means no auth required.
  final String? password;

  const OpenCodeConnection({
    required this.id,
    required this.name,
    required this.host,
    this.port = 3000,
    this.useHttps = false,
    this.isDefault = false,
    required this.createdAt,
    this.lastConnectedAt,
    this.password,
  });

  /// Gets the full base URL for this connection.
  String get baseUrl => '${useHttps ? 'https' : 'http'}://$host:$port';

  /// Gets the Authorization header value for HTTP basic auth.
  /// OpenCode uses empty-string username with the server password.
  String? get authorizationHeader {
    if (password == null || password!.isEmpty) return null;
    final credentials = base64Encode(utf8.encode(':$password'));
    return 'Basic $credentials';
  }

  factory OpenCodeConnection.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  OpenCodeConnection copyWith({...});
}
```

**Design Decision:** We store `password` in `SharedPreferences` alongside other config. This is consistent with the existing `huggingFaceToken` pattern in `InferenceConfigService`. For higher security in a future release, we could migrate to `flutter_secure_storage`, but that introduces a new dependency — out of scope for this iteration.

### 4.2 `lib/models/opencode_models.dart`

These model classes map to the OpenCode REST API response shapes.

```dart
/// A provider registered in the OpenCode server (e.g., "anthropic", "openai").
class OpenCodeProvider {
  final String id;
  final String name;
  final Map<String, OpenCodeModelDef> models;

  const OpenCodeProvider({
    required this.id,
    required this.name,
    required this.models,
  });

  factory OpenCodeProvider.fromJson(Map<String, dynamic> json);
}

/// Definition of a single model within an OpenCode provider.
///
/// Maps to the rich model metadata in the OpenCode API:
/// ```json
/// { "id": "claude-sonnet-4-20250514", "name": "Claude Sonnet 4",
///   "cost": { "input": 3, "output": 15 },
///   "limit": { "context": 200000, "output": 16384 },
///   "modalities": { "input": ["text","image"], "output": ["text"] },
///   "reasoning": true, "tool_call": true }
/// ```
class OpenCodeModelDef {
  /// Model ID within the provider (e.g., "claude-sonnet-4-20250514").
  final String id;

  /// Human-readable display name (e.g., "Claude Sonnet 4").
  final String? name;

  /// Whether the model supports image/file attachments.
  final bool attachment;

  /// Whether the model supports extended reasoning/thinking.
  final bool reasoning;

  /// Default temperature (null = use provider default).
  final double? temperature;

  /// Whether the model supports tool/function calling.
  final bool toolCall;

  /// Cost per million tokens (input/output), in cents or provider units.
  final OpenCodeModelCost? cost;

  /// Token limits.
  final OpenCodeModelLimit? limit;

  /// Supported input/output modalities.
  final OpenCodeModelModalities? modalities;

  /// Model lifecycle status.
  final String? status; // "alpha" | "beta" | "deprecated" | null (stable)

  const OpenCodeModelDef({
    required this.id,
    this.name,
    this.attachment = false,
    this.reasoning = false,
    this.temperature,
    this.toolCall = false,
    this.cost,
    this.limit,
    this.modalities,
    this.status,
  });

  /// Human-readable display name, falling back to id.
  String get displayName => name ?? id;

  /// Whether this model accepts image inputs.
  bool get supportsVision =>
      modalities?.input.contains('image') == true || attachment;

  /// Whether this model accepts audio inputs.
  bool get supportsAudio => modalities?.input.contains('audio') == true;

  /// The unified model ID used within Private Chat Hub.
  /// Format: "opencode:{providerId}/{modelId}"
  String unifiedId(String providerId) => 'opencode:$providerId/$id';

  factory OpenCodeModelDef.fromJson(String id, Map<String, dynamic> json);
}

class OpenCodeModelCost {
  final double input;   // per million tokens
  final double output;  // per million tokens
  final double? cacheRead;
  final double? cacheWrite;

  const OpenCodeModelCost({
    required this.input,
    required this.output,
    this.cacheRead,
    this.cacheWrite,
  });

  factory OpenCodeModelCost.fromJson(Map<String, dynamic> json);
}

class OpenCodeModelLimit {
  final int context;  // max context window tokens
  final int output;   // max output tokens

  const OpenCodeModelLimit({
    required this.context,
    required this.output,
  });

  factory OpenCodeModelLimit.fromJson(Map<String, dynamic> json);
}

class OpenCodeModelModalities {
  final List<String> input;   // e.g., ["text", "image"]
  final List<String> output;  // e.g., ["text"]

  const OpenCodeModelModalities({
    required this.input,
    required this.output,
  });

  factory OpenCodeModelModalities.fromJson(Map<String, dynamic> json);
}

/// Represents an OpenCode session (maps 1:1 to app Conversation).
class OpenCodeSession {
  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OpenCodeSession({
    required this.id,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OpenCodeSession.fromJson(Map<String, dynamic> json);
}

/// An SSE event from the OpenCode `/event` endpoint.
///
/// The event stream delivers real-time updates for all sessions.
/// We filter by sessionId to get events for the active conversation.
class OpenCodeSSEEvent {
  /// The event type (e.g., "message.part.updated", "message.created", etc.)
  final String type;

  /// The raw JSON payload.
  final Map<String, dynamic> data;

  const OpenCodeSSEEvent({
    required this.type,
    required this.data,
  });

  /// Extract the session ID this event belongs to, if present.
  String? get sessionId => data['sessionId'] as String? ?? data['session_id'] as String?;

  /// Extract text content from a message part update event.
  String? get textContent => data['content'] as String? ?? data['text'] as String?;

  factory OpenCodeSSEEvent.fromRawSSE(String event, String data);
}
```

### 4.3 `lib/models/opencode_model_capabilities.dart`

```dart
import 'package:private_chat_hub/models/opencode_models.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';

/// Builds [ModelCapabilities] from OpenCode's rich model metadata.
///
/// Unlike Ollama and LiteRT which rely on static registries,
/// OpenCode provides capability metadata dynamically via the API.
/// This class converts that metadata into the shared ModelCapabilities type.
class OpenCodeModelCapabilitiesFactory {
  OpenCodeModelCapabilitiesFactory._();

  /// Build a [ModelCapabilities] from an [OpenCodeModelDef] and its provider ID.
  static ModelCapabilities fromModelDef(
    OpenCodeModelDef model,
    String providerId,
  ) {
    return ModelCapabilities(
      supportsToolCalling: model.toolCall,
      supportsVision: model.supportsVision,
      supportsAudio: model.supportsAudio,
      supportsThinking: model.reasoning,
      contextWindow: model.limit?.context ?? 128000,
      modelFamily: providerId,
      description: model.displayName,
      useCases: _inferUseCases(model),
    );
  }

  static List<String> _inferUseCases(OpenCodeModelDef model) {
    final useCases = <String>['cloud inference'];
    if (model.toolCall) useCases.add('tool calling');
    if (model.supportsVision) useCases.add('vision');
    if (model.reasoning) useCases.add('reasoning');
    return useCases;
  }
}
```

---

## 5. Service Interface Contracts

### 5.1 `lib/services/opencode_api_client.dart`

Low-level HTTP client responsible for OpenCode REST API calls and SSE stream management.

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:private_chat_hub/models/opencode_connection.dart';
import 'package:private_chat_hub/models/opencode_models.dart';

/// Low-level HTTP client for the OpenCode server API.
///
/// Handles authentication, request building, and SSE stream parsing.
/// This is the only class that makes direct HTTP calls to the OpenCode server.
class OpenCodeApiClient {
  final OpenCodeConnection _connection;
  final http.Client _httpClient;

  /// Active SSE subscription (only one at a time — global event stream).
  StreamSubscription? _sseSubscription;

  /// Controller that re-broadcasts parsed SSE events.
  StreamController<OpenCodeSSEEvent>? _eventController;

  OpenCodeApiClient(this._connection) : _httpClient = http.Client();

  // ── Health ────────────────────────────────────────────────────────

  /// GET /global/health → { healthy: bool, version: String }
  Future<({bool healthy, String version})> checkHealth();

  // ── Providers & Models ────────────────────────────────────────────

  /// GET /provider → full provider list with model definitions.
  Future<List<OpenCodeProvider>> getProviders();

  /// GET /config/providers → provider config including connected providers.
  Future<({List<OpenCodeProvider> providers, Map<String, String> defaults})> getProviderConfig();

  // ── Sessions ──────────────────────────────────────────────────────

  /// POST /session → create a new session.
  /// Returns the created session.
  Future<OpenCodeSession> createSession({String? title});

  /// POST /session/:id/message → send a message to a session.
  /// Body: { parts: [...], model?: string, agent?: string }
  /// Returns the created message with its parts.
  Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required List<Map<String, dynamic>> parts,
    String? model,
    String? agent,
  });

  /// POST /session/:id/prompt_async → trigger async inference (returns 204).
  /// The actual response comes via SSE events.
  Future<void> promptAsync({required String sessionId});

  // ── SSE Event Stream ──────────────────────────────────────────────

  /// GET /event → Server-Sent Events stream.
  ///
  /// Opens a persistent HTTP connection to the SSE endpoint.
  /// Returns a broadcast stream of parsed events.
  /// Only one SSE connection is maintained at a time.
  Stream<OpenCodeSSEEvent> get eventStream;

  /// Connect to the SSE endpoint if not already connected.
  Future<void> connectEventStream();

  /// Disconnect the SSE stream.
  void disconnectEventStream();

  // ── Auth ───────────────────────────────────────────────────────────

  /// PUT /auth/:providerId → set auth credentials for a provider.
  Future<void> setProviderAuth({
    required String providerId,
    required Map<String, String> credentials,
  });

  // ── Internal ──────────────────────────────────────────────────────

  /// Build common headers (auth, content-type).
  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final auth = _connection.authorizationHeader;
    if (auth != null) h['Authorization'] = auth;
    return h;
  }

  /// Build SSE-specific headers.
  Map<String, String> get _sseHeaders {
    final h = <String, String>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    };
    final auth = _connection.authorizationHeader;
    if (auth != null) h['Authorization'] = auth;
    return h;
  }

  /// Dispose all resources.
  void dispose() {
    _sseSubscription?.cancel();
    _eventController?.close();
    _httpClient.close();
  }
}
```

### 5.2 `lib/services/opencode_connection_manager.dart`

```dart
import 'package:private_chat_hub/models/opencode_connection.dart';
import 'package:private_chat_hub/services/opencode_api_client.dart';

/// Manages the OpenCode server connection lifecycle.
///
/// Mirrors [OllamaConnectionManager] in structure and responsibility.
/// Bridges the app's [OpenCodeConnection] model with [OpenCodeApiClient].
class OpenCodeConnectionManager {
  OpenCodeConnection? _connection;
  OpenCodeApiClient? _client;

  /// Gets the current connection configuration.
  OpenCodeConnection? get connection => _connection;

  /// Gets the configured API client, or null if no connection is set.
  OpenCodeApiClient? get client => _client;

  /// Whether a connection is configured and a client exists.
  bool get isConfigured => _client != null;

  /// Sets the connection and creates a new API client.
  void setConnection(OpenCodeConnection connection) {
    _client?.dispose();
    _connection = connection;
    _client = OpenCodeApiClient(connection);
  }

  /// Tests the connection to the OpenCode server.
  /// Returns (healthy, version) or throws on failure.
  Future<({bool healthy, String version})> testConnection([
    OpenCodeConnection? connection,
  ]) async {
    if (connection != null) {
      final tempClient = OpenCodeApiClient(connection);
      try {
        return await tempClient.checkHealth();
      } finally {
        tempClient.dispose();
      }
    }
    if (_client == null) throw Exception('No OpenCode connection configured');
    return await _client!.checkHealth();
  }

  /// Clears the current connection and disposes the client.
  void clearConnection() {
    _client?.dispose();
    _connection = null;
    _client = null;
  }
}
```

### 5.3 `lib/services/opencode_llm_service.dart`

```dart
import 'dart:async';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/opencode_models.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/opencode_connection_manager.dart';
import 'package:private_chat_hub/services/opencode_model_visibility_service.dart';

/// LLM service implementation for OpenCode server.
///
/// Implements [LLMService] to integrate OpenCode as a third inference backend.
/// Uses the session-based API with SSE streaming for real-time token delivery.
///
/// ## Model ID Convention
///
/// OpenCode model IDs within Private Chat Hub use the format:
///   `opencode:{providerId}/{modelId}`
///
/// Examples:
///   - `opencode:anthropic/claude-sonnet-4-20250514`
///   - `opencode:openai/gpt-4o`
///   - `opencode:google/gemini-2.5-pro`
///
/// The `opencode:` prefix is stripped before sending to the OpenCode API.
/// The provider ID and model ID are extracted by splitting on `/`.
class OpenCodeLLMService implements LLMService {
  final OpenCodeConnectionManager _connectionManager;
  final OpenCodeModelVisibilityService? _visibilityService;

  String? _currentModelId;

  /// Cache of provider data fetched from the server.
  List<OpenCodeProvider>? _cachedProviders;

  /// Map from conversationId → OpenCode sessionId.
  /// Lazily populated when a conversation first sends a message.
  final Map<String, String> _sessionMap = {};

  OpenCodeLLMService(
    this._connectionManager, {
    OpenCodeModelVisibilityService? visibilityService,
  }) : _visibilityService = visibilityService;

  @override
  String? get currentModelId => _currentModelId;

  @override
  bool isModelLoaded(String modelId) => _currentModelId == modelId;

  @override
  Future<bool> isAvailable() async {
    final client = _connectionManager.client;
    if (client == null) return false;
    try {
      final health = await client.checkHealth();
      return health.healthy;
    } catch (e) {
      _log('OpenCode not available: $e');
      return false;
    }
  }

  @override
  Future<List<ModelInfo>> getAvailableModels() async {
    final client = _connectionManager.client;
    if (client == null) return [];

    try {
      final providers = await client.getProviders();
      _cachedProviders = providers;

      final models = <ModelInfo>[];
      final visibleSet = _visibilityService?.visibleModelIds;

      for (final provider in providers) {
        for (final entry in provider.models.entries) {
          final modelDef = entry.value;
          final unifiedId = modelDef.unifiedId(provider.id);

          // Skip if visibility service is active and model is hidden
          if (visibleSet != null && !visibleSet.contains(unifiedId)) continue;

          // Skip deprecated models unless explicitly visible
          if (modelDef.status == 'deprecated') continue;

          models.add(_toModelInfo(provider.id, modelDef));
        }
      }

      return models;
    } catch (e) {
      _log('Failed to get OpenCode models: $e');
      return [];
    }
  }

  @override
  Future<void> loadModel(String modelId) async {
    // OpenCode loads models on-demand server-side; just track selection.
    _currentModelId = modelId;
    _log('Model set to: $modelId');
  }

  @override
  Future<void> unloadModel() async {
    _currentModelId = null;
    _log('Model tracking cleared');
  }

  @override
  Stream<String> generateResponse({
    required String prompt,
    required String modelId,
    List<Message>? conversationHistory,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
    List<Attachment>? attachments,
  }) async* {
    final client = _connectionManager.client;
    if (client == null) throw Exception('OpenCode not connected');

    _currentModelId = modelId;

    // Strip the "opencode:" prefix to get "providerId/modelId"
    final rawModelId = stripPrefix(modelId);

    // Build message parts for the OpenCode API.
    // OpenCode uses "parts" with type annotations.
    final parts = <Map<String, dynamic>>[];

    // Add text content
    parts.add({'type': 'text', 'text': prompt});

    // Add image attachments as base64
    if (attachments != null) {
      for (final attachment in attachments) {
        if (attachment.isImage) {
          parts.add({
            'type': 'image',
            'image': base64Encode(attachment.data),
            'mimeType': attachment.mimeType,
          });
        }
      }
    }

    // Get or create the OpenCode session for this "conversation".
    // When called from ChatService, we receive a conversationId-scoped
    // context. We use a synthetic session keyed by the modelId + prompt hash
    // for simplicity. The ChatService integration (Section 8) handles the
    // actual conversationId → sessionId mapping.

    // Create a fresh session for this generation request.
    // (The ChatService-level integration in _sendMessageOpenCode manages
    //  the long-lived session mapping.)
    final session = await client.createSession(
      title: prompt.length > 60 ? prompt.substring(0, 60) : prompt,
    );

    // Send the message to the session
    await client.sendMessage(
      sessionId: session.id,
      parts: parts,
      model: rawModelId,
    );

    // Trigger async prompt — response comes via SSE
    await client.promptAsync(sessionId: session.id);

    // Connect to SSE if not already connected
    await client.connectEventStream();

    // Listen to SSE events filtered for this session
    await for (final event in client.eventStream) {
      if (event.sessionId != session.id) continue;

      switch (event.type) {
        case 'message.part.updated':
        case 'message.part.delta':
          final text = event.textContent;
          if (text != null && text.isNotEmpty) {
            yield text;
          }
          break;

        case 'message.completed':
        case 'message.done':
          // Generation complete
          return;

        case 'message.error':
        case 'error':
          final error = event.data['error'] ?? event.data['message'] ?? 'Unknown error';
          throw Exception('OpenCode generation error: $error');
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  /// Convert an [OpenCodeModelDef] into the shared [ModelInfo] type.
  ModelInfo _toModelInfo(String providerId, OpenCodeModelDef modelDef) {
    final capabilities = <String>['text'];
    if (modelDef.supportsVision) capabilities.add('vision');
    if (modelDef.supportsAudio) capabilities.add('audio');
    if (modelDef.toolCall) capabilities.add('tools');
    if (modelDef.reasoning) capabilities.add('reasoning');

    return ModelInfo(
      id: modelDef.unifiedId(providerId),
      name: '${_providerDisplayName(providerId)} / ${modelDef.displayName}',
      description: _buildDescription(providerId, modelDef),
      sizeBytes: 0, // Cloud models have no local size
      isDownloaded: true, // Always "available"
      capabilities: capabilities,
      isLocal: false,
    );
  }

  String _buildDescription(String providerId, OpenCodeModelDef modelDef) {
    final parts = <String>[];
    if (modelDef.limit != null) {
      parts.add('${(modelDef.limit!.context / 1000).round()}k context');
    }
    if (modelDef.cost != null) {
      parts.add('\$${modelDef.cost!.input}/\$${modelDef.cost!.output} per 1M tokens');
    }
    if (modelDef.status != null) {
      parts.add('(${modelDef.status})');
    }
    return parts.isEmpty ? 'OpenCode: $providerId' : parts.join(' · ');
  }

  String _providerDisplayName(String providerId) {
    const names = {
      'anthropic': 'Anthropic',
      'openai': 'OpenAI',
      'google': 'Google',
      'aws': 'AWS Bedrock',
      'azure': 'Azure',
      'groq': 'Groq',
      'mistral': 'Mistral',
      'xai': 'xAI',
      'deepseek': 'DeepSeek',
      'together': 'Together AI',
    };
    return names[providerId.toLowerCase()] ?? providerId;
  }

  // ── Static Utilities ───────────────────────────────────────────────

  /// Prefix used for OpenCode model IDs in the unified model list.
  static const String modelPrefix = 'opencode:';

  /// Whether a model name belongs to OpenCode.
  static bool isOpenCodeModel(String modelName) {
    return modelName.startsWith(modelPrefix);
  }

  /// Strip the "opencode:" prefix from a model ID.
  /// Returns "providerId/modelId".
  static String stripPrefix(String modelId) {
    if (modelId.startsWith(modelPrefix)) {
      return modelId.substring(modelPrefix.length);
    }
    return modelId;
  }

  /// Extract the provider ID from a unified model ID.
  /// "opencode:anthropic/claude-sonnet-4" → "anthropic"
  static String extractProviderId(String modelId) {
    final raw = stripPrefix(modelId);
    final slashIndex = raw.indexOf('/');
    return slashIndex >= 0 ? raw.substring(0, slashIndex) : raw;
  }

  /// Extract the bare model ID from a unified model ID.
  /// "opencode:anthropic/claude-sonnet-4" → "claude-sonnet-4"
  static String extractModelId(String modelId) {
    final raw = stripPrefix(modelId);
    final slashIndex = raw.indexOf('/');
    return slashIndex >= 0 ? raw.substring(slashIndex + 1) : raw;
  }

  @override
  Future<void> dispose() async {
    _connectionManager.client?.disconnectEventStream();
    _currentModelId = null;
    _sessionMap.clear();
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[OpenCodeLLMService] $message');
  }
}
```

### 5.4 `lib/services/opencode_model_visibility_service.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Persists which OpenCode models the user wants to see in the model selector.
///
/// OpenCode can expose hundreds of models across many providers. Rather than
/// showing all of them, the user selects which models to "pin" as visible.
///
/// ## Persistence
///
/// Uses SharedPreferences with a simple string-list key. The list contains
/// unified model IDs (e.g., "opencode:anthropic/claude-sonnet-4-20250514").
///
/// ## Default Behavior
///
/// When no visibility config exists (first launch), ALL models from
/// connected providers are shown. Once the user modifies visibility,
/// only the selected subset is shown.
class OpenCodeModelVisibilityService {
  final SharedPreferences _prefs;

  static const String _visibleModelsKey = 'opencode_visible_models';
  static const String _hasCustomizedKey = 'opencode_visibility_customized';

  OpenCodeModelVisibilityService(this._prefs);

  /// Whether the user has customized model visibility.
  /// If false, all models from connected providers are shown.
  bool get hasCustomized => _prefs.getBool(_hasCustomizedKey) ?? false;

  /// Get the set of visible model IDs.
  /// Returns null if the user hasn't customized (show all).
  Set<String>? get visibleModelIds {
    if (!hasCustomized) return null; // null = show all
    final list = _prefs.getStringList(_visibleModelsKey);
    return list?.toSet();
  }

  /// Set the visible model IDs.
  Future<void> setVisibleModelIds(Set<String> modelIds) async {
    await _prefs.setStringList(_visibleModelsKey, modelIds.toList());
    await _prefs.setBool(_hasCustomizedKey, true);
  }

  /// Add a model to the visible set.
  Future<void> showModel(String modelId) async {
    final current = visibleModelIds ?? {};
    current.add(modelId);
    await setVisibleModelIds(current);
  }

  /// Remove a model from the visible set.
  Future<void> hideModel(String modelId) async {
    final current = visibleModelIds;
    if (current == null) return; // If not customized yet, do nothing
    current.remove(modelId);
    await setVisibleModelIds(current);
  }

  /// Check if a specific model is visible.
  bool isVisible(String modelId) {
    final visible = visibleModelIds;
    if (visible == null) return true; // Show all by default
    return visible.contains(modelId);
  }

  /// Reset to show all models (clear customization).
  Future<void> resetToShowAll() async {
    await _prefs.remove(_visibleModelsKey);
    await _prefs.remove(_hasCustomizedKey);
  }
}
```

---

## 6. OpenCode Sessions ↔ App Conversations Mapping

### 6.1 The Mapping Problem

Private Chat Hub has `Conversation` objects with message histories persisted locally. OpenCode has `Session` objects with message histories managed server-side. We need to decide how these relate.

### 6.2 Chosen Strategy: Lazy 1:1 Mapping with Local Authority

```
┌─────────────────────────┐        ┌──────────────────────────┐
│   App Conversation      │        │   OpenCode Session       │
│                         │  1:1   │                          │
│   id: "conv-abc123"     │◄──────►│   id: "sess-xyz789"      │
│   modelName: "opencode: │        │   title: "Help me with…" │
│     anthropic/claude…"  │        │                          │
│   messages: [local copy]│        │   messages: [server copy] │
└─────────────────────────┘        └──────────────────────────┘
```

**Rules:**

1. **App is the source of truth** for conversation metadata, message display, and persistence. This is identical to how Ollama works — the app doesn't rely on Ollama to store conversations.

2. **Session creation is lazy.** When a user creates a conversation with an `opencode:` model, no OpenCode session exists yet. The session is created on the first `sendMessage` call.

3. **Session ID is stored** in the `ChatService`'s in-memory map `_openCodeSessionMap: Map<String, String>` (conversationId → sessionId) and also persisted in SharedPreferences for crash recovery.

4. **Message history is sent from the app** each time, because OpenCode sessions may not retain full history across server restarts. The app always sends the conversation context.

5. **Session reuse per conversation.** Subsequent messages in the same conversation reuse the same OpenCode session, enabling any server-side context/state the session may hold.

### 6.3 Session Lifecycle

```
User creates conversation with "opencode:anthropic/claude-sonnet-4"
  → No session created yet (lazy)

User sends first message "Hello"
  → ChatService._sendMessageOpenCode() called
  → POST /session { title: "Hello" } → sessionId = "sess-001"
  → Store mapping: conv.id → "sess-001"
  → POST /session/sess-001/message { parts: [{type: "text", text: "Hello"}], model: "anthropic/claude-sonnet-4" }
  → POST /session/sess-001/prompt_async → 204
  → SSE stream → yield tokens → assistant message built locally

User sends second message "Tell me more"
  → Lookup mapping: conv.id → "sess-001" (reuse)
  → POST /session/sess-001/message { parts: [...], model: "anthropic/claude-sonnet-4" }
  → POST /session/sess-001/prompt_async → 204
  → SSE stream → yield tokens

User closes app and reopens
  → Session map reloaded from SharedPreferences
  → If session is still valid, reuse; otherwise create new
```

### 6.4 Persistence of Session Map

```dart
/// In InferenceConfigService (or a dedicated OpenCodeSessionMapService)
static const String _openCodeSessionMapKey = 'opencode_session_map';

/// Save: jsonEncode(Map<String, String>)
/// Load: jsonDecode → Map<String, String>
```

---

## 7. Streaming Architecture (SSE Events → Token Stream)

### 7.1 How OpenCode Streaming Works

OpenCode uses a **global SSE endpoint** (`GET /event`) that delivers events for ALL sessions. This is fundamentally different from Ollama's per-request streaming.

```
┌─────────────────┐         ┌────────────────────┐
│ Flutter App      │         │ OpenCode Server     │
│                  │         │                    │
│ 1. POST /session │────────►│ Create session     │
│    /msg/prompt   │         │                    │
│                  │         │                    │
│ 2. GET /event    │◄───SSE──│ Event stream       │
│    (persistent)  │         │                    │
│                  │  event: │ message.part.delta  │
│                  │  data:  │ {"sessionId":"…",  │
│                  │         │  "content":"Hello"}│
│                  │         │                    │
│    Filter by     │         │                    │
│    sessionId     │         │                    │
│                  │         │                    │
│    yield "Hello" │         │                    │
│    to stream     │         │                    │
└─────────────────┘         └────────────────────┘
```

### 7.2 SSE Client Implementation Strategy

The `http` package supports streamed responses. We read the response body as a byte stream and parse SSE frames manually:

```dart
/// In OpenCodeApiClient:
Future<void> connectEventStream() async {
  if (_eventController != null && !_eventController!.isClosed) return;

  _eventController = StreamController<OpenCodeSSEEvent>.broadcast();

  final request = http.Request('GET', Uri.parse('${_connection.baseUrl}/event'));
  request.headers.addAll(_sseHeaders);

  final response = await _httpClient.send(request);

  if (response.statusCode != 200) {
    throw Exception('SSE connection failed: ${response.statusCode}');
  }

  // Parse SSE frames from the byte stream
  String buffer = '';
  String? currentEvent;
  String currentData = '';

  _sseSubscription = response.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(
    (line) {
      if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        currentData += line.substring(5).trim();
      } else if (line.isEmpty && currentData.isNotEmpty) {
        // Empty line = end of event frame
        try {
          final data = jsonDecode(currentData) as Map<String, dynamic>;
          _eventController!.add(OpenCodeSSEEvent(
            type: currentEvent ?? 'message',
            data: data,
          ));
        } catch (e) {
          // Non-JSON data or parse error — skip
          _log('SSE parse error: $e');
        }
        currentEvent = null;
        currentData = '';
      }
    },
    onError: (error) {
      _eventController!.addError(error);
    },
    onDone: () {
      _eventController!.close();
    },
  );
}
```

### 7.3 Token Stream Contract

The `generateResponse` method in `OpenCodeLLMService` returns a `Stream<String>` that:

1. Yields **incremental text deltas** (not full text), matching the Ollama and LiteRT contract
2. Completes when `message.completed` or `message.done` is received
3. Throws on `message.error` or `error` events
4. Filters SSE events by `sessionId` to only yield tokens for the active conversation

This is **directly compatible** with the existing `ChatService._sendMessageOnDevice` pattern which yields tokens that are appended to a `StringBuffer`.

### 7.4 SSE Connection Lifecycle

- **Connect** when the first OpenCode message is sent (lazy, like Ollama client)
- **Keep alive** while the app is foregrounded and has an active OpenCode conversation
- **Disconnect** when no OpenCode conversations are active for 5 minutes, or on app background
- **Reconnect** automatically on network recovery (leverages existing `ConnectivityService`)

---

## 8. Integration Points with Existing Code

### 8.1 `lib/services/llm_service.dart` — Extend InferenceMode

```dart
// BEFORE:
enum InferenceMode {
  remote,
  onDevice,
}

// AFTER:
enum InferenceMode {
  /// Remote inference via Ollama server
  remote,

  /// On-device inference via LiteRT-LM
  onDevice,

  /// Cloud inference via OpenCode server
  openCode,
}
```

### 8.2 `lib/services/inference_config_service.dart` — Add OpenCode Support

**New preference keys:**
```dart
static const String _lastOpenCodeModelKey = 'last_opencode_model';
```

**Updated `inferenceMode` getter:**
```dart
InferenceMode get inferenceMode {
  final modeString = _prefs.getString(_inferenceModeKey);
  switch (modeString) {
    case 'onDevice':
      return InferenceMode.onDevice;
    case 'openCode':
      return InferenceMode.openCode;
    default:
      return InferenceMode.remote;
  }
}
```

**New accessors:**
```dart
/// Get last used OpenCode model
String? get lastOpenCodeModel => _prefs.getString(_lastOpenCodeModelKey);

/// Set last used OpenCode model
Future<void> setLastOpenCodeModel(String modelId) async {
  await _prefs.setString(_lastOpenCodeModelKey, modelId);
}
```

**Updated `lastModel` getter:**
```dart
String? get lastModel {
  switch (inferenceMode) {
    case InferenceMode.remote:
      return lastRemoteModel;
    case InferenceMode.onDevice:
      return lastOnDeviceModel;
    case InferenceMode.openCode:
      return lastOpenCodeModel;
  }
}
```

**Updated extension `InferenceModeExtension`:**
```dart
extension InferenceModeExtension on InferenceMode {
  String get displayName {
    switch (this) {
      case InferenceMode.remote:
        return 'Remote (Ollama)';
      case InferenceMode.onDevice:
        return 'On-Device (LiteRT)';
      case InferenceMode.openCode:
        return 'Cloud (OpenCode)';
    }
  }

  String get description {
    switch (this) {
      case InferenceMode.remote:
        return 'Run models on your Ollama server. More models available, unlimited size.';
      case InferenceMode.onDevice:
        return 'Run models directly on your device. Fully private, works offline.';
      case InferenceMode.openCode:
        return 'Access cloud LLMs via your OpenCode server. Widest model selection.';
    }
  }

  String get iconName {
    switch (this) {
      case InferenceMode.remote:
        return 'cloud';
      case InferenceMode.onDevice:
        return 'phone_android';
      case InferenceMode.openCode:
        return 'hub';
    }
  }
}
```

### 8.3 `lib/services/unified_model_service.dart` — Add OpenCode Models

**Updated constructor:**
```dart
class UnifiedModelService {
  final OnDeviceLLMService? _onDeviceLLMService;
  final OpenCodeLLMService? _openCodeLLMService; // NEW

  static const String localModelPrefix = 'local:';
  static const String openCodeModelPrefix = 'opencode:'; // NEW

  UnifiedModelService({
    OnDeviceLLMService? onDeviceLLMService,
    OpenCodeLLMService? openCodeLLMService, // NEW
  }) : _onDeviceLLMService = onDeviceLLMService,
       _openCodeLLMService = openCodeLLMService;
```

**Updated `getUnifiedModelList`:**
```dart
Future<List<ModelInfo>> getUnifiedModelList(
  List<OllamaModelInfo> ollamaModels,
) async {
  final List<ModelInfo> unifiedList = [];

  // Add Ollama models (remote) — unchanged
  for (final OllamaModelInfo ollamaModel in ollamaModels) {
    unifiedList.add(/* existing code */);
  }

  // Add on-device models (local) — unchanged
  if (_onDeviceLLMService != null) {
    // ... existing code ...
  }

  // Add OpenCode models (cloud) — NEW
  if (_openCodeLLMService != null) {
    try {
      final openCodeModels = await _openCodeLLMService!.getAvailableModels();
      unifiedList.addAll(openCodeModels);
    } catch (e) {
      print('[UnifiedModelService] Failed to get OpenCode models: $e');
    }
  }

  return unifiedList;
}
```

**New static helpers:**
```dart
/// Check if a model name is an OpenCode model
static bool isOpenCodeModel(String modelName) {
  return modelName.startsWith(openCodeModelPrefix);
}

/// Get the raw model ID without the opencode: prefix
static String getOpenCodeModelId(String modelName) {
  if (isOpenCodeModel(modelName)) {
    return modelName.substring(openCodeModelPrefix.length);
  }
  return modelName;
}

/// Updated display name
static String getDisplayName(String modelName) {
  if (isLocalModel(modelName)) return getLocalModelId(modelName);
  if (isOpenCodeModel(modelName)) return getOpenCodeModelId(modelName);
  return modelName;
}
```

### 8.4 `lib/services/chat_service.dart` — Add OpenCode Routing

**New fields:**
```dart
class ChatService {
  // ... existing fields ...
  OpenCodeLLMService? _openCodeLLMService;  // NEW

  // OpenCode session map: conversationId → OpenCode sessionId
  final Map<String, String> _openCodeSessionMap = {};  // NEW
```

**New setter (mirrors `setOnDeviceLLMService`):**
```dart
/// Set the OpenCode LLM service
void setOpenCodeLLMService(OpenCodeLLMService service) {
  _openCodeLLMService = service;
  _log('OpenCode LLM service attached');
}
```

**Updated routing in `sendMessage` (around line 826-869):**
```dart
// Existing: check local model prefix
final isLocalModel = UnifiedModelService.isLocalModel(initialConversation.modelName);
// NEW: check opencode model prefix
final isOpenCodeModel = UnifiedModelService.isOpenCodeModel(initialConversation.modelName);

_log(
  'Routing decision: model=${initialConversation.modelName}, '
  'isLocalModel=$isLocalModel, '
  'isOpenCodeModel=$isOpenCodeModel, '  // NEW
  'inferenceMode=$currentInferenceMode, '
  'onDeviceServiceReady=${_onDeviceLLMService != null}, '
  'openCodeServiceReady=${_openCodeLLMService != null}, '  // NEW
  'isOnline=$isOnline',
);

// Route to OpenCode if opencode: model is selected — NEW
if (isOpenCodeModel) {
  if (_openCodeLLMService == null) {
    throw Exception(
      'OpenCode service is not configured. Please set up an OpenCode connection in Settings.',
    );
  }
  _log('Using OpenCode inference (opencode: model selected)');
  yield* _sendMessageOpenCode(conversationId, text);
  return;
}

// Existing: route to on-device if local model
if (isLocalModel && _onDeviceLLMService != null) { /* existing */ }

// Existing: offline queueing for remote models
// ...
```

**New `_sendMessageOpenCode` method:**
```dart
/// Sends a message using OpenCode server inference.
///
/// Similar structure to [_sendMessageOnDevice] but uses the OpenCode
/// session-based API with SSE streaming.
Stream<Conversation> _sendMessageOpenCode(
  String conversationId,
  String text, {
  bool addUserMessage = true,
}) async* {
  final initialConversation = getConversation(conversationId);
  if (initialConversation == null) throw Exception('Conversation not found');
  if (_openCodeLLMService == null) throw Exception('OpenCode not configured');

  final client = _openCodeLLMService!._connectionManager.client;
  if (client == null) throw Exception('OpenCode not connected');

  // 1. Add user message to conversation (if needed)
  var conversation = initialConversation;
  if (addUserMessage) {
    final userMessage = Message.user(
      id: const Uuid().v4(),
      text: text,
      timestamp: DateTime.now(),
    );
    conversation = await addMessage(conversationId, userMessage);
    yield conversation;
  }

  // 2. Create placeholder assistant message
  final assistantMessageId = const Uuid().v4();
  var assistantMessage = Message.assistant(
    id: assistantMessageId,
    text: '',
    timestamp: DateTime.now(),
    isStreaming: true,
  );
  conversation = await addMessage(conversationId, assistantMessage);
  yield conversation;

  // 3. Get or create OpenCode session
  String sessionId;
  if (_openCodeSessionMap.containsKey(conversationId)) {
    sessionId = _openCodeSessionMap[conversationId]!;
  } else {
    final session = await client.createSession(
      title: conversation.title,
    );
    sessionId = session.id;
    _openCodeSessionMap[conversationId] = sessionId;
    await _persistSessionMap();
  }

  // 4. Extract model info
  final rawModelId = OpenCodeLLMService.stripPrefix(conversation.modelName);

  // 5. Build message parts
  final parts = <Map<String, dynamic>>[
    {'type': 'text', 'text': text},
  ];

  // Include image attachments from the last user message
  final imageAttachments = _lastUserMessageAttachments(conversation, assistantMessageId);
  if (imageAttachments != null) {
    for (final attachment in imageAttachments) {
      if (attachment.isImage) {
        parts.add({
          'type': 'image',
          'image': base64Encode(attachment.data),
          'mimeType': attachment.mimeType,
        });
      }
    }
  }

  // 6. Send message and trigger async inference
  await client.sendMessage(
    sessionId: sessionId,
    parts: parts,
    model: rawModelId,
  );
  await client.promptAsync(sessionId: sessionId);

  // 7. Stream SSE events
  await client.connectEventStream();

  final buffer = StringBuffer();
  try {
    await for (final event in client.eventStream) {
      if (event.sessionId != sessionId) continue;

      switch (event.type) {
        case 'message.part.updated':
        case 'message.part.delta':
          final content = event.textContent;
          if (content != null && content.isNotEmpty) {
            buffer.write(content);
            conversation = await _updateAssistantMessage(
              conversation,
              assistantMessageId,
              buffer.toString(),
              isStreaming: true,
            );
            yield conversation;
          }
          break;

        case 'message.completed':
        case 'message.done':
          // Finalize the message
          conversation = await _updateAssistantMessage(
            conversation,
            assistantMessageId,
            buffer.toString(),
            isStreaming: false,
          );
          await _inferenceConfigService?.setLastOpenCodeModel(conversation.modelName);
          await _saveConversations();
          yield conversation;
          return;

        case 'message.error':
        case 'error':
          final error = event.data['error'] ?? event.data['message'] ?? 'Unknown error';
          _handleError(conversationId, conversation, assistantMessageId,
              _activeStreams[conversationId]!, error.toString());
          return;
      }
    }
  } catch (e) {
    _log('OpenCode streaming error: $e');
    _handleError(conversationId, conversation, assistantMessageId,
        _activeStreams[conversationId]!, e.toString());
  }
}
```

### 8.5 `lib/models/model_capability_resolver.dart` — Add OpenCode Detection

```dart
// BEFORE:
static bool _isLocalModel(String modelName) {
  return modelName.trim().toLowerCase().startsWith('local:');
}

// AFTER:
static bool _isLocalModel(String modelName) {
  return modelName.trim().toLowerCase().startsWith('local:');
}

static bool _isOpenCodeModel(String modelName) {
  return modelName.trim().toLowerCase().startsWith('opencode:');
}

// Updated getCapabilities:
static ModelCapabilities? getCapabilities(String modelName) {
  if (_isLocalModel(modelName)) {
    return OnDeviceModelCapabilitiesRegistry.getCapabilities(modelName);
  }
  if (_isOpenCodeModel(modelName)) {
    // OpenCode capabilities are dynamic (fetched from API), not from a
    // static registry. Return null here; the OpenCodeLLMService provides
    // capabilities via ModelInfo at list time. The unknown fallback in
    // getCapabilitiesOrUnknown() is acceptable for edge cases.
    return null;
  }
  return ModelRegistry.getCapabilities(modelName);
}
```

> **Note:** For richer capability resolution, we could cache OpenCode model capabilities in a static map populated at fetch time. This is a future enhancement — the `unknown` fallback already handles tool calling conservatively.

### 8.6 `lib/main.dart` — Initialize OpenCode Services

In `_HomeScreenState`, add new fields and initialization:

```dart
class _HomeScreenState extends State<HomeScreen> {
  // ... existing fields ...
  OpenCodeConnectionManager? _openCodeManager;          // NEW
  OpenCodeLLMService? _openCodeLLMService;               // NEW
  OpenCodeModelVisibilityService? _openCodeVisibility;   // NEW

  Future<void> _initializeInferenceServices() async {
    // ... existing Ollama + LiteRT init ...

    // Initialize OpenCode services — NEW
    try {
      _openCodeVisibility = OpenCodeModelVisibilityService(prefs);
      _openCodeManager = OpenCodeConnectionManager();

      // Load saved OpenCode connection
      final openCodeConnection = _loadOpenCodeConnection(prefs);
      if (openCodeConnection != null) {
        _openCodeManager!.setConnection(openCodeConnection);

        _openCodeLLMService = OpenCodeLLMService(
          _openCodeManager!,
          visibilityService: _openCodeVisibility,
        );
        _chatService.setOpenCodeLLMService(_openCodeLLMService!);

        _log('OpenCode service initialized');
      }
    } catch (e) {
      _log('Failed to initialize OpenCode service: $e');
    }
  }
}
```

---

## 9. Model ID Prefix Convention

### 9.1 Full Prefix Table

| Prefix | Backend | Example | Route |
|---|---|---|---|
| *(none)* | Ollama remote | `llama3.2:3b` | `OllamaLLMService` |
| `local:` | LiteRT on-device | `local:gemma3-1b` | `OnDeviceLLMService` |
| `opencode:` | OpenCode server | `opencode:anthropic/claude-sonnet-4-20250514` | `OpenCodeLLMService` |

### 9.2 OpenCode Model ID Structure

```
opencode:{providerId}/{modelId}
         ├─────────┘ └──────────────────────────┘
         │           Full model ID from provider
         │
         Provider slug (anthropic, openai, google, etc.)
```

**Examples:**
- `opencode:anthropic/claude-sonnet-4-20250514`
- `opencode:openai/gpt-4o-2024-08-06`
- `opencode:google/gemini-2.5-pro-preview`
- `opencode:deepseek/deepseek-chat`
- `opencode:groq/llama-3.3-70b-versatile`

### 9.3 Display Name Convention

In the model selector and conversation headers, strip the prefix and format as:
```
"Anthropic / Claude Sonnet 4"
"OpenAI / GPT-4o"
"Google / Gemini 2.5 Pro"
```

---

## 10. Caching Strategy

### 10.1 Model List Caching

OpenCode models are cached the same way Ollama models are — via `UnifiedModelService.cacheRemoteModels()`. The existing method already caches all `!isLocal` models, which naturally includes `opencode:` models.

For clarity, the updated caching covers:
- **Ollama models** → cached when fetched (existing)
- **OpenCode models** → cached when fetched (covered by existing `!isLocal` filter)
- **On-device models** → not cached (always available locally)

### 10.2 Session Map Caching

The `_openCodeSessionMap` (conversationId → sessionId) is persisted to SharedPreferences:

```dart
static const String _openCodeSessionMapKey = 'opencode_session_map';

Future<void> _persistSessionMap() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_openCodeSessionMapKey, jsonEncode(_openCodeSessionMap));
}

Future<void> _loadSessionMap() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_openCodeSessionMapKey);
  if (json != null) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    _openCodeSessionMap.addAll(map.cast<String, String>());
  }
}
```

### 10.3 Connection Persistence

The `OpenCodeConnection` is persisted in SharedPreferences under a dedicated key:

```dart
static const String _openCodeConnectionKey = 'opencode_connection';
```

This is managed by the Settings screen, following the same pattern as `ConnectionService` for Ollama connections.

---

## 11. Error Handling Strategy

### 11.1 Error Categories

| Error | Source | User Message | Recovery |
|---|---|---|---|
| Server unreachable | `checkHealth()` timeout | "Cannot reach OpenCode server at {host}:{port}" | Retry / check config |
| Auth failed | 401 response | "OpenCode authentication failed. Check your server password." | Re-enter password |
| Provider not connected | Provider list shows 0 connected | "No AI providers connected in OpenCode. Configure providers in OpenCode settings." | User configures OpenCode |
| Model not available | 404 on prompt | "Model {name} is not available. It may have been removed or the provider is disconnected." | Select different model |
| SSE connection dropped | Network error on /event | "Connection to OpenCode lost. Retrying…" | Auto-reconnect |
| Rate limit | 429 response | "Rate limited by {provider}. Please wait and try again." | Exponential backoff |
| Generation error | SSE error event | "Error from {provider}: {message}" | Display to user |

### 11.2 Offline Behavior

When the OpenCode server is unreachable:

1. **Do NOT fall back** to Ollama or on-device. The user explicitly chose a cloud model — honour that choice (consistent with existing Ollama offline policy).
2. **Do NOT queue** messages for later. Unlike Ollama, OpenCode sessions are stateless from the client's perspective, and the server may restart. Queueing could lead to stale contexts.
3. **Show an immediate error** with a suggestion to switch to an available model.

This differs from Ollama's offline queue because OpenCode is typically used for cloud models where the user has a specific provider/model expectation.

---

## 12. Testing Strategy

### 12.1 Unit Tests

| Test File | Covers |
|---|---|
| `test/models/opencode_connection_test.dart` | Serialization, URL construction, auth header |
| `test/models/opencode_models_test.dart` | JSON parsing for all model types |
| `test/services/opencode_api_client_test.dart` | HTTP request building, SSE parsing |
| `test/services/opencode_llm_service_test.dart` | Model listing, prefix handling, session management |
| `test/services/opencode_model_visibility_test.dart` | Visibility persistence, show/hide logic |
| `test/services/unified_model_service_test.dart` | Updated to include OpenCode models |
| `test/services/inference_config_service_test.dart` | Updated for openCode mode |

### 12.2 Integration Tests

| Test | Description |
|---|---|
| OpenCode health check | Connect to test server, verify health endpoint |
| Model discovery | Fetch providers, verify model list conversion |
| Session lifecycle | Create session, send message, verify session reuse |
| SSE streaming | Send prompt_async, verify token stream yields correctly |
| Routing end-to-end | ChatService routes opencode: model to OpenCodeLLMService |

### 12.3 Mock Strategy

The `OpenCodeApiClient` should be injectable/mockable. The test suite should use a mock HTTP client that returns canned SSE responses, allowing offline testing of the streaming pipeline.

---

## 13. Alternatives Considered

### 13.1 Embedding OpenCode as a git submodule

**Rejected.** OpenCode is a separate server process. Embedding it would change the deployment model and add massive complexity. The HTTP API is the intended integration surface.

### 13.2 Using the Ollama-compatible endpoint in OpenCode

**Rejected.** OpenCode exposes its own API shape (sessions, parts, SSE). Trying to force it through the Ollama code path would lose rich metadata (cost, modalities, reasoning flags) and require awkward translation layers.

### 13.3 Using `dio` instead of `http` for SSE

**Rejected for now.** The `http` package is already a dependency and supports streamed responses, which is sufficient for SSE. `dio` would add a new dependency. If SSE reliability becomes an issue (reconnection, keep-alive), we can revisit.

### 13.4 Storing all models as visible by default (no visibility service)

**Rejected.** OpenCode can aggregate 100+ models across many providers. Showing all of them in the model selector would be overwhelming. The visibility service lets users curate their preferred subset.

### 13.5 Using a shared `Connection` model for both Ollama and OpenCode

**Rejected.** While they share `host`/`port`/`useHttps`, OpenCode adds `password` auth and has a different default port (3000 vs 11434). Separate models avoid confusion and keep each provider's concerns isolated, following the same philosophy that keeps `OllamaLLMService` and `OnDeviceLLMService` as separate classes.

---

## 14. Migration & Rollout Plan

### Phase 1: Foundation (No UI changes)
1. Create `OpenCodeConnection`, `OpenCodeModels`, and API client
2. Create `OpenCodeLLMService` implementing `LLMService`
3. Extend `InferenceMode` enum
4. Unit tests for all new models and services

### Phase 2: Integration (Wiring)
5. Update `UnifiedModelService` to include OpenCode
6. Update `ChatService` routing
7. Update `ModelCapabilityResolver`
8. Integration tests with mock server

### Phase 3: UI (User-facing)
9. Add OpenCode connection settings UI
10. Add OpenCode model visibility picker
11. Update model selector to show opencode: models
12. Update inference mode picker with third option

### Phase 4: Polish
13. Error messages and edge cases
14. SSE reconnection logic
15. Documentation and user guide
16. E2E testing with real OpenCode server

---

## 15. Dependencies

### New packages required: **None**

All functionality can be implemented with existing dependencies:
- `http` — HTTP requests and streamed responses (SSE)
- `shared_preferences` — Connection and visibility persistence
- `uuid` — Session and message ID generation
- `dart:convert` — JSON and Base64 encoding

### No new third-party packages

This is a deliberate design choice to minimize dependency surface and keep the app lightweight.

---

## 16. Summary of Changes by File

| File | Change Type | Lines (est.) | Risk |
|---|---|---|---|
| `lib/models/opencode_connection.dart` | **NEW** | ~90 | Low |
| `lib/models/opencode_models.dart` | **NEW** | ~200 | Low |
| `lib/models/opencode_model_capabilities.dart` | **NEW** | ~50 | Low |
| `lib/services/opencode_api_client.dart` | **NEW** | ~250 | Medium |
| `lib/services/opencode_connection_manager.dart` | **NEW** | ~60 | Low |
| `lib/services/opencode_llm_service.dart` | **NEW** | ~300 | Medium |
| `lib/services/opencode_model_visibility_service.dart` | **NEW** | ~80 | Low |
| `lib/services/llm_service.dart` | **MODIFY** | ~5 | Low |
| `lib/services/inference_config_service.dart` | **MODIFY** | ~50 | Low |
| `lib/services/unified_model_service.dart` | **MODIFY** | ~30 | Low |
| `lib/services/chat_service.dart` | **MODIFY** | ~150 | **High** |
| `lib/models/model_capability_resolver.dart` | **MODIFY** | ~15 | Low |
| `lib/main.dart` | **MODIFY** | ~40 | Medium |
| `lib/screens/settings_screen.dart` | **MODIFY** | ~100 | Medium |
| `lib/screens/models_screen.dart` | **MODIFY** | ~50 | Medium |

**Total new code:** ~1,030 lines across 7 new files  
**Total modified code:** ~440 lines across 7 existing files  
**Highest risk:** `chat_service.dart` — the routing logic is the most complex change

---

*End of Architecture Document*
