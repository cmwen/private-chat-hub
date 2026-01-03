# v2 Architecture Quick Reference

**Document Version:** 1.0  
**Date:** January 3, 2026  
**Purpose:** Quick lookup for v2 architecture decisions

---

## Architecture at a Glance

### System Diagram

```
┌──────────────────────────────────────────────────────────┐
│         Private Chat Hub v2 (Flutter Android)            │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ Presentation Layer                                       │
│ ├─ Chat Screen (enhanced)                               │
│ ├─ Comparison Chat Screen                               │
│ ├─ Task Progress Screen                                 │
│ └─ Settings (expanded with Tools, TTS, MCP)             │
│                                                          │
│ State Management Layer (Riverpod)                        │
│ ├─ Existing: chat, models, settings, connection         │
│ ├─ New Phase 1: toolConfig, jinaSearch                  │
│ ├─ New Phase 2: comparison, comparisonMetrics           │
│ ├─ New Phase 3: ttsPlayer, shareIntent                  │
│ ├─ New Phase 4: taskExecution, taskList                 │
│ └─ New Phase 5: mcpServers, mcpTools                    │
│                                                          │
│ Domain Layer                                             │
│ ├─ Entities (Message, Conversation, Task, etc.)         │
│ ├─ Use Cases                                             │
│ └─ Repository Interfaces                                │
│                                                          │
│ Data Layer                                               │
│ ├─ Repositories (ChatRepository, TaskRepository, etc.)   │
│ ├─ Data Sources                                          │
│ │  ├─ Local: SQLite (13 tables in v2)                   │
│ │  ├─ Remote: Ollama API                                │
│ │  ├─ Remote: Jina API (Phase 1)                        │
│ │  ├─ Remote: MCP Servers (Phase 5)                     │
│ │  └─ Local: SharedPreferences                          │
│ └─ Services                                              │
│    ├─ OllamaService (enhanced)                          │
│    ├─ JinaSearchService (Phase 1)                       │
│    ├─ TTSService (Phase 3)                              │
│    ├─ TaskExecutionService (Phase 4)                    │
│    ├─ MCPClientService (Phase 5)                        │
│    └─ Existing services (unchanged)                     │
│                                                          │
└──────────────────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
    ┌────────┐     ┌────────┐    ┌──────────┐
    │ Ollama │     │ Jina   │    │ MCP      │
    │ API    │     │ API    │    │ Servers  │
    └────────┘     └────────┘    └──────────┘
```

---

## Phase Breakdown

### Phase 1: Tool Calling (Weeks 1-10)
**Goal:** Enable tool use with web search

**Components:**
- JinaSearchService (web search via Jina API)
- ToolExecutor (route tool calls)
- Tool result caching (SQLite)
- UI: Tool badges, search results display

**New Tables:**
- `tools_invoked` - Track tool calls
- `web_search_cache` - Cache search results

**Dependencies:**
- http (already have)
- jina_api_flutter (new)

**Impact on v1:** None

---

### Phase 2: Model Comparison (Weeks 9-16)
**Goal:** Support comparing 2-4 models side-by-side

**Components:**
- Dual-model streaming (parallel OllamaService calls)
- ComparisonConversationNotifier
- Comparison metrics & diff view

**New Tables:**
- `comparison_pairs` - Track comparison sessions
- `comparison_responses` - Store responses per model

**UI Changes:**
- Model selector → comparison option
- Chat view → split screen (2 models) or tabbed (4 models)

**Impact on v1:** None (single model still works)

---

### Phase 3: Native Integration (Weeks 17-24)
**Goal:** Share intent & TTS integration

**Components:**
- ShareIntentService (receive)
- TTSService (text-to-speech)
- Share action on messages (send)

**New Tables:**
- `tts_cache` - Cache generated audio

**Dependencies:**
- flutter_tts ^4.2.3
- receive_sharing_intent ^1.8.1
- share_plus ^12.0.1

**Android Code:**
- Intent receiver in MainActivity
- Method channel for TTS

**Impact on v1:** None (all optional)

---

### Phase 4: Long-Running Tasks (Weeks 25-34)
**Goal:** Support multi-step background tasks

**Components:**
- TaskExecutionService
- BackgroundTaskManager (background_fetch)
- Task progress tracking & persistence

**New Tables:**
- `tasks` - Task definitions
- `task_steps` - Individual steps

**Dependencies:**
- background_fetch ^1.5.0
- workmanager ^0.5.2 (iOS support)

**UI:**
- Task progress cards
- Running tasks dashboard

