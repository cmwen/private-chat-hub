# v2 Architecture & Technical Design - Complete Summary

**Date:** January 3, 2026  
**Status:** Design Complete - Ready for Implementation  
**Scope:** Full v2 feature architecture (Phases 1-5, 18-27 weeks)

---

## 📋 Documents Created

This architectural review has produced 6 comprehensive documents:

### 1. **[ARCHITECTURE_V2.md](ARCHITECTURE_V2.md)** (1,200+ lines)
**Complete v2 technical architecture**
- System context diagrams
- Architecture layers (Presentation → Domain → Data)
- Phase 1-5 detailed designs
- Database schema extensions
- Service dependencies
- Testing strategy
- Impact on v1 features (ZERO breaking changes)

### 2. **[JINA_INTEGRATION_SPEC.md](JINA_INTEGRATION_SPEC.md)** (800+ lines)
**Web search implementation guide**
- Jina API overview (/search, /reader, /qa endpoints)
- Complete DartService implementation
- Error handling & retry logic
- Rate limiting & quota management
- Caching strategy (24h local cache)
- Security (API key management, input validation)
- Testing strategy
- Rollout plan (weeks 1-10)

### 3. **[UX_DESIGN_V2.md](UX_DESIGN_V2.md)** (700+ lines)
**Complete UI/UX specification**
- Design principles (transparency, power without overwhelm)
- Phase 1-5 wireframes with ASCII mockups
- Tool invocation badges
- Comparison view layouts (2 & 4 model modes)
- Native sharing & TTS controls
- Task progress tracking
- MCP server configuration
- Material Design 3 compliance
- Accessibility features

### 4. **[UX_DESIGN_V2_COMPONENTS.md](UX_DESIGN_V2_COMPONENTS.md)** (600+ lines)
**Detailed component specifications**
- 18+ component specs with properties & states
- Dart code structure suggestions
- Animation & transition specs
- Haptic feedback mapping
- Accessibility specs (contrast, touch targets, screen readers)
- Component implementation priority

### 5. **[UX_DESIGN_V2_FLOWS.md](UX_DESIGN_V2_FLOWS.md)** (500+ lines)
**User journey maps for all features**
- 15+ detailed end-to-end flows
- Web search flow (query → search → results → response)
- Comparison flows (2 & 4 model modes)
- Share intent flows (receive & send)
- TTS playback flows
- Task execution flows
- MCP tool invocation flows
- Error recovery paths

### 6. **[V2_IMPACT_ANALYSIS.md](V2_IMPACT_ANALYSIS.md)** (600+ lines)
**Backward compatibility & migration**
- Impact on all v1 features: ZERO breaking changes
- Database migration strategy (auto-migrated)
- Message & conversation model updates (all new fields nullable)
- Performance impact (<5MB additional memory)
- Data import/export compatibility
- Feature toggles & graceful degradation
- Rollout strategy (safe, tested)

### 7. **[V2_ARCHITECTURE_QUICK_REFERENCE.md](V2_ARCHITECTURE_QUICK_REFERENCE.md)** (400+ lines)
**Quick lookup guide**
- System diagram
- Phase breakdown (1-5)
- Architecture decisions
- Services list
- Error handling patterns
- Performance targets
- Deployment checklist
- Key files reference

---

## 🎯 Architecture Overview

### v2 System Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                Private Chat Hub v2 (Flutter)                   │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│ PRESENTATION LAYER                                             │
│ Chat | Comparison | Tasks | Models | Settings + new screens   │
│                            ↓                                   │
│ STATE MANAGEMENT (Riverpod)                                   │
│ Existing + New: tools, comparison, tts, tasks, mcp            │
│                            ↓                                   │
│ DOMAIN LAYER                                                  │
│ Entities | Use Cases | Repository Interfaces                  │
│                            ↓                                   │
│ DATA LAYER                                                    │
│ Repositories | Data Sources | Services                        │
│ ├─ Local: SQLite (13 tables v2.5)                            │
│ ├─ Remote: Ollama, Jina, MCP                                 │
│ └─ Services: Jina, TTS, Tasks, MCP, Tools                    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
              ↓              ↓              ↓
          Ollama          Jina AI        MCP
          (local)         (web)          (remote)
