# Quick Reference: API-Based Model Capability Detection

## What You Need to Know

### The Problem We Solved
❌ **Before**: App had hardcoded list of models that support tools. Every time Ollama added a new tool-capable model, the code needed to be updated.

✅ **After**: App automatically detects which models support tools by asking the Ollama API.

### The Solution
Instead of hardcoding model names like `"llama3.1"` and `"mistral-3"`, the app now:

1. Calls Ollama's `/api/show` endpoint for a model
2. Reads the `capabilities` array (e.g., `["completion", "tools"]`)
3. Checks if `"tools"` is in the array
4. Caches the result for performance

### Files Changed
| File | Change |
|------|--------|
| `lib/services/chat_service.dart` | Added async `modelSupportsTools()` method |
| `lib/screens/chat_screen.dart` | Added state variable `_modelSupportsTools` |
| `lib/services/chat_service.dart` | Updated message generation to await model check |

### How It Affects You

**When selecting a new model for a chat:**
- Globe icon appears → Model supports web search tools
- Globe icon hidden → Model doesn't support tools

The icon is determined automatically based on what the Ollama API reports.

### Performance Notes

**First time checking a model:** ~100-500ms (API call)  
**Subsequent times:** <1ms (cached in memory)

The cache is per app session. When you restart the app, it checks the API again.

### If Something Goes Wrong

1. **Globe icon missing when it should appear?**
   - Check logs: `[DEBUG] Model supports tools: true`
   - Run Ollama and verify model is available
   - Check internet connection

2. **Globe icon appearing for a model that doesn't support tools?**
   - Clear app cache and restart
   - The cache might be outdated from previous session

3. **Error message about model?**
   - Falls back to hardcoded list automatically
   - You can still use web search if the hardcoded list knows about the model

### Testing

Run tests to verify everything works:
```bash
flutter test --no-pub
```

Should see: `00:03 +76: All tests passed!`

### Logging to Debug

Watch logs while using the app:
```
[DEBUG] Fetching capabilities for model: llama3.1:latest
[DEBUG] Model llama3.1:latest capabilities: [completion, tools]
[DEBUG] Model llama3.1:latest supports tools: true
```

### Caching Behavior

```dart
// First check of "llama3.1:latest"
→ API call to /api/show
→ Returns: {capabilities: ["completion", "tools"]}
→ Cache: _modelCapabilitiesCache["llama3.1"] = true
→ Result: true

// Second check of "llama3.1:latest"
→ Cache hit! 
→ Result: true (instant, no API call)

// Different conversation, but same model "llama3.1:latest"
→ Cache hit!
→ Result: true (instant, no API call)
```

### Architecture

```
Chat Screen
    ↓
  initState/didUpdateWidget
    ↓
  _checkModelCapabilities() [async]
    ↓
  ChatService.modelSupportsTools() [async]
    ├─→ Check cache
    ├─→ If miss, call _ollama.showModel()
    └─→ Check capabilities array
    ↓
  Update _modelSupportsTools state
    ↓
  UI renders (globe icon shows/hides)
```

### Fallback

If the Ollama API doesn't provide capability info:

```dart
// Known tool-capable models (fallback list)
_modelSupportsFallback(modelFamily) {
  if (modelFamily.startsWith('llama3.1')) return true;
  if (modelFamily.startsWith('mistral-3')) return true;
  if (modelFamily.startsWith('mistral-nemo')) return true;
  if (modelFamily.startsWith('qwen2.5')) return true;
  if (modelFamily.startsWith('command-r')) return true;
  return false;
}
```

This ensures the app works even if the API doesn't return capability info.

### Async/Await Handling

The method is now async:
```dart
// Before (sync)
bool result = chatService.modelSupportsTools(modelName);

// After (async)
bool result = await chatService.modelSupportsTools(modelName);
```

The UI handles this by:
1. Calling `_checkModelCapabilities()` in `initState` and `didUpdateWidget`
2. Awaiting the async method
3. Updating state when complete
4. Widget rebuilds with `_modelSupportsTools` value

### Related Files

- `WEB_SEARCH_API_CAPABILITIES.md` - Technical deep dive
- `API_CAPABILITIES_IMPLEMENTATION.md` - Implementation details
- `DEBUGGING_WEB_SEARCH.md` - Troubleshooting guide
- `DEBUGGING_CHECKLIST.md` - Quick troubleshooting checklist

### Summary

The app is now **smarter**: it asks Ollama what models support tools instead of guessing based on model names. This means automatic support for new tool-capable models without code changes.

✅ More accurate  
✅ More maintainable  
✅ More future-proof  
✅ All tests pass