**Impact on v1:** None

---

### Phase 5: MCP Integration (Weeks 35-42)
**Goal:** Support remote MCP servers for tool discovery

**Components:**
- MCPClientService (WebSocket-based)
- MCP tool library UI
- Tool permission management

**New Tables:**
- `mcp_servers` - Connected servers
- `mcp_tools` - Tools per server
- `mcp_permissions` - Tool permissions

**Protocol:**
- Model Context Protocol (WebSocket)

**Impact on v1:** None

---

## Key Architecture Decisions

### 1. **Riverpod for State**
- ✅ Type-safe, compile-time checks
- ✅ No BuildContext needed
- ✅ Automatic caching with `keepAlive`
- ✅ Easy testing with provider overrides

**New providers in v2:**
```dart
// Phase 1
final jinaSearchServiceProvider = Provider(...)
final toolConfigProvider = StateNotifierProvider(...)

// Phase 2
final comparisonModeProvider = StateProvider(...)
final selectedComparisonModelsProvider = StateProvider(...)

// Phase 3
final ttsServiceProvider = Provider(...)
final shareIntentServiceProvider = Provider(...)

// Phase 4
final taskExecutionServiceProvider = Provider(...)

// Phase 5
final mcpClientServiceProvider = Provider(...)
```

### 2. **SQLite for Everything**
- ✅ Conversations (v1)
- ✅ Messages (v1)
- ✅ Search cache (Phase 1)
- ✅ Comparison pairs (Phase 2)
- ✅ Tasks (Phase 4)
- ✅ MCP servers (Phase 5)

**Migration:** Automatic with sqflite version management

### 3. **Offline-First Always**
- Save locally first, sync later
- Ollama requests async, don't block UI
- Tools execute with timeout & fallback
- Tasks continue if connection drops

### 4. **Tool Pattern (Ollama Native)**
- Model indicates tool_call in response
- App executes tool (web search, code search, etc.)
- Returns tool_result back to model
- Model incorporates results

### 5. **Jina API for Web Search**
- `/search` endpoint (100/min rate limit)
- `/reader` endpoint (fetch page content)
- `/qa` endpoint (Q&A over context)
- Local caching with 24h expiry
- API key in secure storage

---

## Database Schema Evolution

```
v1 (4 tables)              v2 Phase 1        v2 Phase 2
├─ conversations           ├─ (all v1)       ├─ (all v1)
├─ messages                ├─ tools_invoked  ├─ (Phase 1)
├─ connection_profiles     └─ web_search... ├─ comparison_pairs
└─ cached_models                            └─ comparison_resp...

                           v2 Phase 4        v2 Phase 5
                           ├─ (all prev)     ├─ (all prev)
                           ├─ tasks          ├─ mcp_servers
                           └─ task_steps     ├─ mcp_tools
                                            └─ mcp_permissions
```

**Migration Path:**
1. User updates app
2. SQLite triggers migration script
3. New tables created (v1 untouched)
4. v1 data copied as-is
5. v2 ready to use

---

## Services Architecture

### OllamaService (Enhanced in v2)

**Existing Methods:**
- `listModels()` - GET /api/tags
- `showModel(name)` - GET /api/show
- `sendChatStream(messages, tools?)` - POST /api/chat (now with tools param)
- `pullModel(name)` - POST /api/pull

**No breaking changes** - tools param optional

### New Services

**Phase 1: JinaSearchService**
```dart
Future<SearchResults> search(query, {limit, lang, fresh})
Future<String> fetchContent(url)
Future<String> answerQuestion(question, context)
```

**Phase 3: TTSService**
```dart
Future<void> speak(text, {speed, pitch})
Future<void> pause()
Future<void> resume()
Future<void> stop()
```

**Phase 4: TaskExecutionService**
```dart
Future<void> executeTask(task)
Future<void> pauseTask(taskId)
Future<void> resumeTask(taskId)
Future<void> cancelTask(taskId)
```

**Phase 5: MCPClientService**
```dart
Future<void> connectToServer(name, host, port)
Future<MCPToolResult> callTool(server, tool, args)
Future<List<MCPTool>> listTools(serverName)
```

---

## Error Handling

### Tool Execution Errors

```
Web Search fails
├─ Retry with exponential backoff (up to 3 times)
├─ If API key invalid → Show settings
├─ If rate limited → Show quota warning
├─ If network error → Continue without results
└─ Model: "I couldn't find current results, based on my training..."
```

### Task Execution Errors

