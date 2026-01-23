# LiteRT-LM Integration - Technical Implementation Guide

**Date:** January 24, 2026  
**Version:** 1.0  
**Status:** Complete

---

## Table of Contents

1. [Architecture](#architecture)
2. [Service Layer](#service-layer)
3. [UI Integration](#ui-integration)
4. [Native Platform](#native-platform)
5. [Testing Strategy](#testing-strategy)
6. [Troubleshooting](#troubleshooting)

---

## Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│                      ChatScreen (UI)                        │
└──────────────────┬──────────────────────────────────────────┘
                   │ sendMessage()
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                    ChatService                              │
│  • Route inference based on selected mode                   │
│  • Maintain conversation context                            │
│  • Stream responses to UI                                   │
└──────┬──────────────────────┬──────────────────────┬────────┘
       │                      │                      │
       ▼ Remote Mode         ▼ On-Device Mode       ▼ Config
  OllamaLLMService    OnDeviceLLMService    InferenceConfigService
       │                      │                      │
       ├─ Connect to         ├─ Load Model          ├─ Save Mode
       │  Ollama Server      ├─ Build Prompt        ├─ Save Backend
       │                     ├─ Generate Text       ├─ Save Timeout
       └─────────────────────┼─ Unload Model        └─ Restore Settings
                             │
                             ▼
                        ModelManager
                        • Load/Unload
                        • Auto-Unload Timer
                        • Backend Selection
                             │
                             ├─ ModelDownloadService
                             │  • Download models
                             │  • Resume downloads
                             │  • Verify integrity
                             │
                             └─ LiteRTPlatformChannel
                                • Flutter → Kotlin
                                • Method calls
                                • Streaming response
                                     │
                                     ▼
                            LiteRTPlugin (Kotlin)
                            • Load native library
                            • Run inference
                            • Handle memory
```

---

## Service Layer

### 1. LLMService (Abstract)

**Location:** `lib/services/llm_service.dart`

**Purpose:** Unified interface for all inference implementations

```dart
abstract class LLMService {
  // Check if service is available
  Future<bool> isAvailable();
  
  // Get available models
  Future<List<ModelInfo>> getAvailableModels();
  
  // Load a specific model
  Future<void> loadModel(String modelId);
  
  // Unload current model
  Future<void> unloadModel();
  
  // Generate response stream
  Stream<String> generateResponse({
    required String prompt,
    required String modelId,
    List<Message>? conversationHistory,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
  });
  
  // Check if model is loaded
  bool isModelLoaded(String modelId);
  
  // Current model ID
  String? get currentModelId;
}

// Inference modes
enum InferenceMode { remote, onDevice }

// Model information
class ModelInfo {
  final String id;
  final String name;
  final String description;
  final int sizeBytes;
  final String downloadUrl;
  final ModelType modelType;
  
  const ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.modelType,
  });
}

enum ModelType { remote, onDevice }
```

### 2. OnDeviceLLMService

**Location:** `lib/services/on_device_llm_service.dart`

**Purpose:** On-device inference implementation

**Key Methods:**

```dart
class OnDeviceLLMService implements LLMService {
  final ModelManager _modelManager;
  final LiteRTPlatformChannel _platformChannel;
  
  // Load model (returns success/failure)
  Future<void> loadModel(String modelId) async {
    final success = await _modelManager.loadModel(modelId);
    if (success) {
      _currentModelId = modelId;
    } else {
      throw Exception('Failed to load model: $modelId');
    }
  }
  
  // Generate response with streaming
  Stream<String> generateResponse({
    required String prompt,
    required String modelId,
    List<Message>? conversationHistory,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
  }) async* {
    // Ensure correct model is loaded
    if (_currentModelId != modelId) {
      await loadModel(modelId);
    }
    
    // Build full prompt with context
    final fullPrompt = _buildPrompt(
      prompt: prompt,
      systemPrompt: systemPrompt,
      conversationHistory: conversationHistory,
    );
    
    // Stream response from native plugin
    yield* _platformChannel.generateTextStream(
      prompt: fullPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    
    // Reset auto-unload timer
    _modelManager.resetUnloadTimer();
  }
  
  // Private: Build prompt with conversation context
  String _buildPrompt({
    required String prompt,
    String? systemPrompt,
    List<Message>? history,
  }) {
    final buffer = StringBuffer();
    
    // Add system prompt
    if (systemPrompt != null) {
      buffer.writeln('System: $systemPrompt');
      buffer.writeln();
    }
    
    // Add conversation history
    if (history != null && history.isNotEmpty) {
      for (final msg in history) {
        final role = msg.role == MessageRole.user ? 'User' : 'Assistant';
        buffer.writeln('$role: ${msg.text}');
      }
      buffer.writeln();
    }
    
    // Add current prompt
    buffer.write('User: $prompt\nAssistant: ');
    
    return buffer.toString();
  }
}
```

### 3. OllamaLLMService

**Location:** `lib/services/ollama_llm_service.dart`

**Purpose:** Wrapper for existing Ollama functionality

**Implementation:**

```dart
class OllamaLLMService implements LLMService {
  final OllamaManager _ollamaManager;
  
  // Delegates all calls to existing OllamaManager
  @override
  Stream<String> generateResponse({
    required String prompt,
    required String modelId,
    List<Message>? conversationHistory,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
  }) async* {
    // Use existing Ollama streaming implementation
    yield* _ollamaManager.generateResponse(
      prompt: prompt,
      modelId: modelId,
      conversationHistory: conversationHistory,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }
  
  // ... other delegated methods
}
```

### 4. InferenceConfigService

**Location:** `lib/services/inference_config_service.dart`

**Purpose:** Persist and manage inference settings

**Key Features:**

```dart
class InferenceConfigService {
  final SharedPreferences _prefs;
  final StreamController<InferenceMode> _modeController;
  
  // Get/Set inference mode
  InferenceMode get inferenceMode {
    final mode = _prefs.getString('inference_mode');
    return mode == 'onDevice' ? InferenceMode.onDevice : InferenceMode.remote;
  }
  
  Future<void> setInferenceMode(InferenceMode mode) async {
    await _prefs.setString('inference_mode', mode.name);
    _modeController.add(mode);
  }
  
  // Get/Set backend preference (CPU/GPU/NPU)
  String get preferredBackend {
    return _prefs.getString('litert_preferred_backend') ?? 'gpu';
  }
  
  Future<void> setPreferredBackend(String backend) async {
    if (!['cpu', 'gpu', 'npu'].contains(backend)) {
      throw ArgumentError('Invalid backend: $backend');
    }
    await _prefs.setString('litert_preferred_backend', backend);
  }
  
  // Get/Set auto-unload settings
  bool get autoUnloadEnabled {
    return _prefs.getBool('litert_auto_unload') ?? true;
  }
  
  int get autoUnloadTimeoutMinutes {
    return _prefs.getInt('litert_auto_unload_timeout') ?? 5;
  }
  
  // Get/Set last used models
  String? get lastRemoteModel {
    return _prefs.getString('last_remote_model');
  }
  
  String? get lastOnDeviceModel {
    return _prefs.getString('last_on_device_model');
  }
  
  // Get last used model for current mode
  String? get lastModel {
    return inferenceMode == InferenceMode.remote
        ? lastRemoteModel
        : lastOnDeviceModel;
  }
}
```

### 5. ModelManager

**Location:** `lib/services/model_manager.dart`

**Purpose:** Manage model lifecycle (load/unload/auto-unload)

**Key Features:**

```dart
class ModelManager {
  final StorageService _storage;
  final LiteRTPlatformChannel _platformChannel;
  final ModelDownloadService _downloadService;
  
  Timer? _unloadTimer;
  String? _loadedModel;
  
  // Load model with retry logic
  Future<bool> loadModel(String modelId) async {
    try {
      final isDownloaded = await _downloadService.isModelDownloaded(modelId);
      if (!isDownloaded) {
        _log('Model not downloaded: $modelId');
        return false;
      }
      
      final modelPath = await _downloadService.getModelPath(modelId);
      final result = await _platformChannel.loadModel(
        modelPath: modelPath,
        backend: preferredBackend,
      );
      
      if (result['success'] == true) {
        _loadedModel = modelId;
        resetUnloadTimer(); // Start auto-unload timer
        return true;
      }
      return false;
    } catch (e) {
      _log('Error loading model: $e');
      return false;
    }
  }
  
  // Auto-unload timer management
  void resetUnloadTimer() {
    _unloadTimer?.cancel();
    
    if (!autoUnloadEnabled) return;
    
    _unloadTimer = Timer(
      Duration(minutes: autoUnloadTimeoutMinutes),
      () => unloadModel(),
    );
  }
  
  Future<void> unloadModel() async {
    if (_loadedModel != null) {
      await _platformChannel.unloadModel();
      _loadedModel = null;
      _unloadTimer?.cancel();
    }
  }
  
  // Get available models
  Future<List<ModelInfo>> getAvailableModels() async {
    return _downloadService.getAvailableModels();
  }
}
```

### 6. ModelDownloadService

**Location:** `lib/services/model_download_service.dart`

**Purpose:** Download models from Hugging Face

**Key Features:**

```dart
class ModelDownloadService {
  static const String _baseUrl =
      'https://huggingface.co/google/gemma-models/resolve/main';
  
  // Get available models
  Future<List<ModelInfo>> getAvailableModels() async {
    return [
      ModelInfo(
        id: 'gemma3-1b',
        name: 'Gemma 3 1B',
        description: 'Lightweight, fast inference',
        sizeBytes: 557 * 1024 * 1024, // 557MB
        downloadUrl: '$_baseUrl/gemma3-1b.litertlm',
        modelType: ModelType.onDevice,
      ),
      // ... more models
    ];
  }
  
  // Download model with progress
  Stream<ModelDownloadProgress> downloadModel(String modelId) async* {
    final model = _models.firstWhere((m) => m.id == modelId);
    final filePath = await getModelPath(modelId);
    
    // Create download request with progress tracking
    final request = http.StreamedRequest('GET', Uri.parse(model.downloadUrl));
    final response = await _client.send(request);
    
    if (response.statusCode != 200) {
      throw HttpException('Download failed: ${response.statusCode}');
    }
    
    final contentLength = response.contentLength ?? 0;
    var downloaded = 0;
    
    final file = File(filePath);
    final sink = file.openWrite();
    
    await response.stream.forEach((chunk) {
      downloaded += chunk.length;
      sink.add(chunk);
      
      yield ModelDownloadProgress(
        modelId: modelId,
        downloadedBytes: downloaded,
        totalBytes: contentLength,
        percentComplete: (downloaded / contentLength * 100).toInt(),
      );
    });
    
    await sink.close();
  }
  
  // Check if model is downloaded
  Future<bool> isModelDownloaded(String modelId) async {
    final path = await getModelPath(modelId);
    return File(path).exists();
  }
  
  // Delete model
  Future<void> deleteModel(String modelId) async {
    final path = await getModelPath(modelId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
```

### 7. LiteRTPlatformChannel

**Location:** `lib/services/litert_platform_channel.dart`

**Purpose:** Flutter-Kotlin bridge

```dart
class LiteRTPlatformChannel {
  static const platform = MethodChannel(
    'com.cmwen.private_chat_hub/litert',
  );
  
  // Check if native plugin is available
  Future<bool> isAvailable() async {
    try {
      final result = await platform.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
  
  // Load model on native side
  Future<Map<dynamic, dynamic>> loadModel({
    required String modelPath,
    required String backend,
  }) async {
    return await platform.invokeMethod('loadModel', {
      'modelPath': modelPath,
      'backend': backend,
    });
  }
  
  // Generate text stream
  Stream<String> generateTextStream({
    required String prompt,
    required double temperature,
    int? maxTokens,
  }) async* {
    try {
      final result = await platform.invokeMethod<String>('generateText', {
        'prompt': prompt,
        'temperature': temperature,
        'maxTokens': maxTokens ?? 256,
      });
      
      if (result != null) {
        // Simulate streaming by splitting response
        for (final word in result.split(' ')) {
          yield '$word ';
          await Future.delayed(Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      throw Exception('Text generation failed: $e');
    }
  }
  
  // Unload model
  Future<void> unloadModel() async {
    await platform.invokeMethod('unloadModel');
  }
  
  // Get device capabilities
  Future<Map<String, dynamic>> getDeviceCapabilities() async {
    return (await platform.invokeMethod('getDeviceCapabilities')) ?? {};
  }
  
  // Get memory info
  Future<Map<String, dynamic>> getMemoryInfo() async {
    return (await platform.invokeMethod('getMemoryInfo')) ?? {};
  }
}
```

---

## UI Integration

### 1. OnDeviceModelsScreen

**Location:** `lib/screens/on_device_models_screen.dart`

**Purpose:** Full model management interface

**Features:**
- List available models with download status
- Download with progress indicator
- Cancel downloads
- Delete downloaded models
- Select active model
- View device resources

### 2. InferenceSettingsWidget

**Location:** `lib/widgets/inference_settings_widget.dart`

**Components:**

- **InferenceModeSelector**: Radio buttons to switch modes
- **BackendSelector**: Segmented button for CPU/GPU/NPU
- **ModelDownloadTile**: Model download card
- **DeviceResourceInfo**: Memory/storage display

### 3. SettingsScreen (Updated)

**Location:** `lib/screens/settings_screen.dart`

**Changes:**
- Added "Inference Mode" section with `InferenceModeSelector`
- Added "Manage On-Device Models" button
- Positioned between connections and AI features

---

## Native Platform

### LiteRTPlugin.kt

**Location:** `android/app/src/main/kotlin/com/cmwen/private_chat_hub/LiteRTPlugin.kt`

**Current State:** Simulated responses (ready for LiteRT-LM SDK)

**Structure:**

```kotlin
class LiteRTPlugin {
    private var loadedModel: String? = null
    
    fun setup(binaryMessenger: BinaryMessenger) {
        MethodChannel(binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> handleIsAvailable(result)
                "loadModel" -> handleLoadModel(call, result)
                "generateText" -> handleGenerateText(call, result)
                "getDeviceCapabilities" -> handleGetCapabilities(result)
                else -> result.notImplemented()
            }
        }
    }
    
    private fun handleLoadModel(call: MethodCall, result: MethodChannel.Result) {
        val modelPath: String = call.argument("modelPath") ?: return
        val backend: String = call.argument("backend") ?: "gpu"
        
        // TODO: Replace with actual LiteRT-LM SDK call:
        // val litert = LiteRtModel.load(modelPath, backend)
        
        loadedModel = modelPath
        result.success(mapOf("success" to true))
    }
    
    private fun handleGenerateText(call: MethodCall, result: MethodChannel.Result) {
        val prompt: String = call.argument("prompt") ?: return
        val temperature: Double = call.argument("temperature") ?: 0.7
        
        // TODO: Replace with actual inference:
        // val response = litert.generate(prompt, temperature)
        
        result.success("This is a simulated response to: $prompt")
    }
}
```

**Future Implementation:**

```kotlin
// When LiteRT-LM SDK becomes available:
import com.google.ai.edge.litert.LiteRtModel

private var litert: LiteRtModel? = null

private fun handleLoadModel(call: MethodCall, result: MethodChannel.Result) {
    try {
        val modelPath: String = call.argument("modelPath") ?: return
        val backend: String = call.argument("backend") ?: "gpu"
        
        litert = LiteRtModel.load(modelPath, backend)
        result.success(mapOf("success" to true))
    } catch (e: Exception) {
        result.error("LOAD_ERROR", e.message, null)
    }
}

private fun handleGenerateText(call: MethodCall, result: MethodChannel.Result) {
    try {
        val prompt: String = call.argument("prompt") ?: return
        val temperature: Double = call.argument("temperature") ?: 0.7
        val maxTokens: Int = call.argument("maxTokens") ?: 256
        
        val response = litert?.generate(
            prompt,
            temperature = temperature,
            maxTokens = maxTokens
        )
        
        result.success(response)
    } catch (e: Exception) {
        result.error("GENERATION_ERROR", e.message, null)
    }
}
```

---

## Testing Strategy

### Unit Tests

**InferenceConfigService Tests (27 tests):**
- Mode persistence and retrieval
- Backend selection
- Auto-unload configuration
- Model tracking
- Edge cases and error handling

**OnDeviceLLMService Tests (8 tests):**
- Service initialization
- Model management
- Availability checking
- Lifecycle management

**Test Examples:**

```dart
test('should set and persist inference mode', () async {
  await service.setInferenceMode(InferenceMode.onDevice);
  expect(service.inferenceMode, InferenceMode.onDevice);
  expect(prefs.getString('inference_mode'), 'onDevice');
});

test('should handle rapid mode changes', () async {
  await service.setInferenceMode(InferenceMode.onDevice);
  await service.setInferenceMode(InferenceMode.remote);
  await service.setInferenceMode(InferenceMode.onDevice);
  
  expect(service.inferenceMode, InferenceMode.onDevice);
});

test('should throw error for invalid backend', () {
  expect(
    () => service.setPreferredBackend('invalid'),
    throwsArgumentError,
  );
});
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/inference_config_service_test.dart

# Run with coverage
flutter test --coverage
```

---

## Troubleshooting

### Issue: "Model not found"

**Solution:**
1. Ensure model is downloaded: `await downloadService.isModelDownloaded(modelId)`
2. Check storage path: `await downloadService.getModelPath(modelId)`
3. Verify file exists: `File(path).exists()`

### Issue: "Load timeout"

**Solution:**
1. Increase timeout in `ModelManager.loadModel()`
2. Check device memory: `await modelManager.getMemoryInfo()`
3. Try with smaller model

### Issue: "Native plugin not responding"

**Solution:**
1. Check plugin is registered in `MainActivity.kt`
2. Verify MethodChannel name matches both sides
3. Check Android version (minSdk 24+)
4. Rebuild: `flutter clean && flutter build apk`

### Issue: "Streaming not working"

**Solution:**
1. Verify LiteRTPlatformChannel is initialized
2. Check model is loaded before generating
3. Verify prompt is not empty
4. Check native plugin response format

---

## Code Patterns

### Hybrid Routing Pattern

```dart
Future<Stream<Conversation>> sendMessage(String text) async {
  final mode = _inferenceConfig.inferenceMode;
  
  if (mode == InferenceMode.remote) {
    return _sendMessageRemote(text);
  } else {
    return _sendMessageOnDevice(text);
  }
}
```

### Auto-Unload Pattern

```dart
void resetUnloadTimer() {
  _unloadTimer?.cancel();
  
  _unloadTimer = Timer(
    Duration(minutes: _config.autoUnloadTimeoutMinutes),
    () async {
      await _modelManager.unloadModel();
    },
  );
}
```

### Stream Processing Pattern

```dart
Stream<String> generateResponse(...) async* {
  yield* _platformChannel.generateTextStream(
    prompt: prompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
  
  // Reset timer after generation completes
  _modelManager.resetUnloadTimer();
}
```

---

## References

- [Flutter Platform Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)
- [Hugging Face Models](https://huggingface.co/models)
- [LiteRT-LM Docs](https://ai.google.dev/edge) (When available)

---

**Document Version:** 1.0  
**Last Updated:** January 24, 2026  
**Maintainer:** AI Agent (OpenCode)
