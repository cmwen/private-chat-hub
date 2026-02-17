# Local Model Integration - Implementation Summary

## Overview

Implemented complete integration of on-device LiteRT models into the main model selector, allowing users to select and use local models directly from the chat interface with clear visual indicators.

## Changes Made

### 1. Enhanced ModelInfo Class ([lib/services/llm_service.dart](lib/services/llm_service.dart))

**Added `isLocal` property** to distinguish local models from remote Ollama models:

```dart
class ModelInfo {
  final String id;
  final String name;
  final String description;
  final int sizeBytes;
  final bool isDownloaded;
  final List<String> capabilities;
  final String? downloadUrl;
  final bool isLocal; // NEW: Marks local vs remote models

  const ModelInfo({
    // ...
    this.isLocal = false,
  });
}
```

Updated `copyWith()` and `toJson()` methods to include `isLocal` field.

### 2. Created UnifiedModelService ([lib/services/unified_model_service.dart](lib/services/unified_model_service.dart))

**New service** that combines Ollama and on-device models into a single list:

**Key Features:**
- **Model Prefix**: Local models use `local:` prefix (e.g., `local:gemma3-1b`)
- **Unified List**: Combines Ollama + on-device models
- **Helper Methods**:
  - `isLocalModel(modelName)` - Check if model is local
  - `getLocalModelId(modelName)` - Extract actual ID from prefixed name
  - `getDisplayName(modelName)` - Get display name without prefix

**Example:**
```dart
final unifiedService = UnifiedModelService(
  onDeviceLLMService: onDeviceLLMService,
);

final allModels = await unifiedService.getUnifiedModelList(ollamaModels);
// Returns: [llama3.2, mistral, local:gemma3-1b, local:gemma-3n-e2b]
```

### 3. Updated ModelDownloadService ([lib/services/model_download_service.dart](lib/services/model_download_service.dart))

**Marked all on-device models as local**:

```dart
Future<List<ModelInfo>> getAvailableModels() async {
  // ...
  models.add(
    ModelInfo(
      // ...
      isLocal: true, // All LiteRT models are local
    ),
  );
}
```

### 4. Enhanced ConversationListScreen ([lib/screens/conversation_list_screen.dart](lib/screens/conversation_list_screen.dart))

**Integrated unified model list**:

```dart
class _ConversationListScreenState extends State<ConversationListScreen> {
  List<OllamaModelInfo> _ollamaModels = [];
  List<ModelInfo> _allModels = []; // Combined Ollama + local models
  late UnifiedModelService _unifiedModelService;

  @override
  void initState() {
    super.initState();
    _unifiedModelService = UnifiedModelService(
      onDeviceLLMService: widget.chatService.onDeviceLLMService,
    );
    _loadData();
  }

  Future<void> _loadModels() async {
    // Load Ollama models
    _ollamaModels = await widget.ollamaManager.listModels();
    
    // Get unified list (Ollama + local)
    _allModels = await _unifiedModelService.getUnifiedModelList(_ollamaModels);
  }
}
```

**Visual Indicators for Local Models**:

- **Icon**: 📱 Phone icon for local, ☁️ Cloud icon for remote
- **Badge**: Green "LOCAL" badge with lightning bolt icon
- **Badge Style**: 
  - Green background with alpha
  - Green border
  - Offline bolt icon
  - Bold "LOCAL" text

```dart
ListTile(
  leading: CircleAvatar(
    child: Icon(
      model.isLocal ? Icons.phone_android : Icons.cloud,
    ),
  ),
  title: Row(
    children: [
      Expanded(child: Text(model.name)),
      if (model.isLocal) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.offline_bolt, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text('LOCAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
      ],
    ],
  ),
)
```

### 5. Updated ChatService ([lib/services/chat_service.dart](lib/services/chat_service.dart))

**Automatic routing to on-device inference for local models**:

```dart
Stream<Conversation> sendMessage(String conversationId, String text) async* {
  final initialConversation = getConversation(conversationId);
  
  // NEW: Check if model is local
  final isLocalModel = UnifiedModelService.isLocalModel(initialConversation.modelName);

  // Route to on-device if local model selected
  if (isLocalModel && _onDeviceLLMService != null) {
    _log('Using on-device inference (local model selected)');
    yield* _sendMessageOnDevice(conversationId, text);
    return;
  }
  
  // ... rest of logic for remote models
}
```

**Extract actual model ID when using local models**:

