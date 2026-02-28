# LLM Model Configuration and Integration Analysis
## Private Chat Hub - Codebase Structure

### Overview
The Private Chat Hub is a Flutter application that implements a hybrid LLM inference system supporting both:
1. **Remote inference** via Ollama server
2. **On-device inference** via Google LiteRT-LM

The architecture uses an abstract `LLMService` interface that allows seamless switching between backend implementations.

---

## 1. Model Configuration Architecture

### 1.1 Core Model Configuration Files

#### **File: `/lib/ollama_toolkit/models/ollama_model.dart`** (528 lines)
This is the PRIMARY model registry for Ollama-compatible models.

**Key Classes:**
- `ModelCapabilities`: Data class defining model capabilities
  - `supportsToolCalling` (bool): Function calling support
  - `supportsVision` (bool): Image input support
  - `supportsAudio` (bool): Audio input support
  - `supportsThinking` (bool): Reasoning/thinking mode support
  - `contextWindow` (int): Max context tokens
  - `modelFamily` (string): Model series (e.g., 'llama', 'qwen')
  - `aliases` (List<String>): Alternative names for model
  - `description` (string): Human-readable description
  - `useCases` (List<String>): Recommended use cases

- `ModelRegistry`: Static registry of all Ollama models (65 entries)
  
**Registered Model Families:**
- **Llama**: llama3.1, llama3.2, llama3.3, llama2-70b
- **Qwen**: qwen2.5, qwen2.5-coder, qwen3, qwen3-vl
- **DeepSeek**: deepseek-v3, deepseek-coder
- **Mistral**: mistral, mistral-large, mixtral, codestral, pixtral, mistral-nemo
- **Gemma**: gemma2, gemma3
- **Phi**: phi3, phi4
- **Community/Other**: vicuna, alpaca, gpt4all, mpt-30b, gpt-oss

**Lookup Methods:**
- `getCapabilities(String modelName)`: Direct model lookup with alias resolution
- `findModelsByCapability()`: Filter models by specific capabilities
- `getAllModelNames()`: List all registered models
- `getAllModelFamilies()`: List unique model families
- Normalization: Removes version tags (`:8b`, `:latest`)
- Canonicalization: Handles separator variations (`-` vs `.`)

---

#### **File: `/lib/models/on_device_model_capabilities.dart`** (109 lines)
Registry for LiteRT on-device models (kept separate from Ollama models).

**Registered On-Device Models:**
- `gemma3-1b`: Gemma 3 1B - text + tools
- `gemma-3n-e2b`: Gemma 3n E2B - multimodal (text, vision, audio, tools)
- `gemma-3n-e4b`: Gemma 3n E4B - multimodal (text, vision, audio, tools)
- `phi-4-mini`: Phi-4 Mini - text + tools
- `qwen2.5-1.5b`: Qwen 2.5 1.5B - multilingual + tools

**Key Feature:**
- Intentionally separate from `ModelRegistry` to keep on-device and remote metadata independent
- Same capability interface as Ollama models

---

#### **File: `/lib/models/model_capability_resolver.dart`** (43 lines)
Unified resolver that determines which registry to use.

**Logic:**
```dart
if (modelName.startsWith('local:')) {
  return OnDeviceModelCapabilitiesRegistry.getCapabilities(modelName);
} else {
  return ModelRegistry.getCapabilities(modelName);
}
```

**Default Unknown Capability:**
```dart
Unknown = ModelCapabilities(
  supportsToolCalling: false,
  supportsVision: false,
  supportsAudio: false,
  supportsThinking: false,
  contextWindow: 4096,
)
```

---

### 1.2 Model Download Service

#### **File: `/lib/services/model_download_service.dart`** (598 lines)
Manages on-device model downloads and lifecycle.

**Defined LiteRT Models (5 total):**
```dart
availableModels = {
  'gemma3-1b': LiteRTModel(
    id: 'gemma3-1b',
    name: 'Gemma 3 1B',
    sizeBytes: 584056320,  // ~557 MB
    downloadUrl: 'https://huggingface.co/litert-community/...',
    capabilities: ['text', 'tools'],
    contextSize: 4096,
    quantization: '4-bit',
  ),
  'gemma-3n-e2b': LiteRTModel(...),  // 2.9 GB, multimodal
  'gemma-3n-e4b': LiteRTModel(...),  // 4.1 GB, multimodal
  'phi-4-mini': LiteRTModel(...),     // 3.6 GB
  'qwen2.5-1.5b': LiteRTModel(...),   // 1.5 GB
}
```

