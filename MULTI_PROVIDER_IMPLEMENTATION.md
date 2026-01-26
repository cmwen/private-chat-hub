# Multi-Provider Implementation Guide

## Overview

This document describes the multi-provider architecture implemented in Private Chat Hub, supporting three AI model providers:

1. **Ollama** - Self-hosted local models
2. **LiteRT (MediaPipe)** - On-device inference with TensorFlow Lite
3. **OpenAI-compatible** - Cloud APIs via LiteLLM proxy

## Architecture

### Provider Abstraction Layer

All providers implement the unified `ChatProvider` interface:

```dart
abstract class ChatProvider {
  Stream<String> streamChat({
    required String model,
    required List<Map<String, String>> messages,
    String? systemPrompt,
  });
  
  Future<void> dispose();
  String get providerName;
}
```

### Implementation Status

#### ✅ Completed Core Infrastructure

1. **Domain Layer**
   - `ProviderType` enum (ollama, litert, openai)
   - `ModelProviderConfig` (Freezed union type for provider configurations)
   - `LiteRTModel` entity with download/initialization states
   - Updated `Conversation` entity with provider fields

2. **Data Layer**
   - `ChatProvider` interface
   - `OllamaApiClient` (existing, implements streaming chat)
   - `LiteRTApiClient` (MediaPipe integration via MethodChannel)
   - `OpenAIApiClient` (OpenAI-compatible streaming)
   - Database schema v2 with provider support

3. **Build System**
   - Dependencies added (http for OpenAI)
   - Freezed code generation successful
   - Zero compilation errors

#### ⚠️ Pending UI Integration

The following UI components need implementation to complete the feature:

1. **Settings Management**
   - Store OpenAI API keys
   - Configure LiteLLM endpoint
   - Manage provider preferences

2. **LiteRT Model Management Screen**
   - Download models to device
   - List installed models
   - Delete models

3. **Provider Selection UI**
   - Choose provider in conversation creation
   - Switch providers in existing conversations
   - Provider-specific settings in connection dialog

4. **ChatScreen Integration**
   - Instantiate correct provider based on conversation
   - Handle provider-specific errors
   - Show provider status indicators

## Provider Details

### 1. Ollama Provider

**Status**: ✅ Fully Implemented (v1.0)

**Features**:
- Real-time streaming responses
- Model management (pull, list, delete)
- Connection profiles
- Health checks

**Configuration**:
```dart
ModelProviderConfig.ollama(
  host: 'localhost',
  port: 11434,
  modelName: 'llama3.2',
)
```

### 2. LiteRT Provider

**Status**: 🔨 Backend Ready, Native Implementation Pending

**Implementation**: `lib/data/datasources/remote/litert_api_client.dart`

**Required Native Code** (not included):

Create `android/app/src/main/kotlin/.../LiteRTPlugin.kt`:

```kotlin
class LiteRTPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var llmInference: LlmInference? = null
    
    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, 
            "com.cmwen.private_chat_hub/litert")
        channel.setMethodCallHandler(this)
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeModel" -> {
                val modelPath = call.argument<String>("modelPath")
                val maxTokens = call.argument<Int>("maxTokens") ?: 512
                val temperature = call.argument<Double>("temperature") ?: 0.7
                val topK = call.argument<Int>("topK") ?: 40
                
                try {
                    llmInference = LlmInference.createFromFile(
                        context = context,
                        modelPath = modelPath,
                        options = LlmInference.LlmInferenceOptions.builder()
                            .setMaxTokens(maxTokens)
                            .setTemperature(temperature.toFloat())
                            .setTopK(topK)
                            .build()
                    )
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INIT_ERROR", e.message, null)
                }
            }
            
            "generateText" -> {
                val prompt = call.argument<String>("prompt")
                GlobalScope.launch(Dispatchers.IO) {
                    try {
                        llmInference?.generateResponseAsync(prompt)
                            ?.collect { partialResult ->
                                channel.invokeMethod("onToken", partialResult)
                            }
                        channel.invokeMethod("onComplete", null)
                    } catch (e: Exception) {
                        channel.invokeMethod("onError", e.message)
                    }
                }
                result.success(true)
            }
            
            "disposeModel" -> {
                llmInference?.close()
                llmInference = null
                result.success(true)
            }
        }
    }
}
```

**Dependencies** (add to `android/app/build.gradle.kts`):

```kotlin
dependencies {
    implementation("com.google.mediapipe:tasks-genai:latest")
}
```

**Model Setup**:

1. Download a LiteRT model (e.g., Gemma 2B)
2. Place in `android/app/src/main/assets/` or use app storage
3. Initialize with model path

**Configuration**:
```dart
ModelProviderConfig.litert(
  modelPath: '/data/user/0/com.cmwen.private_chat_hub/files/gemma-2b.bin',
  maxTokens: 512,
  temperature: 0.7,
  topK: 40,
)
```

**Reference**: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference

### 3. OpenAI-Compatible Provider (LiteLLM)

**Status**: ✅ Backend Implemented

**Implementation**: `lib/data/datasources/remote/openai_api_client.dart`

**Features**:
- Server-sent events (SSE) streaming
- OpenAI Chat Completions API compatible
- Works with LiteLLM, OpenAI, and compatible proxies

**LiteLLM Setup**:

```bash
pip install litellm[proxy]

litellm --config config.yaml
```

**LiteLLM Config** (`config.yaml`):

```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: gpt-4
      api_key: sk-...
      
  - model_name: claude-3
    litellm_params:
      model: anthropic/claude-3-sonnet
      api_key: sk-ant-...
      
  - model_name: gemini-pro
    litellm_params:
      model: gemini/gemini-pro
      api_key: ...
```

