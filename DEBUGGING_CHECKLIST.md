# Web Search Debugging Checklist

## Quick Diagnosis Steps

### 1. Check If Icon Appears ✓

**Expected**: Globe icon (🌐) in chat screen AppBar

**What it means**:
- ✓ Icon shows → Model supports tools
- ✗ Icon missing → Model does NOT support tools

**Solution if icon missing**:
- Check model name in logs: `[DEBUG] Checking tool support for model: {name}`
- Supported models: llama3.1+, mistral-nemo, qwen2.5+, command-r
- Current model: probably mistral-3, llama2, or llama3.0

**Model Support:**
```
✓ llama3.1:latest       - SUPPORTS
✓ llama3.2:latest       - SUPPORTS  
✓ mistral-3:latest      - SUPPORTS (native function calling)
✓ mistral-nemo:latest   - SUPPORTS
✓ mistral-large:latest  - SUPPORTS
✓ qwen2.5:latest        - SUPPORTS
✗ mistral:latest        - Does NOT (use mistral-3 or mistral-nemo instead)
✗ llama3:latest         - Does NOT (use llama3.1+ instead)
✗ llama2:latest         - Does NOT
✗ neural-chat:latest    - Does NOT
✗ gemma:latest          - Does NOT
```

---

### 2. Check If Toggle Is Enabled ✓

**When icon shows**, check the icon style:
- **Filled icon** (🌐) → Web search ENABLED
- **Outlined icon** (⊙) → Web search DISABLED

**What to do**:
- Click icon to toggle
- Look for snackbar: "Web search enabled" or "Web search disabled"

---

### 3. Send a Web Search Query ✓

**Good test queries**:
- "What is Flutter?" (should get instant answer)
- "Python definition" (should get definition)
- "What is React.js?" (should search)

**Bad test queries** (likely no results):
- "How to cook pasta" (too broad)
- "Weather in Paris" (real-time, not supported)
- "Random word" (no factual answer)

---

### 4. Check Console Logs ✓

**Open Logcat/Debug Console** and look for these patterns:

#### Icon should appear:
```
[DEBUG] Checking tool support for model: llama3.1:latest
[DEBUG] llama3.1 supports tools: true
```

#### Search should execute:
```
[DEBUG] Model supports tools: true, Web search enabled: true
[DEBUG] Including 1 tool(s) in request
[WebSearch] Starting search for query: "what is flutter"
[WebSearch] Response status: 200
[WebSearch] Formatted results: Web Search Results...
```

#### If no icon:
```
[DEBUG] Model mistral tool capable: false
[DEBUG] No tools in request (supports=false, enabled=true)
```

---

## Log Output Examples

### ✓ GOOD: Web search works
```
[DEBUG] Checking tool support for model: llama3.1:latest (family: llama3.1)
[DEBUG] llama3.1 supports tools: true
[DEBUG] Preparing message for model: llama3.1:latest
[DEBUG] Model supports tools: true, Web search enabled: true
[DEBUG] Including 1 tool(s) in request
[WebSearch] Starting search for query: "what is flutter"
[WebSearch] Response status: 200
[WebSearch] Parsed response keys: AbstractText, AbstractSource, ...
[WebSearch] Formatted results: Web Search Results for: "what is flutter"
```

### ✗ ISSUE 1: Model doesn't support tools
```
[DEBUG] Checking tool support for model: mistral:latest (family: mistral)
[DEBUG] Model mistral tool capable: false
[DEBUG] No tools in request (supports=false, enabled=true)
```
**Fix**: Use llama3.1 or mistral-nemo instead

### ✗ ISSUE 2: Web search disabled
```
[DEBUG] Model supports tools: true, Web search enabled: false
[DEBUG] No tools in request (supports=true, enabled=false)
```
**Fix**: Click the icon to enable web search

### ✗ ISSUE 3: Search fails
```
[WebSearch] Starting search for query: "test"
[WebSearch] Response status: 503
[WebSearch] Error: Search failed with status code: 503
```
**Fix**: Network issue or DuckDuckGo down. Try again.

### ✗ ISSUE 4: No search results
```
[WebSearch] Parsed response keys: AbstractText (empty), RelatedTopics (empty)
[WebSearch] Formatted results: Web Search Results for: "query"
(empty)
```
**Fix**: Query not understood by search engine. Try different wording.

---

## Common Problems & Solutions

| Problem | Root Cause | Solution |
|---------|-----------|----------|
| Icon doesn't show | Model doesn't support tools | Switch to llama3.1+ |
| Icon shows but disabled by default | Web search disabled per-conversation | Click icon to enable |
| Search returns empty results | Query too specific/recent | Rephrase: "What is Flutter?" |
| Network error (503, timeout) | Network or DuckDuckGo down | Try again in 30s |
| Results show in logs but not UI | Message display issue | Clear app cache, restart |
| Icon still shows after switching models | Cache not updated | Pull to refresh or restart |

---

## Quick Log Search

**Filter logs by these strings:**

```
[DEBUG]        - Model support checking
[WebSearch]    - Search request/response
Model supports - Tools preparation
Including tool - Tools sent to LLM
Response body  - Raw DuckDuckGo response
```

In Android Studio:
- Logcat → Filter: `[DEBUG]|[WebSearch]`

In VS Code:
- Use Ctrl+F in Debug Console to search

---

## Step-by-Step Debug Session

1. **Start fresh**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check initial model**
   - Look at AppBar subtitle (shows model name)
   - Search logs for: `Checking tool support for model: {name}`

3. **Try search**
   - Ask: "What is Flutter?"
   - Monitor logs for: `[WebSearch] Starting search`

4. **Analyze results**
   - Check response status: should be 200
   - Check formatted results: should have content
   - Check UI: results should appear in chat

5. **Try toggling**
   - Click icon to disable/enable
   - Verify snackbar appears
   - Try search again

---

## Contact Points for Debugging

| Component | Log Prefix | File |
|-----------|-----------|------|
| Model Detection | `[DEBUG] Checking tool` | `lib/services/chat_service.dart:42` |
| Tools Preparation | `[DEBUG] Preparing message` | `lib/services/chat_service.dart:373` |
| Web Search Request | `[WebSearch] Starting search` | `lib/services/web_search_service.dart:55` |
| Search Response | `[WebSearch] Response status` | `lib/services/web_search_service.dart:69` |

---

## Expected Behavior by Model

### llama3.1:latest
```
✓ Icon shows (filled)
✓ Can toggle on/off
✓ Tools included in request
✓ Web search executes
```

### mistral-3:latest
```
✓ Icon shows (filled)
✓ Can toggle on/off
✓ Tools included in request
✓ Web search executes
```

### mistral-nemo:latest
```
✓ Icon shows (filled)
✓ Can toggle on/off
✓ Tools included in request
✓ Web search executes
```

### mistral:latest  
```
✗ Icon does NOT show
✗ Cannot toggle
✗ No tools in request
✗ Web search cannot execute
→ FIX: Switch to mistral-3 or mistral-nemo
```

### llama2:latest
```
✗ Icon does NOT show
✗ Cannot toggle
✗ No tools in request
✗ Web search cannot execute
→ FIX: Switch to llama3.1 or newer
```

---

## Notes

- **Logs are temporary** - cleared on app restart
- **Print statements are debug only** - safe to keep in code
- **DuckDuckGo is free** - limited to instant answers, not comprehensive search
- **Speed varies** - depends on query complexity and network (2-5 seconds typical)