**Key Methods:**
- `getAvailableModels()`: Returns all models with download status
- `getDownloadedModels()`: Returns only downloaded models
- `downloadModel(modelId)`: Stream-based download with progress tracking
- `isModelDownloaded(modelId)`: Check if model file exists

---

## 2. API Provider Integration

### 2.1 Ollama Integration

#### **File: `/lib/ollama_toolkit/services/ollama_client.dart`** (364 lines)
HTTP client for Ollama API.

**API Endpoints Implemented:**
- `/api/generate` - Text generation
- `/api/chat` - Chat completions (with streaming)
- `/api/embeddings` - Embedding generation
- `/api/pull` - Download models
- `/api/delete` - Delete models
- `/api/tags` - List available models
- `/api/show` - Model information
- `/api/health` - Server health check

**Streaming Support:**
- `Stream<OllamaGenerateResponse> generateStream()`
- `Stream<OllamaChatResponse> chatStream()`

**Configuration:**
```dart
OllamaClient({
  baseUrl = 'http://localhost:11434',
  timeout = Duration(seconds: 60),
  httpClient = http.Client(),
})
```

---

#### **File: `/lib/ollama_toolkit/services/ollama_config_service.dart`** (164 lines)
SharedPreferences-based configuration persistence.

**Configuration Keys:**
```dart
OllamaConfigKeys {
  baseUrl: 'ollama_base_url'
  timeout: 'ollama_timeout'
  defaultModel: 'ollama_default_model'
  lastUsedModel: 'ollama_last_used_model'
  streamEnabled: 'ollama_stream_enabled'
  modelHistory: 'ollama_model_history'
  developerMode: 'developer_mode_enabled'
}
```

**Configuration Defaults:**
- `defaultBaseUrl`: 'http://localhost:11434'
- `defaultTimeout`: 120 seconds
- `maxTimeout`: 600 seconds
- `minTimeout`: 30 seconds
- `maxHistorySize`: 10 models

---

#### **File: `/lib/services/ollama_connection_manager.dart`** (99 lines)
Manages Ollama server connections and client lifecycle.

**Configuration:**
```dart
OllamaConnectionManager {
  _connection: Connection      // Connection profile
  _client: OllamaClient?       // Configured API client
  _timeout: Duration           // Request timeout
}
```

**Connection Model:**
```dart
Connection {
  id: String
  name: String
  host: String
  port: int (default: 11434)
  useHttps: bool (default: false)
  isDefault: bool
  createdAt: DateTime
  lastConnectedAt: DateTime?
}
```

**URL Construction:**
```dart
String get url => '${useHttps ? 'https' : 'http'}://$host:$port'
```

---

### 2.2 On-Device Integration

#### **File: `/lib/services/on_device_llm_service.dart`** (251 lines)
Implements `LLMService` interface for LiteRT-LM on-device inference.

**Dependencies:**
- `ModelManager`: Manages model lifecycle
- `LiteRTPlatformChannel`: Native platform channel to Android
- `InferenceConfigService`: Configuration parameters

**Key Methods:**
- `loadModel(modelId)`: Load model via platform channel
- `unloadModel()`: Free model memory
- `generateResponse()`: Stream text generation with conversation history
- `isAvailable()`: Check if LiteRT is available on device

**Configuration Parameters Used:**
- Temperature
- maxTokens
- topK
- topP
- repetitionPenalty

---

#### **File: `/lib/services/model_manager.dart`** (305 lines)
Manages on-device model lifecycle and state.

**State Management:**
- `loadedModelId`: Currently loaded model
- `preferredBackend`: GPU/CPU/NPU selection
- `autoUnloadEnabled`: Auto-unload after timeout
- `stateStream`: Broadcast stream of model state changes

**Backend Selection:**
```dart
setPreferredBackend(String backend) // 'cpu', 'gpu', 'npu'
```

**Auto-Unload:**
- Default timeout: 5 minutes
- Controlled via `setAutoUnload(bool)`
- Preferences persisted to SharedPreferences

---

## 3. Model Selection and Service Interface

### 3.1 Abstract LLM Service Interface

#### **File: `/lib/services/llm_service.dart`** (177 lines)

