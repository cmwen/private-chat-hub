# Local & Remote Model System - Complete Documentation Index

## Overview

This index provides quick access to all documentation related to the unified local (LiteRT) and remote (Ollama) model system with offline support and automatic message queueing.

**Last Updated:** January 25, 2026

---

## Documentation Files

### 1. UX Design Specification
**File:** [UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md](UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md)

**Purpose:** Complete user experience design for the local/remote model system

**Contents:**
- Design goals and principles
- User workflows (model selection, chatting, offline mode)
- Visual design specifications (banners, icons, indicators)
- Settings and configuration UI
- Edge cases and error handling
- Accessibility considerations
- Responsive design
- Animation specifications

**Audience:** UX designers, product managers, developers

---

### 2. Technical Architecture
**File:** [ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md](ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md)

**Purpose:** Technical architecture and implementation details

**Contents:**
- System architecture diagram
- Core components (ChatService, UnifiedModelService, ConnectivityService, MessageQueueService)
- Data flow diagrams
- Message status state machine
- Storage schema
- API contracts
- Error handling strategies
- Performance considerations
- Testing strategy

**Audience:** Developers, architects

---

### 3. User Guide
**File:** [USER_GUIDE_LOCAL_REMOTE_MODELS.md](USER_GUIDE_LOCAL_REMOTE_MODELS.md)

**Purpose:** End-user documentation and help

**Contents:**
- Getting started guide
- Model selection instructions
- Offline mode explanation
- Message status indicators
- Managing local models
- Settings and preferences
- Common scenarios (commuting, privacy, unreliable connection)
- Troubleshooting guide
- FAQ
- Model comparison table

**Audience:** End users

---

## Related Documentation

### Existing LiteRT Documentation

**LiteRT Integration Audit:**
- File: [audit/LITERT_INTEGRATION_AUDIT.md](../audit/LITERT_INTEGRATION_AUDIT.md)
- Overview of LiteRT-LM integration
- Feature set and capabilities
- Implementation summary

**LiteRT Quick Reference:**
- File: [audit/LITERT_QUICK_REFERENCE.md](../audit/LITERT_QUICK_REFERENCE.md)
- Quick reference for developers
- Code examples
- Available models

**LiteRT Implementation Guide:**
- File: [audit/LITERT_IMPLEMENTATION_GUIDE.md](../audit/LITERT_IMPLEMENTATION_GUIDE.md)
- Detailed implementation guide
- Service layer documentation
- Native platform details

### Architecture Documentation

**Architecture Decisions:**
- File: [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md)
- Core architectural decisions
- Offline-first architecture
- Connection reliability

**Technical Feasibility:**
- File: [TECHNICAL_FEASIBILITY.md](TECHNICAL_FEASIBILITY.md)
- Technical challenges
- Connection reliability
- Model download management

### UX Documentation

**UX Design Decisions:**
- File: [UX_DESIGN_DECISIONS.md](UX_DESIGN_DECISIONS.md)
- Connection status visibility
- Error handling
- Graceful degradation for offline

**User Flows:**
- File: [USER_FLOWS.md](USER_FLOWS.md)
- User interaction flows
- Conversation workflows

**User Stories:**
- File: [USER_STORIES_MVP.md](USER_STORIES_MVP.md)
- User stories for MVP
- Connection setup
- Model management

---

## Quick Links by Role

### For Product Managers

**Start here:**
1. [UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md](UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md) - Complete UX design
2. [USER_GUIDE_LOCAL_REMOTE_MODELS.md](USER_GUIDE_LOCAL_REMOTE_MODELS.md) - End-user experience

**Then review:**
- [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) - Product requirements
- [USER_STORIES_MVP.md](USER_STORIES_MVP.md) - User stories

### For Developers

**Start here:**
1. [ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md](ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md) - Technical architecture
2. [audit/LITERT_QUICK_REFERENCE.md](../audit/LITERT_QUICK_REFERENCE.md) - Quick reference

