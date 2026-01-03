# v2 Planning Quick Reference

**Created:** January 3, 2026  
**Purpose:** Quick summary of v2 features and planning documents

---

## 📚 Documentation Files Created

| Document | Purpose | Location |
|----------|---------|----------|
| **PRODUCT_ROADMAP_V2.md** | Overall vision, phasing, timeline | [docs/PRODUCT_ROADMAP_V2.md](PRODUCT_ROADMAP_V2.md) |
| **USER_STORIES_V2.md** | Detailed user stories with acceptance criteria | [docs/USER_STORIES_V2.md](USER_STORIES_V2.md) |
| **REQUIREMENTS_V2.md** | Functional and non-functional requirements | [docs/REQUIREMENTS_V2.md](REQUIREMENTS_V2.md) |

---

## 🎯 v2 Features at a Glance

### Phase 1: Tool Calling (8-10 weeks, P0)
**Foundation for advanced features**

- ✅ Tool calling framework (abstract interface)
- ✅ Web search tool (search, caching, results)
- ✅ Tool result rendering (cards, timeline)
- ✅ Web search configuration (API key, settings)
- ✅ Error handling and fallbacks

**Success Criteria:** 95%+ tool success rate, < 3s response time

---

### Phase 2: Model Comparison (6-8 weeks, P0)
**Differentiator from competitors**

- ✅ Side-by-side model comparison chat
- ✅ Parallel model requests (2-4 models)
- ✅ Response aggregation and metrics
- ✅ Model switching in conversation
- ✅ Response diff highlighting
- ✅ Performance metrics per model

**Success Criteria:** 40%+ users try comparison, metrics 95% accurate

---

### Phase 3: Native Android Integration (6-8 weeks, P0)
**User delight + engagement**

- ✅ Share intent (receive text & images)
- ✅ Share conversation to other apps
- ✅ Text-to-speech (play, speed, voice control)
- ✅ Streaming TTS (while generating)
- ✅ Clipboard integration

**Success Criteria:** 30%+ share intent, 25%+ TTS enabled

---

### Phase 4: Thinking Models & Tasks (8-10 weeks, P1)
**Advanced use cases**

- ✅ Thinking model detection and display
- ✅ Long-running task framework (2-20 steps)
- ✅ Task progress UI and tracking
- ✅ Background task execution
- ✅ Task templates and reusable workflows
- ✅ Result caching and resumption

**Success Criteria:** 30%+ power users enable thinking, 90%+ task success

---

### Phase 5: Remote MCP Integration (6-8 weeks, P1)
**Enterprise + advanced users**

- ✅ MCP server discovery and configuration
- ✅ Dynamic tool invocation via MCP
- ✅ MCP tool permissions and management
- ✅ Tool discovery from MCP servers

**Success Criteria:** 20%+ users configure MCP, 95%+ tool invocation success

---

## 🏗️ Architecture Overview

### New Services Required

```
Tool Calling Layer
├─ ToolCallingService (orchestration)
├─ WebSearchService (web search implementation)
├─ MCPService (MCP server communication)
├─ ThinkingModelService (reasoning support)
└─ ToolResultRenderer (UI formatting)

Comparison Layer
├─ ModelComparisonService (parallel requests)
├─ ResponseAggregationService
└─ MetricsCollectionService

Native Integration Layer
├─ ShareIntentService (intent handling)
├─ TextToSpeechService (TTS)
└─ ClipboardService

Task Management Layer
├─ LongRunningTaskService (orchestration)
├─ TaskPersistenceService (state storage)
├─ TaskProgressUIService
└─ BackgroundTaskService

MCP Integration Layer
├─ MCPDiscoveryService
├─ MCPConnectionService
└─ MCPToolService
```

### Data Models

- `Tool`, `ToolResult`, `ToolSchema`
- `ComparisonMessage`, `ModelComparison`
- `LongRunningTask`, `TaskStep`
- `MCPServer`, `MCPTool`
- `ResponseMetrics`, `ModelStatistics`

