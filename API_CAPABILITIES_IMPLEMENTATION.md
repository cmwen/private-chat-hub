# Model Capability Detection: Transition from Hardcoding to API-Based

## Summary of Changes

The application now determines which models support web search tools **dynamically via the Ollama API** instead of using a hardcoded list of model names.

## What Changed

### Before (Hardcoded)
```dart
bool modelSupportsTools(String modelName) {
  final modelFamily = modelName.split(':').first.toLowerCase();
  
  // Hardcoded list - requires code updates for new models
  if (modelFamily.startsWith('mistral-3') ||
      modelFamily.startsWith('llama3.1')) {
    return true; // ❌ Must update this code
  }
  return false;
}
```

### After (API-Based)
```dart
Future<bool> modelSupportsTools(String modelName) async {
  // 1. Check cache first
  if (_modelCapabilitiesCache.containsKey(modelFamily)) {
    return _modelCapabilitiesCache[modelFamily] ?? false;
  }
  
  // 2. Query Ollama API
  final modelInfo = await _ollama.showModel(modelName);
  
  // 3. Check actual capabilities returned by API
  final capabilities = modelInfo['capabilities'] as List<dynamic>?;
  
  if (capabilities != null) {
    final supportsTools = capabilities.contains('tools'); // ✅ API tells us
    
    // 4. Cache result for future use
    _modelCapabilitiesCache[modelFamily] = supportsTools;
    return supportsTools;
  }
  
  // 5. Fallback if API doesn't have info
  return _modelSupportsFallback(modelFamily);
}
```

## Key Improvements

| Aspect | Before | After |
|--------|--------|-------|
| **Accuracy** | Guesswork based on model name | Uses actual API capabilities |
| **New Models** | Code changes required | Automatic support |
| **Performance** | Synchronous (no overhead) | Async with in-memory cache |
| **Errors** | Silent failures | Fallback to hardcoded list |
| **Future-Proof** | Requires maintenance | Self-updating |

## Files Modified

### 1. `lib/services/chat_service.dart`
- Added `_modelCapabilitiesCache` map for in-memory caching
- Converted `modelSupportsTools()` from sync to async
- Fetches model info from Ollama API's `/api/show` endpoint
- Checks if "tools" is in the capabilities array
- Falls back to `_modelSupportsFallback()` if needed

### 2. `lib/screens/chat_screen.dart`
- Added `_modelSupportsTools` state variable
- Added `_checkModelCapabilities()` async method called on init/update
- Updated web search icon condition to use state variable instead of sync method

### 3. Message Generation Pipeline
- Updated `_generateMessageInBackground()` to await model capability check
- This is called when sending messages with potential tool use

## How It Works in Practice

### Scenario 1: User opens chat with llama3.1

1. **Chat screen loads** → calls `_checkModelCapabilities()`
2. **Fetches from API** → `showModel("llama3.1:latest")`
3. **API returns** → `{capabilities: ["completion", "tools"]}`
4. **Check contents** → `"tools"` is in capabilities array? YES
5. **Cache result** → `_modelCapabilitiesCache["llama3.1"] = true`
6. **UI updates** → Globe icon appears

### Scenario 2: User opens chat with mistral:3b (old mistral)

1. **Chat screen loads** → calls `_checkModelCapabilities()`
2. **Fetches from API** → `showModel("mistral:3b")`
3. **API returns** → `{capabilities: ["completion"]}`
4. **Check contents** → `"tools"` is in capabilities array? NO
5. **Cache result** → `_modelCapabilitiesCache["mistral"] = false`
6. **UI updates** → Globe icon does NOT appear

### Scenario 3: Future model with tools (e.g., "falcon-tools:7b")

1. **Chat screen loads** → calls `_checkModelCapabilities()`
2. **Fetches from API** → `showModel("falcon-tools:7b")`
3. **API returns** → `{capabilities: ["completion", "tools"]}`
4. **Check contents** → `"tools"` is in capabilities array? YES
5. **Cache result** → `_modelCapabilitiesCache["falcon-tools"] = true`
6. **UI updates** → Globe icon appears ✅ No code changes needed!

## Fallback Strategy

If the Ollama API doesn't return capabilities (older version, offline, etc.):

```dart
bool _modelSupportsFallback(String modelFamily) {
  // Known tool-capable models from Ollama documentation
  if (modelFamily.startsWith('llama3.')) {
    // Parse version and check >= 1
  }
  if (modelFamily.startsWith('mistral-3')) return true;
  if (modelFamily.startsWith('mistral-nemo')) return true;
  if (modelFamily.startsWith('qwen2.5')) return true;
  if (modelFamily.startsWith('command-r')) return true;
  
  return false; // Default to no tools
}
```

This ensures the app still works even if the API doesn't provide capability info.

## Caching Strategy

**In-Memory Cache** per app session:
- First query: API call (slower ~100-500ms)
- Subsequent queries: Memory (instant <1ms)
- New app session: Cache cleared, fresh queries

**Future Enhancement**: Could persist cache in SharedPreferences for multi-session caching

## Testing

All 76 tests pass ✅
- Unit tests for message generation
- Widget tests for UI components
- Async/await properly handled

```bash
$ flutter test --no-pub
00:03 +76: All tests passed!
```

## Logging Output

When model capabilities are checked:

```
[DEBUG] Fetching capabilities for model: llama3.1:latest
[DEBUG] Model llama3.1:latest capabilities: [completion, tools]
[DEBUG] Model llama3.1:latest supports tools: true

[DEBUG] Model capabilities retrieved from cache: llama3.1 (next time)
```

When generating messages:
```
[DEBUG] Model supports tools: true, Web search enabled: true
[DEBUG] Including 1 tool(s) in request
```

## Benefits

✅ **Accurate**: Uses API's actual capability info  
✅ **Dynamic**: Automatically works with new models  
✅ **Maintainable**: No hardcoded model lists  
✅ **Robust**: Fallback to hardcoded list if needed  
✅ **Performant**: Caching prevents repeated API calls  
✅ **Future-Proof**: Self-updating as models evolve  

## Edge Cases Handled

| Case | Behavior |
|------|----------|
| API offline | Falls back to hardcoded list |
| Invalid model name | Returns false (no tools) |
| Capabilities field missing | Falls back to hardcoded list |
| Network error | Logs error, returns false |
| Cache hit | Returns immediately (no API call) |

## Related Documentation

- See `WEB_SEARCH_API_CAPABILITIES.md` for technical deep dive
- See `DEBUGGING_WEB_SEARCH.md` for troubleshooting guide
- Ollama API docs: https://github.com/ollama/ollama/blob/main/docs/api.md#show-model-information