**Then review:**
- [audit/LITERT_IMPLEMENTATION_GUIDE.md](../audit/LITERT_IMPLEMENTATION_GUIDE.md) - Implementation details
- [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md) - Architecture decisions

### For UX Designers

**Start here:**
1. [UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md](UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md) - Complete UX design
2. [UX_DESIGN_DECISIONS.md](UX_DESIGN_DECISIONS.md) - Design decisions

**Then review:**
- [USER_FLOWS.md](USER_FLOWS.md) - User flows
- [USER_PERSONAS.md](USER_PERSONAS.md) - User personas

### For End Users

**Start here:**
1. [USER_GUIDE_LOCAL_REMOTE_MODELS.md](USER_GUIDE_LOCAL_REMOTE_MODELS.md) - Complete user guide

---

## Key Concepts

### Model Types

**Local Models (On-Device):**
- Run entirely on your device
- Work offline
- Privacy-focused
- Identified by 📱 icon
- Prefix: `local:` in model ID

**Remote Models (Ollama):**
- Run on Ollama server
- More powerful
- Require connection
- Identified by 🌐 icon
- No prefix in model ID

### Message States

```
draft → queued → sending → sent
                          ↓
                       failed
```

- **draft:** Being composed
- **queued:** Waiting to send (offline)
- **sending:** Currently transmitting
- **sent:** Successfully delivered
- **failed:** Send failed

### Offline Mode

**Automatic Queueing:**
- Messages queue when offline
- Send automatically when connection restored
- FIFO processing (first in, first out)
- Max 50 messages per queue

**Local Model Fallback:**
- If offline with remote model selected
- System can suggest using local model
- Seamless continuation without queueing

---

## Implementation Status

### ✅ Completed

- [x] ChatService routing logic
- [x] UnifiedModelService (combine local + remote)
- [x] ConnectivityService (monitor connection)
- [x] MessageQueueService (queue management)
- [x] OnDeviceLLMService (local inference)
- [x] Message status indicators
- [x] Queue persistence

### 🚧 In Progress

- [ ] UI integration (model selector with unified list)
- [ ] Queue status banner in UI
- [ ] Message status icons in chat UI
- [ ] Retry actions in UI
- [ ] Local fallback prompt

### 📋 Planned

- [ ] Queue management UI
- [ ] Model download progress in UI
- [ ] Advanced settings screen
- [ ] Background queue processing
- [ ] Push notifications for queue completion

---

## System Requirements

### For Local Models

**Minimum:**
- Android 7.0+ (API 24)
- 2 GB RAM
- 1 GB free storage (for smallest model)

**Recommended:**
- Android 10+ (API 29)
- 4 GB RAM
- 5 GB free storage (for multiple models)

**Optimal:**
- Android 12+ (API 31)
- 8 GB RAM
- 10 GB free storage
- NPU/GPU acceleration

### For Remote Models

**Requirements:**
- Network connection (Wi-Fi or cellular)
- Running Ollama server
- Server URL configured

---

## Common Tasks

### How to Select a Model

1. Open conversation list
2. Tap model name or "New Conversation"
3. See unified list of all models
4. Tap desired model
5. If local model not downloaded, tap [Download]

### How to Work Offline

**With Local Model:**
1. Download local model (one-time)
2. Select local model
3. Chat works offline automatically

**With Remote Model:**
1. Messages queue automatically when offline
2. Send when connection restored
3. Or switch to local model for immediate response

### How to Manage Queue

**View Queue:**
- Tap [View Queue] in offline banner

**Retry Messages:**
- Tap [Retry Now] in banner
- Or tap individual message → [Retry]

**Cancel Message:**
- Tap message → View details → [Cancel]

### How to Download Local Model

**Option 1: From Model Selector**
1. Tap model with [Download] button
2. Confirm download
3. Wait for completion

**Option 2: From Settings**
1. Settings → Manage On-Device Models
2. Tap [Download] next to model
3. Track progress