**Core Interface:**
```dart
abstract class LLMService {
  // Text generation with streaming
  Stream<String> generateResponse({
    required String prompt,
    required String modelId,
    List<Message>? conversationHistory,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
    List<Attachment>? attachments,
  });
  
  // Model management
  Future<bool> isAvailable();
  Future<List<ModelInfo>> getAvailableModels();
  Future<void> loadModel(String modelId);
  Future<void> unloadModel();
  String? get currentModelId;
  bool isModelLoaded(String modelId);
  
  // Resource cleanup
  Future<void> dispose();
}
```

**ModelInfo Data Class:**
```dart
class ModelInfo {
  final String id;
  final String name;
  final String description;
  final int sizeBytes;
  final bool isDownloaded;
  final List<String> capabilities;
  final String? downloadUrl;
  final bool isLocal;
  
  // Computed properties
  bool get supportsVision => capabilities.contains('vision');
  bool get supportsAudio => capabilities.contains('audio');
  bool get supportsTools => capabilities.contains('tools');
}
```

**Inference Mode Enum:**
```dart
enum InferenceMode {
  remote,   // Ollama server
  onDevice, // LiteRT-LM
}
```

---

### 3.2 Service Implementations

#### **File: `/lib/services/ollama_llm_service.dart`** (217 lines)
Ollama implementation of `LLMService` interface.

**Key Methods:**
- `generateResponse()`: Wraps Ollama chat API with streaming
- `getAvailableModels()`: Lists models from connected Ollama instance
- `loadModel()`: Tracks model (Ollama auto-loads)
- `isAvailable()`: Verifies connection by calling `listModels()`

**Message Format Conversion:**
- App `Message` → `OllamaMessage`
- Handles image attachments as base64 strings
- Builds conversation history in Ollama format

---

#### **File: `/lib/services/unified_model_service.dart`** (139 lines)
Combines both local and remote model sources.

**Features:**
- `getUnifiedModelList()`: Merges Ollama + on-device models
- Local model prefix: `local:` (avoids conflicts)
- Capability extraction from both sources
- Remote model caching to SharedPreferences for offline access

---

## 4. Integration with Chat Service

#### **File: `/lib/services/chat_service.dart`** (2585 lines)
Primary service coordinating chat with model selection.

**Inference Mode Management:**
```dart
// Get inference mode
InferenceMode get currentInferenceMode

// Set services
void setInferenceConfigService(InferenceConfigService service)
void setOnDeviceLLMService(OnDeviceLLMService service)

// Check availability
Future<bool> isOnDeviceAvailable()
```

**Model Selection Logic:**
- Infers which service to use based on model prefix
- `local:modelName` → On-device service
- Other names → Ollama service
- Falls back to demo mode if both unavailable

---

## 5. Model Registration Lookup Hierarchy

### Lookup Flow for Model Capabilities:

```
1. ModelCapabilityResolver.getCapabilities(modelName)
   │
   ├─ if modelName.startswith('local:')
   │  └─→ OnDeviceModelCapabilitiesRegistry.getCapabilities()
   │
   └─ else
      └─→ ModelRegistry.getCapabilities()
         ├─ Normalize model name (remove version tags)
         ├─ Try direct lookup
         ├─ Try canonical lookup (handle separator variations)
         └─ Try alias matching
         └─ Return null if not found
```

### Model Name Normalization:
- Remove `local:` prefix
- Remove version tags (e.g., `:8b`, `:latest`)
- Convert to lowercase
- Handle separator variations (`.` vs `-`)

---

## 6. File Structure Summary

```
lib/
├── models/
│   ├── model_capability_resolver.dart      [Unified resolver]
│   ├── on_device_model_capabilities.dart   [LiteRT registry]
│   ├── connection.dart                      [Connection profile]
│   └── message.dart                         [Message + Attachment]
│
├── services/
│   ├── llm_service.dart                    [Abstract interface]
│   ├── ollama_llm_service.dart             [Ollama implementation]
│   ├── on_device_llm_service.dart          [LiteRT implementation]
│   ├── unified_model_service.dart          [Combined models]
│   ├── ollama_connection_manager.dart      [Connection management]
│   ├── model_manager.dart                  [On-device lifecycle]
│   ├── model_download_service.dart         [Model downloads]
│   ├── chat_service.dart                   [Chat coordination]
│   ├── inference_config_service.dart       [Parameter config]
│   └── ...other services
│
├── ollama_toolkit/
│   ├── models/
│   │   ├── ollama_model.dart               [Model registry: 65 entries]
│   │   ├── ollama_message.dart
│   │   ├── ollama_request.dart
│   │   ├── ollama_response.dart
│   │   └── ollama_tool.dart
│   │
│   ├── services/
│   │   ├── ollama_client.dart              [HTTP API client]
│   │   └── ollama_config_service.dart      [Config persistence]
│   │
│   └── thinking_loop/
│       ├── agent.dart
│       ├── ollama_agent.dart
│       ├── memory.dart
│       └── tools.dart
│
└── main.dart                               [App initialization]
```