```

### Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **State Management** | Riverpod 3.0+ | Type-safe, testable, no BuildContext |
| **Database** | SQLite + sqflite | Structured, relational, FTS5, reliable |
| **Pattern** | Clean Architecture | Testable, maintainable, scalable |
| **Web Search** | Jina API | Reliable, affordable, simple integration |
| **Tool Format** | Ollama native | Built-in support, model agnostic |
| **Comparison** | Parallel streams | Fast, responsive, both models concurrent |
| **Tasks** | background_fetch | Android native, reliable, persistent |
| **TTS** | flutter_tts | Native Android integration, clean |
| **MCP** | WebSocket client | Standard protocol, future-proof |

---

## 📊 Phase Timeline

```
Phase 1: Tool Calling & Web Search (8-10 weeks)
├─ Jina API integration
├─ Tool definition system
├─ Web search execution
├─ Result caching & display
└─ UI: Tool badges, search results, configuration

Phase 2: Model Comparison (6-8 weeks)
├─ Dual-model streaming
├─ Comparison metrics
├─ Response diff view
├─ UI: Split screen, tabbed view, metrics

Phase 3: Native Integration (6-8 weeks)
├─ Share intent receiver
├─ Share action sender
├─ TTS integration
├─ Android platform code
└─ UI: Shared content widget, TTS controls

Phase 4: Long-Running Tasks (8-10 weeks)
├─ Task execution engine
├─ Background worker (background_fetch)
├─ Step-by-step progress
├─ Error recovery & retry
└─ UI: Progress cards, task dashboard, results

Phase 5: MCP Integration (6-8 weeks)
├─ MCP client (WebSocket)
├─ Tool discovery
├─ Permission management
├─ Server configuration
└─ UI: Server list, tool library, permissions

Total: 18-27 weeks (delivery Q2 2026)
```

---

## 🔧 Implementation Checklist

### Phase 1: Tool Calling (Week 1-10)

**Core Implementation:**
- [ ] JinaSearchService (search, fetch, QA)
- [ ] ToolDefinition & ToolInvocation models
- [ ] ToolExecutor (route tool calls)
- [ ] tools_invoked table & migrations
- [ ] web_search_cache table

**Integration:**
- [ ] OllamaService.sendChatStream() with tools param
- [ ] Tool capability detection (model compatibility)
- [ ] Tool result formatting
- [ ] Error handling & retries

**UI:**
- [ ] Tool configuration screen
- [ ] Tool result display component
- [ ] Tool error states
- [ ] Loading indicators

**Testing:**
- [ ] Unit tests (JinaSearchService)
- [ ] Integration tests (tool calling flow)
- [ ] UI tests (tool badges, results)

---

### Phase 2: Model Comparison (Week 9-16)

**Core Implementation:**
- [ ] ComparisonConversation model
- [ ] ComparisonConversationNotifier
- [ ] Parallel message sending
- [ ] comparison_pairs & comparison_responses tables

**UI:**
- [ ] Model selector → comparison option
- [ ] Split-screen view (2 models)
- [ ] Tabbed view (4 models)
- [ ] Metrics sidebar
- [ ] Response diff view

**Testing:**
- [ ] Unit tests (comparison logic)
- [ ] UI tests (layouts, switching)
- [ ] Performance tests (parallel streaming)

---

### Phase 3: Native Integration (Week 17-24)

**Android Platform:**
- [ ] Intent receiver setup (MainActivity)
- [ ] Method channel for TTS
- [ ] Share intent processing

**Services:**
- [ ] ShareIntentService
- [ ] TTSService (flutter_tts wrapper)
- [ ] Shared content stream

**UI:**
- [ ] SharedContentWidget
- [ ] TTSControls component
- [ ] Share action menu
- [ ] TTS configuration screen

**Testing:**
- [ ] Android intent tests
- [ ] TTS playback tests
- [ ] Share flow integration tests

---

### Phase 4: Long-Running Tasks (Week 25-34)

**Core Implementation:**
- [ ] Task & TaskStep models
- [ ] TaskExecutionService
- [ ] BackgroundTaskManager
- [ ] tasks & task_steps tables
- [ ] Retry logic & error recovery

**UI:**
- [ ] TaskProgressCard
- [ ] RunningTasksDashboard
- [ ] TaskResultView
- [ ] Notification integration

**Testing:**
- [ ] Unit tests (task execution)
- [ ] Background execution tests
- [ ] Error recovery tests
- [ ] UI tests (progress display)

---

### Phase 5: MCP Integration (Week 35-42)

**Core Implementation:**
- [ ] MCPClientService (WebSocket)
- [ ] MCP tool discovery
- [ ] Permission system
- [ ] mcp_servers, mcp_tools, mcp_permissions tables

**UI:**
- [ ] MCPServerCard
- [ ] MCPToolLibrary
- [ ] Server configuration screen
- [ ] Tool permission management

**Testing:**
- [ ] Unit tests (WebSocket connection)
- [ ] Tool invocation tests
- [ ] Permission system tests

---

## 💾 Database Schema (v2)

**Total: 13 tables** (4 v1 + 9 v2)

```sql
-- v1 Tables (unchanged)
CREATE TABLE conversations (...)
CREATE TABLE messages (...)
CREATE TABLE connection_profiles (...)
CREATE TABLE cached_models (...)

