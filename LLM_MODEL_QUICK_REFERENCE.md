# LLM Model Configuration - Quick Reference

## Key File Locations

| Purpose | File Path | Lines | Key Class |
|---------|-----------|-------|-----------|
| **Ollama Model Registry** | `lib/ollama_toolkit/models/ollama_model.dart` | 528 | `ModelRegistry` (65 models) |
| **On-Device Model Registry** | `lib/models/on_device_model_capabilities.dart` | 109 | `OnDeviceModelCapabilitiesRegistry` (5 models) |
| **Model Capability Resolver** | `lib/models/model_capability_resolver.dart` | 43 | `ModelCapabilityResolver` |
| **LLM Service Interface** | `lib/services/llm_service.dart` | 177 | `LLMService` (abstract) |
| **Ollama Service** | `lib/services/ollama_llm_service.dart` | 217 | `OllamaLLMService` |
| **On-Device Service** | `lib/services/on_device_llm_service.dart` | 251 | `OnDeviceLLMService` |
| **Ollama API Client** | `lib/ollama_toolkit/services/ollama_client.dart` | 364 | `OllamaClient` |
| **Model Download Service** | `lib/services/model_download_service.dart` | 598 | `ModelDownloadService` |
| **Model Manager** | `lib/services/model_manager.dart` | 305 | `ModelManager` |
| **Connection Manager** | `lib/services/ollama_connection_manager.dart` | 99 | `OllamaConnectionManager` |
| **Chat Service** | `lib/services/chat_service.dart` | 2585 | `ChatService` |
| **Unified Models** | `lib/services/unified_model_service.dart` | 139 | `UnifiedModelService` |

---

## How to Add a New Ollama Model

### 1. Add Entry to ModelRegistry in `ollama_model.dart`

```dart
'mymodel': ModelCapabilities(
  supportsToolCalling: true,
  supportsVision: false,
  supportsAudio: false,
  supportsThinking: false,
  contextWindow: 128000,
  modelFamily: 'mymodelfamily',
  aliases: ['mymodel:7b', 'mymodel:latest'],
  description: 'My custom model',
  useCases: ['general chat', 'tool calling'],
),
```

### 2. Model Name Normalization
- Automatically removes version tags (`:7b`, `:latest`)
- Automatically matches aliases
- Case-insensitive matching
- Handles separator variations (`-` vs `.`)

### Example Lookups:
```dart
ModelRegistry.getCapabilities('mymodel');         // ✅ Found
ModelRegistry.getCapabilities('mymodel:7b');      // ✅ Found (via alias)
ModelRegistry.getCapabilities('MyModel:Latest');  // ✅ Found (case-insensitive)
```

---

## How to Add a New On-Device Model

### 1. Add to OnDeviceModelCapabilitiesRegistry

```dart
'mynewmodel': ModelCapabilities(
  supportsToolCalling: true,
  supportsVision: false,
  supportsAudio: false,
  supportsThinking: false,
  contextWindow: 4096,
  modelFamily: 'mymodelfamily',
  aliases: ['mynewmodel-it'],
  description: 'My on-device model',
  useCases: ['on-device inference'],
),
```

### 2. Add to ModelDownloadService.availableModels

```dart
'mynewmodel': LiteRTModel(
  id: 'mynewmodel',
  name: 'My New Model',
  description: 'Description here',
  sizeBytes: 1234567890,  // Size in bytes
  downloadUrl: 'https://huggingface.co/...',
  capabilities: ['text', 'tools'],  // What it supports
  contextSize: 4096,
  quantization: '4-bit',  // or '8-bit'
),
```

### 3. Models are Accessed via `local:` Prefix

```dart
// User selects: 'local:mynewmodel'
// ModelCapabilityResolver automatically uses OnDeviceModelCapabilitiesRegistry
```

---

## Model Capability Fields

```dart
class ModelCapabilities {
  bool supportsToolCalling;      // Can call external functions
  bool supportsVision;            // Can process images
  bool supportsAudio;             // Can process audio
  bool supportsThinking;          // Has explicit reasoning mode
  int contextWindow;              // Max tokens (e.g., 128000)
  String? modelFamily;            // Series name (e.g., 'llama')
  List<String> aliases;           // Alternative names
  String? description;            // Human-readable description
  List<String>? useCases;         // Recommended use cases
}
```

---

## Service Selection Flow

```
User selects model 'qwen2.5:7b'
         ↓
ChatService.sendMessage(modelName: 'qwen2.5:7b')
         ↓
modelName.startsWith('local:') ? No
         ↓
Use OllamaLLMService
         ↓
ModelRegistry.getCapabilities('qwen2.5:7b')
         ↓
Returns: ModelCapabilities(
  supportsToolCalling: true,
  supportsVision: false,
  ...
)
         ↓
UI adjusts UI controls based on capabilities
```