```dart
Stream<Conversation> _sendMessageOnDevice(String conversationId, String text) async* {
  // ...
  
  // Get on-device model ID (strip local: prefix if present)
  String onDeviceModelId;
  if (UnifiedModelService.isLocalModel(initialConversation.modelName)) {
    onDeviceModelId = UnifiedModelService.getLocalModelId(initialConversation.modelName);
    _log('Using local model from conversation: $onDeviceModelId');
  } else {
    onDeviceModelId = _inferenceConfigService?.lastOnDeviceModel ?? 'gemma3-1b';
  }
  
  // Load model and generate response
  await _onDeviceLLMService!.loadModel(onDeviceModelId);
  // ...
}
```

## User Experience

### Model Selection Flow

1. **Open Conversations Screen**
2. **Tap "Active Model" card**
3. **See unified model list** with clear indicators:
   - **Remote models**: Cloud icon, no badge
   - **Local models**: Phone icon, green "LOCAL" badge
4. **Select a model** (local or remote)
5. **Create new conversation**
6. **Chat interface remains the same**

### Visual Indicators

#### Model Selector Sheet
```
┌─────────────────────────────────────┐
│  Select Model              🔄       │
├─────────────────────────────────────┤
│  ☁️  llama3.2                      │
│     4.1 GB                          │
│                                     │
│  ☁️  mistral                       │
│     4.2 GB  🔧 Tools               │
│                                     │
│  📱  Gemma 3 1B        [🗲 LOCAL]  │
│     557 MB  🔧 Tools               │
│                                     │
│  📱  Gemma 3n E2B      [🗲 LOCAL]  │
│     2.9 GB  👁️ Vision  🔧 Tools    │
└─────────────────────────────────────┘
```

### Chat Screen Behavior

**No UI changes required** - Chat screen works identically with local and remote models:
- Same message input
- Same streaming response
- Same message bubbles
- Model routing handled automatically by ChatService

### Model Comparison

**Local models cannot be used in comparison mode** (comparison requires 2 Ollama models):

```dart
Future<void> _createComparisonConversation() async {
  if (_ollamaModels.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You need at least 2 Ollama models to compare'),
      ),
    );
    return;
  }
  // Only show Ollama models in dual selector
}
```

## Technical Details

### Model Name Format

**Ollama Models**: `llama3.2`, `mistral`, `phi3`
**Local Models**: `local:gemma3-1b`, `local:gemma-3n-e2b`

### Automatic Routing Logic

1. **Local model selected** → On-device inference
2. **Inference mode = onDevice** → On-device inference
3. **Offline + on-device available** → On-device inference (fallback)
4. **Offline + no on-device** → Queue message
5. **Online + remote model** → Ollama inference

### Error Handling

- **No local models**: Only Ollama models shown
- **No Ollama models**: Only local models shown
- **Neither available**: Empty state shown
- **On-device service unavailable**: Falls back to Ollama or queueing

## Files Modified

1. ✅ [lib/services/llm_service.dart](lib/services/llm_service.dart) - Added `isLocal` property
2. ✅ [lib/services/unified_model_service.dart](lib/services/unified_model_service.dart) - NEW: Unified model provider
3. ✅ [lib/services/model_download_service.dart](lib/services/model_download_service.dart) - Mark models as local
4. ✅ [lib/services/chat_service.dart](lib/services/chat_service.dart) - Auto-route to on-device
5. ✅ [lib/screens/conversation_list_screen.dart](lib/screens/conversation_list_screen.dart) - Unified model selector

## Testing Checklist

- [ ] Local models appear in model selector
- [ ] Local models show green "LOCAL" badge
- [ ] Local models use phone icon (📱)
- [ ] Remote models use cloud icon (☁️)
- [ ] Selecting local model creates conversation
- [ ] Chat with local model works (sends/receives messages)
- [ ] Streaming works with local models
- [ ] Model comparison excludes local models
- [ ] Empty state shows when no models available
- [ ] Works when Ollama offline (local models only)
- [ ] Works when no local models (Ollama models only)

## Benefits

1. **Unified Experience**: Single model selector for all models
2. **Clear Indication**: Users can easily see which models are local
3. **Seamless Usage**: Same chat interface for local and remote
4. **Automatic Routing**: ChatService handles model type automatically
5. **Offline Support**: Local models available when Ollama offline
6. **Progressive Enhancement**: Works with or without local models

## Future Improvements

1. **Model Metadata**: Show context size, quantization for local models
2. **Performance Indicators**: Speed estimates for local vs remote
3. **Model Sync**: Download remote models to local automatically
4. **Hybrid Mode**: Use both local and remote in same conversation
5. **Model Switching**: Switch between local/remote mid-conversation
6. **Smart Fallback**: Auto-select fastest available model

## Date

January 25, 2026