---

## 🚀 Implementation Sequence

### Critical Path (What to Build First)

1. **TOOL-001**: Tool calling framework (foundation)
2. **TOOL-002**: Web search tool (first real tool)
3. **TOOL-003**: Tool result rendering (UI)
4. **COMP-001**: Model comparison (validates architecture)
5. **INTENT-001**: Share intent (parallel, quick win)
6. **TTS-001**: Text-to-speech (parallel, quick win)
7. **TASK-001**: Long-running task framework (foundation)
8. **MCP-001**: MCP discovery (foundation)

### Dependency Graph

```
TOOL-001 (Tool Framework)
├─ TOOL-002 (Web Search) ─┐
├─ TOOL-003 (Rendering)   │
├─ TOOL-004 (Config)      │
├─ TOOL-005 (Error H.)    │
└─ COMP-001 (Comparison) ─┘ (depends on TOOL-*)

COMP-001 ─┬─ COMP-002 (Metrics)
          ├─ COMP-003 (Model Switch)
          ├─ COMP-004 (Response Diff)
          └─ COMP-005 (Branching)

INTENT-001 (Text Share) ─┬─ INTENT-002 (Images)
                         ├─ INTENT-003 (Send)
                         └─ TTS-001 ─┬─ TTS-002 (Config)
                                     └─ TTS-003 (Streaming)

TASK-001 (Task Framework) ─┬─ TASK-002 (Progress UI)
                           ├─ TASK-003 (Background)
                           ├─ TASK-004 (Templates)
                           ├─ TASK-005 (Caching)
                           └─ THINK-001 (Thinking Models)

MCP-001 (Discovery) ─┬─ MCP-002 (Invocation)
                     └─ MCP-003 (Permissions)
```

---

## 📊 Effort Estimation

| Phase | Effort | Weeks | Stories |
|-------|--------|-------|---------|
| 1 | 45 pts | 8-10 | 5 |
| 2 | 35 pts | 6-8 | 5 |
| 3 | 48 pts | 6-8 | 8 |
| 4 | 52 pts | 8-10 | 5 |
| 5 | 32 pts | 6-8 | 3 |
| **TOTAL** | **212 pts** | **34-44 weeks** | **26** |

**Velocity Assumption:** 8-12 pts/week
**Timeline:** 4-6 months (with good team velocity)

---

## 🎯 Phase Priorities & Rationale

### Phase 1: Tool Calling (P0 - Start Immediately)
**Why First:**
- Foundation for all advanced features (comparison, MCP, thinking)
- High user value (internet info in chat)
- Enables future extensibility
- Validates real-time interaction architecture

---

### Phase 2: Model Comparison (P0 - Parallel or Immediate After Phase 1)
**Why Second:**
- Builds on tool calling architecture
- Primary differentiator from ChatGPT/Claude
- Appeals to power users and developers
- Validates parallel request handling

**Can Start:** End of Week 4 (while finishing Phase 1 cleanup)

---

### Phase 3: Native Integration (P0 - Parallel Track)
**Why Third (or Parallel):**
- Independent from tool calling/comparison
- Quick wins for user engagement
- Android integration is expected
- Share intent + TTS improve retention

**Can Start:** Week 1 in parallel with Phase 1

---

### Phase 4: Thinking Models & Tasks (P1 - After Phase 1)
**Why Fourth:**
- Depends on tool calling foundation
- Addresses power users
- Requires stable architecture
- Complex feature that needs time

**Can Start:** Week 10-12 (after Phase 1 stabilizes)

---

### Phase 5: MCP Integration (P1 - After Phase 1)
**Why Fifth:**
- Builds on tool calling framework
- Enterprise feature (lower priority)
- Requires stable tool calling first
- Specialized use case

**Can Start:** Week 12-14

---