**Configuration**:
```dart
ModelProviderConfig.openai(
  baseUrl: 'http://localhost:4000',  // LiteLLM proxy
  apiKey: 'sk-1234',
  modelName: 'gpt-4',
  temperature: 0.7,
  maxTokens: 2000,
)
```

## Database Schema

### Conversations Table (v2)

```sql
CREATE TABLE conversations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  model_name TEXT,
  system_prompt TEXT,
  is_archived INTEGER DEFAULT 0,
  provider_type TEXT DEFAULT 'ollama',  -- NEW
  provider_config TEXT                   -- NEW (JSON)
)
```

**Migration from v1 to v2**:
- Adds `provider_type` column (default: 'ollama')
- Adds `provider_config` column for JSON configuration

## Usage Example

### Creating a Conversation with Provider

```dart
final conversation = Conversation(
  id: 0,
  title: 'Chat with GPT-4',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  providerType: ProviderType.openai,
  providerConfig: jsonEncode({
    'baseUrl': 'http://localhost:4000',
    'apiKey': 'sk-1234',
    'modelName': 'gpt-4',
  }),
);

await dbHelper.insertConversation(conversation);
```

### Using a Provider

```dart
ChatProvider? provider;

switch (conversation.providerType) {
  case ProviderType.ollama:
    provider = OllamaApiClient(baseUrl: 'http://localhost:11434');
    
  case ProviderType.litert:
    provider = LiteRTApiClient(
      modelPath: '/path/to/model.bin',
      maxTokens: 512,
      temperature: 0.7,
    );
    await (provider as LiteRTApiClient).initialize();
    
  case ProviderType.openai:
    provider = OpenAIApiClient(
      baseUrl: 'http://localhost:4000',
      apiKey: 'sk-1234',
      model: 'gpt-4',
    );
}

await for (final chunk in provider.streamChat(
  model: modelName,
  messages: messages,
  systemPrompt: systemPrompt,
)) {
  print(chunk);
}

await provider.dispose();
```

## Next Steps

### High Priority (for MVP)

1. **Settings Repository Extensions**
   ```dart
   Future<void> setOpenAIApiKey(String key);
   Future<String?> getOpenAIApiKey();
   Future<void> setLiteLLMEndpoint(String url);
   Future<String?> getLiteLLMEndpoint();
   ```

2. **Provider Factory**
   ```dart
   class ProviderFactory {
     static Future<ChatProvider> create(Conversation conversation);
   }
   ```

3. **Update ChatScreen**
   - Replace hardcoded Ollama client with provider factory
   - Handle provider initialization/disposal
   - Show provider-specific errors

### Medium Priority (for v1.5)

1. **Provider Selection UI**
   - Radio buttons in conversation creation
   - Provider-specific configuration forms
   - Validation and testing

2. **LiteRT Model Management**
   - Model download UI with progress
   - List installed models with metadata
   - Delete models to free space

3. **Connection Settings Enhancement**
   - Tabbed interface for each provider
   - Save multiple OpenAI configurations
   - Test connection for each provider

### Low Priority (polish)

1. **Provider Status Indicators**
   - Show active provider in conversation list
   - Provider icons and badges
   - Connection quality indicators

2. **Cost Tracking**
   - Track token usage for cloud providers
   - Estimate costs per conversation
   - Usage analytics

3. **Smart Routing**
   - Fallback to alternative providers
   - Load balancing across providers
   - Automatic provider selection

## Testing

### Unit Tests

```dart
test('OpenAI client streams responses', () async {
  final client = OpenAIApiClient(
    baseUrl: 'http://mock-server',
    apiKey: 'test-key',
    model: 'gpt-4',
  );
  
  final chunks = await client.streamChat(
    model: 'gpt-4',
    messages: [{'role': 'user', 'content': 'Hello'}],
  ).toList();
  
  expect(chunks.isNotEmpty, true);
});
```

### Integration Tests

1. Test Ollama with local server
2. Test LiteRT with sample model
3. Test OpenAI with LiteLLM proxy

## File Structure

```
lib/
├── domain/
│   ├── entities/
│   │   ├── conversation.dart          # Updated with provider fields
│   │   ├── model_provider.dart        # Provider configuration union
│   │   └── litert_model.dart          # LiteRT model entity
│   └── repositories/
│       └── i_chat_provider.dart       # Provider interface
│
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   └── database_helper.dart   # v2 schema with providers
│   │   └── remote/
│   │       ├── ollama_api_client.dart  # Existing
│   │       ├── litert_api_client.dart  # New (LiteRT)
│   │       └── openai_api_client.dart  # New (OpenAI-compatible)
│   └── repositories/
│       └── settings_repository.dart    # Extend for API keys
│
└── presentation/
    └── screens/
        ├── chat_screen.dart           # Update for multi-provider
        ├── litert_models_screen.dart  # New (model management)
        └── provider_settings.dart     # New (provider config)
```

## Compilation Status

```bash
flutter analyze
```

**Result**: ✅ 0 errors, 12 info/warnings (cosmetic only)

- No blocking issues
- Ready for UI implementation
- All backend logic compiles successfully

## Contributing

When adding a new provider:

1. Implement `ChatProvider` interface
2. Add provider type to `ProviderType` enum
3. Extend `ModelProviderConfig` union
4. Update database migration if needed
5. Create provider-specific settings UI
6. Add integration tests

---

**Implementation Date**: January 26, 2026
**Status**: Backend Complete, UI Pending
**Next Release**: v1.5 (Multi-Provider Support)