-- Phase 1: Tools
CREATE TABLE tools_invoked (...)
CREATE TABLE web_search_cache (...)

-- Phase 2: Comparison
CREATE TABLE comparison_pairs (...)
CREATE TABLE comparison_responses (...)

-- Phase 3: Sharing & TTS
CREATE TABLE tts_cache (...)

-- Phase 4: Tasks
CREATE TABLE tasks (...)
CREATE TABLE task_steps (...)

-- Phase 5: MCP
CREATE TABLE mcp_servers (...)
CREATE TABLE mcp_tools (...)
CREATE TABLE mcp_permissions (...)
```

---

## 📦 New Dependencies

```yaml
# Phase 1: Web Search
jina_api_flutter: ^1.0.0  # Optional wrapper, or use http directly

# Phase 3: Native Integration
flutter_tts: ^4.2.3
receive_sharing_intent: ^1.8.1
share_plus: ^12.0.1

# Phase 4: Background Tasks
background_fetch: ^1.5.0
workmanager: ^0.5.2  # iOS future support

# Enhanced
sqflite: ^2.4.2+  # Extended schema
http: ^1.2.0+     # Already using
uuid: ^4.0.0+     # Already using
riverpod: ^3.0.0+ # Already using

Total NEW: 6 packages (all production-ready)
Total UPDATED: 3 packages
```

---

## ✅ Backward Compatibility

**v1 Impact: ZERO** ✅

- ✅ All v1 messages load unchanged
- ✅ All v1 conversations work identically  
- ✅ Single-model chat unaffected
- ✅ Database auto-migrates safely
- ✅ Export/import still works
- ✅ No forced features
- ✅ Can downgrade to v1 (theoretical)

**v2 Features: All Optional**

- Single model chat: Default (same as v1)
- Comparison mode: Opt-in
- Web search: Requires API key + toggle
- TTS: Opt-in in settings
- Tasks: Used only when created
- MCP: Connect only if desired

---

## 🚀 Performance Targets

| Metric | v1 | v2 | Delta |
|--------|----|----|-------|
| Cold start | 2.3s | 2.5s | +200ms |
| Warm start | 0.8s | 0.8s | None |
| Memory idle | 10MB | 13-15MB | +3-5MB |
| Memory load | 40MB | 45-50MB | +5-10MB |
| Chat (single) | 2-3s | 2-3s | None |
| Chat (dual) | N/A | 3-4s | New feature |
| Web search | N/A | <3s | New feature |

**Optimization strategies:**
- Lazy load new providers with `autoDispose`
- Local caching (search results, MCP tools)
- Parallel execution (dual model, tools)
- Efficient database indexes

---

## 🔒 Security Considerations

### API Keys
- ✅ Jina API key in secure storage (flutter_secure_storage)
- ✅ Never logged or exposed
- ✅ Validated format before storage
- ✅ Can be cleared from settings

### Input Validation
- ✅ Search queries sanitized (no HTML/JS)
- ✅ URLs validated before fetching
- ✅ Task definitions type-checked
- ✅ MCP permissions whitelist-based

### Network Security
- ✅ HTTPS only for all remote calls
- ✅ Certificate pinning optional (for extra security)
- ✅ Timeouts on all requests
- ✅ Retry only for transient errors

### Data Privacy
- ✅ All conversations local first
- ✅ No cloud sync (user choice for backup)
- ✅ Tool results not sent to cloud
- ✅ MCP servers user-controlled

---

## 📈 Metrics & Analytics

**Track Usage:**
- Tool calls per conversation (understand feature adoption)
- Model comparison frequency (A/B preference)
- Web search success rate (troubleshoot Jina integration)
- Task completion rate (feature reliability)
- Average response time (performance)

**User Feedback:**
- UI/UX satisfaction (surveys)
- Feature requests (prioritize Phase 2+)
- Bug reports (rapid fixes)
- Performance complaints (optimize)

---

## 🧪 Testing Strategy Summary

### Test Coverage Goals
- **Unit Tests:** 90%+ for new services
- **Integration Tests:** 100% for critical paths
- **Widget Tests:** All new UI components
- **E2E Tests:** Core user flows

### Regression Tests
- All v1 tests pass (100%)
- Single-model chat unchanged
- Message persistence
- Export/import
- Settings migration

---

## 📚 Documentation Structure

```
docs/
├── ARCHITECTURE_V2.md              [System design, phases]
├── JINA_INTEGRATION_SPEC.md        [Web search implementation]
├── UX_DESIGN_V2.md                 [UI/UX specification]
├── UX_DESIGN_V2_COMPONENTS.md      [Component specs]
├── UX_DESIGN_V2_FLOWS.md           [User journeys]
├── V2_IMPACT_ANALYSIS.md           [v1 compatibility]
├── V2_ARCHITECTURE_QUICK_REFERENCE.md [Quick lookup]
└── V2_COMPLETE_SUMMARY.md          [This file]
```

**Total:** 5,000+ lines of architecture & design documentation

---

## 🎓 Key Learnings & Design Patterns

### 1. Streaming Architecture Pattern
```dart
// Model-agnostic, works for dual-model comparison
Stream<Message> streamResponse(Message userMessage) {
  final controller = StreamController<Message>();
  
  // Can stream from 1+ models
  _streamModel1().listen((chunk) => controller.add(chunk));
  _streamModel2().listen((chunk) => controller.add(chunk));
  
  return controller.stream;
}
```

### 2. Tool Invocation Pattern
```dart
// Ollama native format, model-agnostic
if (response.toolCalls != null) {
  for (final call in response.toolCalls) {
    final result = await executeToolByName(call.name, call.args);
    sendResultBackToModel(result);
  }
}
```

### 3. Feature Toggle Pattern
```dart
// Optional features, graceful degradation
if (modelSupportsTools && jinaApiKeyValid) {
  // Include tools in request
} else {
  // Request without tools (works fine)
}
```

### 4. Offline-First Pattern
```dart
// Always save locally, sync asynchronously
saveToDB(data);           // Instant
syncToServer(data).then((_) {
  markSynced();
}).catchError((e) {
  queueForRetry();        // Retry later
});
```

---

## ✨ Implementation Highlights

### What Makes This v2 Design Strong

1. **Zero Breaking Changes**
   - Pure additive architecture
   - All v1 features preserved
   - Database auto-migrated
   - Graceful feature fallback

2. **Proven Technologies**
   - Riverpod (type-safe state)
   - SQLite (reliable persistence)
   - Flutter ecosystem packages
   - Ollama native tools
   - Jina API (simple, affordable)

3. **Clear Separation of Concerns**
   - Presentation isolated from domain
   - Domain isolated from data
   - Services handle external APIs
   - Easy to test each layer

4. **Scalable Architecture**
   - Can add more tools (code search, calculator, etc.)
   - Can support 4+ models easily
   - MCP protocol extensible
   - Task system generic

5. **User-Centric Design**
   - Features are optional toggles
   - Progressive disclosure (no UI clutter)
   - Familiar patterns (similar to v1)
   - Accessibility first-class

---

## 🚦 Next Steps

### Immediate (Week -1)
1. ✅ Review architecture documents
2. ✅ Gather team feedback
3. ✅ Adjust designs based on feedback
4. ✅ Create implementation tasks

### Start Implementation (Week 1)
1. Create v2 feature branch
2. Set up Phase 1 structure
3. Begin JinaSearchService
4. Create database migrations
5. Set up new Riverpod providers

### Continuous
1. Implement by phase (strict sequencing)
2. Write tests for each component
3. Review for v1 compatibility
4. Optimize performance
5. Gather feedback from beta testers

---

## 📞 Questions to Answer Before Starting

1. **API Key Management:** Store Jina key client-side or server-side?
   - **Design:** Client-side in secure storage (user controls)

2. **Quota Tracking:** How to monitor Jina usage?
   - **Design:** Local tracking + monthly cost estimate

3. **Task Persistence:** Keep tasks after app restart?
   - **Design:** Yes, in SQLite with status tracking

4. **Model Selection:** Show tool capability status?
   - **Design:** Yes, with visual indicators in model list

5. **Comparison Save:** Store comparison conversations?
   - **Design:** Yes, can rerun or reference later

---

## 🎉 Conclusion

This comprehensive v2 architecture design provides:

✅ **Complete specification** for 5 phases of features
✅ **Technical implementation** details (not vague)
✅ **Full backward compatibility** (zero breaking changes)
✅ **Production-ready design** (uses proven technologies)
✅ **Clear roadmap** (18-27 weeks, realistic timeline)
✅ **Quality assurance** (testing strategy included)
✅ **User experience** (wireframes, flows, components)
✅ **Security & performance** (considered throughout)

**Ready for implementation!**

---

**Architecture Review Completed:** January 3, 2026  
**Design Status:** ✅ APPROVED FOR IMPLEMENTATION  
**Estimated Timeline:** Q2 2026 (18-27 weeks)  
**Breaking Changes:** ✅ NONE