---

## Adding a New API Provider (e.g., OpenAI)

### File Structure Needed:
```
lib/
├── providers/
│   └── openai_models.dart         [Model registry]
├── services/
│   ├── openai_llm_service.dart    [LLMService implementation]
│   └── openai_connection_manager.dart [Connection handling]
└── openai/
    └── services/
        └── openai_client.dart     [HTTP API client]
```

### Key Steps:
1. Create `OpenAIModelRegistry` with model metadata
2. Implement `OpenAILLMService extends LLMService`
3. Update `ModelCapabilityResolver` to check for 'openai:' prefix
4. Update `ChatService` to route 'openai:' models to `OpenAILLMService`
5. Implement `OpenAIClient` for HTTP communication

---

## Configuration Keys (SharedPreferences)

### Ollama Configuration
```
'ollama_base_url'           // http://localhost:11434
'ollama_timeout'            // seconds
'ollama_default_model'      // model name
'ollama_last_used_model'    // for history
'ollama_stream_enabled'     // boolean
'ollama_model_history'      // JSON array
```

### On-Device Configuration
```
'litert_preferred_backend'  // 'cpu', 'gpu', 'npu'
'litert_auto_unload'        // boolean
'litert_last_model'         // model ID
```

### Inference Configuration
```
'inference_mode'            // 'remote' or 'onDevice'
'inference_temperature'     // 0.0-2.0
'inference_max_tokens'      // integer
'inference_top_k'           // integer
'inference_top_p'           // 0.0-1.0
'inference_repetition_penalty' // float
```

---

## Currently Registered Models

### Ollama (65 models)

**Tool Support (37 models)**
- All Llama, Qwen, DeepSeek, Mistral, Phi variants with tool calling
- Access via: `ModelRegistry.findModelsByCapability(supportsToolCalling: true)`

**Vision Support (6 models)**
- llama3.2, pixtral, gemma3, qwen3-vl, mistral-nemo, ministral-3
- Access via: `ModelRegistry.findModelsByCapability(supportsVision: true)`

**Thinking Support (3 models)**
- deepseek-v3, gpt-oss, qwen3
- Access via: `ModelRegistry.findModelsByCapability(supportsThinking: true)`

### On-Device (5 models)

All support tool calling.
- 2 models: Gemma 3n (multimodal with vision + audio)
- 3 models: Text-only (Gemma 3 1B, Phi-4 Mini, Qwen 2.5 1.5B)

---

## Common Tasks

### Get Model Capabilities
```dart
final caps = ModelCapabilityResolver.getCapabilities('llama3.2');
if (caps?.supportsVision ?? false) {
  // Show image upload button
}
```

### Check If Model Supports Feature
```dart
bool hasVision = ModelCapabilityResolver.supportsVision('llama3.2');
bool hasTools = ModelRegistry.supportsToolCalling('qwen2.5');
```

### List All Models with Capability
```dart
final toolModels = ModelRegistry.findModelsByCapability(
  supportsToolCalling: true,
  supportsVision: false,
);
```

### Get All Model Families
```dart
final families = ModelRegistry.getAllModelFamilies();
// ['deepseek', 'gemma', 'mistral', 'phi', 'qwen', ...]
```

### Check Model Availability
```dart
final available = await ollamaService.isAvailable();
final localAvailable = await onDeviceService.isAvailable();
```

---

## Default Values

| Setting | Default | Min | Max |
|---------|---------|-----|-----|
| Ollama Base URL | localhost:11434 | N/A | N/A |
| Ollama Timeout | 120 sec | 30 sec | 600 sec |
| Temperature | 0.7 | 0.0 | 2.0 |
| Max Tokens | 512 | 1 | 131072 |
| Top K | 40 | 1 | 100 |
| Top P | 0.9 | 0.0 | 1.0 |
| Repetition Penalty | 1.0 | 0.0 | 2.0 |
| LiteRT Backend | GPU | cpu/gpu/npu | N/A |
| Auto-Unload Timeout | 5 min | N/A | N/A |

---

## Testing Model Configuration

### Unit Tests Location
- `test/models/model_capability_resolver_test.dart`
- `test/models/model_capabilities_test.dart`
- `test/ollama_toolkit/models/ollama_model_test.dart`

### Run Tests
```bash
flutter test test/models/
```

---

## Debugging Model Selection

### Enable Debug Logging
In `chat_service.dart`, set:
```dart
static const bool _debugLogging = true;
```

### Check Current Model
```dart
print('Current Model ID: ${chatService.onDeviceLLMService?.currentModelId}');
print('Inference Mode: ${chatService.currentInferenceMode}');
```

### List Available Models
```dart
final models = await unifiedModelService.getUnifiedModelList(ollamaModels);
for (final model in models) {
  print('${model.name}: ${model.capabilities}');
}
```