---

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Messages stuck in queue | Check Ollama connection, tap [Retry Now] |
| Message shows failed (⚠️) | Tap [Retry] button on message |
| Local model not working | Check download complete, restart app |
| Download stuck | Check Wi-Fi, retry download |
| Queue full error | Wait for processing or clear queue |
| Connection error | Verify Ollama running, test connection |

---

## Performance Metrics

### Expected Performance

**Message Send Time:**
- Local model: 50-200ms (first token)
- Remote model (online): 100-500ms (first token)
- Queued message processing: < 5s after reconnect

**Model Loading:**
- Small models (< 1GB): 1-2 seconds
- Medium models (2-3GB): 2-4 seconds
- Large models (4GB+): 4-6 seconds

**Download Time** (on average Wi-Fi):
- 500 MB: ~2 minutes
- 2.9 GB: ~10 minutes
- 4.1 GB: ~15 minutes

---

## Security & Privacy

### Local Models
- ✅ All processing on-device
- ✅ No data leaves device
- ✅ No server logs
- ✅ Works completely offline

### Remote Models
- ⚠️ Data sent to Ollama server
- ⚠️ Server logs may exist
- ⚠️ Network transmission
- ℹ️ Usually on local network (privacy better than cloud)

### Message Queue
- ✅ Stored in app-private storage
- ✅ No external access
- ✅ Encrypted if device encrypted

---

## Future Enhancements

### Short Term
- Improved queue management UI
- Better error messages
- Model download progress indicators
- Retry with different model option

### Medium Term
- Background queue processing
- Push notifications for completion
- Smart model suggestions
- Queue prioritization

### Long Term
- Multi-device queue sync
- Federated learning
- Model caching strategies
- Cloud backup for local models

---

## API Reference (For Developers)

### Key Classes

**ChatService:**
```dart
Stream<Conversation> sendMessage(String conversationId, String text)
Future<Conversation> queueMessage(String conversationId, String text)
Future<void> processMessageQueue()
bool get isOnline
```

**UnifiedModelService:**
```dart
Future<List<ModelInfo>> getUnifiedModelList(List<OllamaModelInfo> ollamaModels)
static bool isLocalModel(String modelId)
static bool isRemoteModel(String modelId)
```

**MessageQueueService:**
```dart
Future<void> enqueue({required String conversationId, required String messageId})
QueueItem? getNextQueueItem()
Future<void> remove(String itemId)
int getQueueCount()
```

**ConnectivityService:**
```dart
Stream<OllamaConnectivityStatus> get statusStream
OllamaConnectivityStatus get currentStatus
bool get isOnline
Future<void> refresh()
```

---

## Glossary

**API:** Application Programming Interface - how software components communicate

**FIFO:** First In, First Out - queue processing order

**LiteRT:** Google's on-device AI runtime for mobile inference

**Model ID:** Unique identifier for a model (e.g., "llama3:latest" or "local:gemma3-1b")

**Offline Mode:** App state when no Ollama connection available

**Ollama:** Open-source platform for running large language models locally

**Queue:** List of messages waiting to be sent when offline

**Stream:** Real-time data flow (for streaming AI responses)

**Unified List:** Combined list showing both local and remote models

---

## Contact & Support

### For Users

**In-App Help:**
- Settings → Help & Support
- Access user guide
- Report issues

**Community:**
- GitHub Issues (for bugs)
- GitHub Discussions (for questions)

### For Developers

**Documentation:**
- This index
- Architecture documents
- API documentation

**Code:**
- `lib/services/` - Service implementations
- `lib/widgets/` - UI components
- `lib/screens/` - Screen implementations

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Jan 25, 2026 | Initial documentation |
| | | - Complete UX design |
| | | - Architecture specification |
| | | - User guide |
| | | - Documentation index |

---

## Contributing

### Documentation Updates

When updating docs:

1. Update relevant document
2. Update this index if needed
3. Update version history
4. Submit PR with clear description

### New Features

When adding features:

1. Update architecture document
2. Update user guide if user-facing
3. Update UX design if UI changes
4. Add to implementation status

---

**End of Index**