## 🚨 Key Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Web search latency impacts UX | HIGH | Implement 3s timeout, streaming, caching |
| Parallel requests overload Ollama | HIGH | Queue management, rate limiting |
| Tool framework too complex | MEDIUM | Start simple, iterate on design |
| MCP discovery complexity | MEDIUM | Manual config first, auto-discover v2.1 |
| TTS battery drain | MEDIUM | Make optional, add power modes |
| Task state loss on crashes | HIGH | Persist after every step |
| Integration complexity | MEDIUM | Modular design, thorough testing |

---

## ✅ Success Metrics Summary

### Phase 1
- Tool success rate > 95%
- Search latency < 3s (p95)
- 60%+ users try web search

### Phase 2
- 40%+ users try comparison
- Metrics accuracy > 95%
- Session duration 2x longer

### Phase 3
- 30%+ use share intent
- 25%+ enable TTS
- Share action in 20%+ of conversations

### Phase 4
- 30%+ power users try thinking
- Task success > 90%
- Background stability > 99%

### Phase 5
- 20%+ configure MCP
- Tool success > 95%
- No security incidents

---

## 📞 Related Documents

- [PRODUCT_VISION.md](PRODUCT_VISION.md) - Original product vision
- [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) - v1 requirements
- [USER_STORIES_MVP.md](USER_STORIES_MVP.md) - v1 user stories
- [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md) - v1 architecture

---

## 🔍 Next Steps for Your Team

### Week 1 Preparation
- [ ] Review all v2 documents
- [ ] Identify team members for each phase
- [ ] Set up project tracking (GitHub Projects, Jira, etc.)
- [ ] Prioritize stories within Phase 1

### Week 2 Kickoff
- [ ] Design Phase 1 architecture with team
- [ ] Create design mocks for new UI components
- [ ] Research and evaluate tool calling options (OpenAI format, Ollama, etc.)
- [ ] Research web search APIs
- [ ] Estimate Phase 1 stories more precisely

### Week 3-4 Implementation Starts
- [ ] Architecture PRs merged
- [ ] TOOL-001 (Tool framework) implemented
- [ ] Data models defined
- [ ] Unit tests for tool interface

---

## 💡 Key Principles for v2

1. **Progressive Enhancement**: Each phase builds on previous
2. **User Value First**: Prioritize visible user benefits
3. **Architecture Quality**: Invest in solid foundations (tool calling, task framework)
4. **Performance Obsession**: Every feature optimized from day 1
5. **Privacy Maintained**: All v2 features respect privacy-first principles
6. **Testing Rigor**: > 80% code coverage across all phases

---

## 📖 How to Use These Documents

### For Product Managers
- Use [PRODUCT_ROADMAP_V2.md](PRODUCT_ROADMAP_V2.md) for timeline and phasing
- Reference [USER_STORIES_V2.md](USER_STORIES_V2.md) for feature definitions
- Track success metrics from each phase

### For Developers
- Read [REQUIREMENTS_V2.md](REQUIREMENTS_V2.md) for detailed specs
- Reference [USER_STORIES_V2.md](USER_STORIES_V2.md) for acceptance criteria
- Use story IDs when creating GitHub issues

### For Designers
- Review Phase 3 for UI/UX needs (Native Integration)
- Check Phase 2 for comparison view design
- Reference Phase 4 for task progress UI
- Design TTS controls and share intent flows

### For QA/Testing
- Use acceptance criteria from [USER_STORIES_V2.md](USER_STORIES_V2.md)
- Reference non-functional requirements from [REQUIREMENTS_V2.md](REQUIREMENTS_V2.md)
- Create test cases for each story
- Plan performance testing for tool calling and comparison

---

## 🎉 You're Ready to Build v2!

These three documents provide everything needed to plan, design, and build v2 features. They're detailed enough to guide implementation but flexible enough to adapt to your team's needs.

Happy building! 🚀