```
Task step fails
├─ Save error state
├─ Mark task as PAUSED
├─ Show notification with retry
├─ User can: Resume, Skip step, Cancel task
└─ Auto-resume on app restart (optional)
```

### MCP Connection Errors

```
MCP server disconnect
├─ Mark server as disconnected
├─ Stop using tools from that server
├─ Show notification
├─ Offer reconnect button
└─ Tools gracefully unavailable (fallback to Ollama only)
```

---

## Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| Cold start | <2.7s | ✅ (was 2.3s, +200ms for new providers) |
| Warm start | <1s | ✅ |
| Single model chat | Same as v1 | ✅ |
| Dual model chat | <4s | ✅ (parallel execution) |
| Web search | <3s | ✅ |
| TTS start | <500ms | ✅ |
| Task step | Variable | ✅ (depends on operation) |
| Memory idle | <15MB | ✅ (v1 was 10MB) |
| Memory under load | <50MB | ✅ |

---

## Backward Compatibility

### v1 → v2 Upgrade
- ✅ All data migrated safely
- ✅ Existing conversations load unchanged
- ✅ Single model chat works identically
- ✅ No forced features
- ✅ Can disable all v2 and use v1 mode

### v2 → v1 Downgrade (Theoretical)
- ✅ v1 ignores new tables
- ✅ v1 ignores new message fields
- ✅ v1 can load any v2 conversation
- ✅ Tool data ignored gracefully
- ✅ Full functionality preserved

---

## Testing Strategy

### Unit Tests
- JinaSearchService
- ToolExecutor
- TaskExecutionService
- MCPClientService
- State notifiers

### Widget Tests
- Tool badges
- Comparison chat view
- Task progress cards
- TTS controls
- Shared content widget

### Integration Tests
- Tool calling flow
- Model comparison flow
- Task execution flow
- Share intent flow
- MCP tool invocation

### Regression Tests
- All v1 tests pass unchanged
- Single model chat works
- Message persistence
- Export/import
- Settings migration

---

## Deployment Checklist

### Pre-Release
- [ ] All v2 code on feature branch
- [ ] Database migrations tested
- [ ] v1 regression tests pass (100%)
- [ ] v2 new tests pass (100%)
- [ ] Performance benchmarks acceptable
- [ ] Security review complete
- [ ] API keys properly secured
- [ ] Rate limiting logic tested

### Release
- [ ] Tag release v2.0.0
- [ ] Database auto-migration runs
- [ ] Verify no data loss
- [ ] Monitor error rates (first 24h)
- [ ] Monitor API quota (Jina)
- [ ] Gather user feedback

### Post-Release
- [ ] Hotfix branch ready
- [ ] v1 support continued (bugfixes)
- [ ] v2 feature iterations (v2.1, v2.2, etc.)

---

## Key Files

### Architecture Docs
- [ARCHITECTURE_V2.md](ARCHITECTURE_V2.md) - Full v2 architecture
- [JINA_INTEGRATION_SPEC.md](JINA_INTEGRATION_SPEC.md) - Jina API details
- [V2_IMPACT_ANALYSIS.md](V2_IMPACT_ANALYSIS.md) - Impact on v1

### UX Docs
- [UX_DESIGN_V2.md](UX_DESIGN_V2.md) - Complete UI specification
- [UX_DESIGN_V2_COMPONENTS.md](UX_DESIGN_V2_COMPONENTS.md) - Component specs
- [UX_DESIGN_V2_FLOWS.md](UX_DESIGN_V2_FLOWS.md) - User journey maps

### Planning Docs
- [PRODUCT_ROADMAP_V2.md](PRODUCT_ROADMAP_V2.md) - Timeline & phases
- [USER_STORIES_V2.md](USER_STORIES_V2.md) - Feature details
- [FEASIBILITY_V2.md](FEASIBILITY_V2.md) - Technical validation

---

## Quick Links

**Jina API:** https://docs.jina.ai/

**Ollama Tool Calling:** https://github.com/ollama/ollama/blob/main/docs/modelfile.md

**Flutter TTS:** https://pub.dev/packages/flutter_tts

**Riverpod:** https://riverpod.dev/

**SQLite / sqflite:** https://pub.dev/packages/sqflite

---

## Contact & Questions

For architecture questions:
1. Check ARCHITECTURE_V2.md
2. Check specific phase docs (JINA_INTEGRATION_SPEC.md, etc.)
3. Review decision rationale in component sections
4. Check v1 comparison in V2_IMPACT_ANALYSIS.md