---

## 7. Key Design Patterns

### 7.1 Service Abstraction
- **Pattern**: Strategy pattern via `LLMService` interface
- **Benefit**: Easy to add new providers without changing chat logic
- **Usage**: ChatService accepts either `OllamaLLMService` or `OnDeviceLLMService`

### 7.2 Registry Pattern
- **Pattern**: Static maps for model metadata
- **Benefit**: O(1) lookups, no database required
- **Locations**: `ModelRegistry`, `OnDeviceModelCapabilitiesRegistry`

### 7.3 Configuration Management
- **Pattern**: SharedPreferences for persistence
- **Benefit**: Survives app restarts
- **Services**: `OllamaConfigService`, `InferenceConfigService`

### 7.4 Hybrid Inference
- **Pattern**: Dual service architecture
- **Benefit**: User can switch between local and remote at runtime
- **Coordination**: `ChatService` route requests based on model name

---

## 8. Adding New Providers (Future Extension Points)

To add a new LLM provider (e.g., OpenAI, Anthropic, LM Studio):

### Step 1: Create Provider Model Registry
```dart
// lib/providers/[provider]_models.dart
class [Provider]ModelRegistry {
  static const Map<String, ModelCapabilities> _registry = {
    'model-name': ModelCapabilities(...),
  };
  
  static ModelCapabilities? getCapabilities(String modelName) { ... }
}
```

### Step 2: Implement LLMService
```dart
// lib/services/[provider]_llm_service.dart
class [Provider]LLMService implements LLMService {
  Stream<String> generateResponse({ ... }) { ... }
  Future<List<ModelInfo>> getAvailableModels() { ... }
  // ... implement other interface methods
}
```

### Step 3: Create API Client (if needed)
```dart
// lib/[provider]/services/[provider]_client.dart
class [Provider]Client {
  Future<[Provider]Response> chat(...) { ... }
  Stream<[Provider]Response> chatStream(...) { ... }
}
```

### Step 4: Update ModelCapabilityResolver
```dart
// In lib/models/model_capability_resolver.dart
static ModelCapabilities? getCapabilities(String modelName) {
  if (_isLocalModel(modelName)) {
    return OnDeviceModelCapabilitiesRegistry.getCapabilities(modelName);
  }
  if (_is[Provider]Model(modelName)) {
    return [Provider]ModelRegistry.getCapabilities(modelName);
  }
  return ModelRegistry.getCapabilities(modelName);
}
```

### Step 5: Update ChatService
```dart
// Route model names to appropriate service
if (model.startsWith('[provider]:')) {
  return _[provider]LLMService.generateResponse(...);
}
```

---

## 9. Current Limitations & TODO

1. **OpenAI/Anthropic**: Not yet integrated
2. **Model Streaming**: Available for Ollama, partially for on-device
3. **Tool Calling**: Framework exists but not fully integrated in chat
4. **Vision Support**: Implemented in Ollama models, partial in on-device
5. **Audio Support**: Framework in place, limited implementation

---

## 10. Configuration Summary

| Configuration | Source | Persistence | Default |
|---|---|---|---|
| Ollama Base URL | OllamaConfigService | SharedPreferences | http://localhost:11434 |
| Ollama Timeout | OllamaConfigService | SharedPreferences | 120 seconds |
| Default Model | OllamaConfigService | SharedPreferences | None |
| Inference Mode | InferenceConfigService | SharedPreferences | Remote |
| LiteRT Backend | ModelManager | SharedPreferences | GPU |
| Auto-Unload | ModelManager | SharedPreferences | Enabled |
| Temperature | InferenceConfigService | SharedPreferences | 0.7 |
| Max Tokens | InferenceConfigService | SharedPreferences | 512 |

---

## 11. Model Registry Statistics

### Ollama Models: 65 registered entries
- **By Family**: Llama (4), Qwen (4), DeepSeek (2), Mistral (6), Gemma (2), Phi (2), Community (39)
- **Tool Support**: 37 models
- **Vision Support**: 6 models
- **Thinking Support**: 3 models

### LiteRT Models: 5 registered entries
- **All have**: Tool calling support
- **Multimodal (vision+audio)**: 2 models
- **Text-only**: 3 models

