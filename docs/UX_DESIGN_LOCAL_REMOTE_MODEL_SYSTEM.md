# UX Design: Local & Remote Model System with Offline Support

## Overview

This document defines the user experience for a unified model selection system that seamlessly integrates local (LiteRT) and remote (Ollama) models, with intelligent offline mode that queues messages and automatically resends when connectivity is restored.

**Date:** January 25, 2026  
**Status:** Design Specification  
**Related Documents:**
- [LITERT_INTEGRATION_AUDIT.md](../audit/LITERT_INTEGRATION_AUDIT.md)
- [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md)
- [USER_FLOWS.md](USER_FLOWS.md)

---

## Design Goals

1. **Unified Experience**: Users shouldn't need to think about "local vs remote" - just select any model
2. **Intelligent Routing**: System automatically routes to appropriate backend based on model type
3. **Seamless Offline**: Messages queue automatically when offline, resend when reconnected
4. **Clear Status**: Always show connection state and queue status
5. **Zero Friction**: No extra steps or configuration for basic usage

---

## User Personas

### Primary: Alex (Privacy-Conscious Developer)
- Wants local inference for sensitive conversations
- Needs offline capability for commuting/travel
- Expects automatic queue handling

### Secondary: Jordan (Power User)
- Uses both local and remote models
- Wants to see which backend is active
- Needs queue management visibility

---

## Information Architecture

```
App Structure
├── Conversation List
│   ├── Model Selector (Unified List)
│   │   ├── Remote Models (Ollama)
│   │   └── Local Models (LiteRT)
│   ├── Connection Status Banner
│   └── Queue Status Banner
├── Chat Screen
│   ├── Active Model Indicator
│   ├── Connection Status
│   ├── Queue Status Banner
│   └── Message Status Indicators
└── Settings
    ├── Inference Mode (Auto/Remote-Only/Local-Only)
    ├── Manage Local Models
    └── Offline Behavior
```

---

## Key Workflows

### Workflow 1: Selecting a Model (Unified)

```
User opens Conversation List
    ↓
Taps "New Conversation" or model selector
    ↓
Sees unified list:
┌─────────────────────────────┐
│ Select Model                │
├─────────────────────────────┤
│ 🌐 llama3:latest           │ ← Remote (Ollama)
│    8B parameters            │
│                             │
│ 🌐 mistral:latest          │ ← Remote (Ollama)
│    7B parameters            │
│                             │
│ 📱 Gemma 3 1B              │ ← Local (Downloaded)
│    557 MB • On-Device      │
│                             │
│ 📱 Gemma 3n E2B            │ ← Local (Available)
│    2.9 GB • Download       │
└─────────────────────────────┘
```

**Visual Distinctions:**
- **Remote models**: Cloud icon (🌐), standard label
- **Downloaded local**: Phone icon (📱), "On-Device" badge
- **Available local**: Phone icon (📱), "Download" button
- **Model type shown subtly**, not prominently

**Interaction:**
1. User taps any model
2. If remote → Creates conversation, uses Ollama
3. If local (downloaded) → Creates conversation, uses LiteRT
4. If local (not downloaded) → Shows download dialog first

---

### Workflow 2: Chatting with Any Model

```
User sends message in conversation
    ↓
System checks:
1. Is selected model local or remote?
2. Is connection available (for remote)?
3. Should message be queued?
    ↓
Routes automatically:
├─ Local model → Use LiteRT (always works)
├─ Remote + Online → Use Ollama
└─ Remote + Offline → Queue message
```

**Message Status Indicators:**

```
┌────────────────────────────────────┐
│ You                           10:30│
│ What is machine learning?          │  ← Sent (✓)
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ You                           10:31│
│ Explain neural networks            │  ← Queued (📤⏳)
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ You                           10:32│
│ Tell me about AI                   │  ← Sending (⌛)
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ You                           10:33│
│ What is deep learning?             │  ← Failed (⚠️)
│ [Retry]                            │
└────────────────────────────────────┘
```

**Status Icons:**
- ✓ = Sent successfully
- 📤⏳ = Queued (will send when online)
- ⌛ = Currently sending
- ⚠️ = Failed (with retry button)

---

### Workflow 3: Offline Mode with Queue

**Scenario A: User Goes Offline While Chatting**

```
User is chatting with remote model
    ↓
Network connection drops
    ↓
Banner appears:
┌──────────────────────────────────────────────┐
│ 🔌 Offline • 2 messages queued               │
│                                              │
│ Messages will send automatically when        │
│ connection is restored                       │
│                                              │
│         [Retry Now]  [View Queue]           │
└──────────────────────────────────────────────┘
    ↓
User continues typing
    ↓
Each message is queued automatically
    ↓
User sees queued indicator on messages
```

**Scenario B: Connection Restores**

```
Connection restored
    ↓
Banner updates:
┌──────────────────────────────────────────────┐
│ ✓ Connected • Sending 2 queued messages...  │
│                                              │
│ [Sending message 1 of 2]                    │
└──────────────────────────────────────────────┘
    ↓
System processes queue in FIFO order
    ↓
Each message:
- Changes from "queued" to "sending"
- Gets response from model
- Updates to "sent"
    ↓
Banner disappears when queue is empty
    ↓
User sees success toast:
"All queued messages sent"
```

**Scenario C: User With Local Model Goes Offline**

```
User is chatting with local model
    ↓
Network connection drops
    ↓
No banner appears
    ↓
User continues chatting normally
    ↓
Local inference continues working
```

> **Key Insight:** Local models make offline mode transparent. Users with local models shouldn't even notice connectivity changes.

---

### Workflow 4: Intelligent Fallback

**Scenario: Remote Model + Offline + Local Model Available**

```
User tries to send to remote model
    ↓
System detects offline
    ↓
System checks: Is local model available?
    ↓
If YES:
┌──────────────────────────────────────────────┐
│ ⚠️ Ollama Offline                            │
│                                              │
│ Would you like to use local model instead?  │
│                                              │
│     [Use Local (Gemma 3 1B)]  [Queue]       │
└──────────────────────────────────────────────┘
    ↓
User taps "Use Local"
    ↓
Message sent immediately via LiteRT
    ↓
Conversation continues with local model
```

**If NO local model available:**
- Message is queued automatically
- Banner shows queue status
- No interruption to user flow

---

## Visual Design Specifications

### Connection Status Indicator (Top Bar)

**States:**

1. **Connected**
```
┌────────────────────────────────┐
│ ● Connected to Ollama          │  ← Green dot
└────────────────────────────────┘
```

2. **Disconnected**
```
┌────────────────────────────────┐
│ ● Ollama Offline               │  ← Orange dot
└────────────────────────────────┘
```

3. **Local Mode**
```
┌────────────────────────────────┐
│ 📱 Using Local Model           │  ← Phone icon
└────────────────────────────────┘
```

4. **Error**
```
┌────────────────────────────────┐
│ ⚠️ Connection Error            │  ← Red warning
└────────────────────────────────┘
```

**Placement:** 
- Conversation List: Below app bar
- Chat Screen: Below app bar, above messages
- Dismissible: User can dismiss temporarily
- Auto-shows: Reappears on state change

---

### Queue Status Banner (Contextual)

**Design Principles:**
- Only show when relevant (has queued messages)
- Non-blocking (doesn't prevent usage)
- Actionable (provides retry/view options)
- Auto-updating (shows progress)

**Visual Style:**
```
Material 3 Container with:
- Rounded corners (12dp)
- Elevation (2dp)
- Padding (16dp vertical, 20dp horizontal)
- Background: Theme-appropriate
  - Orange/Amber for queued
  - Blue for processing
  - Green for success
```

**Layout:**
```
┌─────────────────────────────────────────────────┐
│ [Icon] Status Text                              │
│                                                 │
│ Optional: Subtitle/explanation                  │
│                                                 │
│ Optional: [Button 1]  [Button 2]               │
└─────────────────────────────────────────────────┘
```

---

### Model Selector (Unified List)

**List Item Design:**

```
┌─────────────────────────────────────────────────┐
│ [Icon] Model Name                    [Badge]    │
│        Subtitle/Details              [Action]   │
└─────────────────────────────────────────────────┘
```

**Examples:**

**Remote Model (Available):**
```
┌─────────────────────────────────────────────────┐
│ 🌐 llama3:latest                                │
│    8B parameters • 4.7 GB                       │
└─────────────────────────────────────────────────┘
```

**Local Model (Downloaded):**
```
┌─────────────────────────────────────────────────┐
│ 📱 Gemma 3 1B                      [On-Device]  │
│    Fast inference • 557 MB                      │
└─────────────────────────────────────────────────┘
```

**Local Model (Available for Download):**
```
┌─────────────────────────────────────────────────┐
│ 📱 Gemma 3n E2B                    [Download]   │
│    Balanced performance • 2.9 GB                │
└─────────────────────────────────────────────────┘
```

**Local Model (Downloading):**
```
┌─────────────────────────────────────────────────┐
│ 📱 Gemma 3n E4B                    [▓▓▓░░ 65%]  │
│    High quality • 4.1 GB                        │
└─────────────────────────────────────────────────┘
```

**Grouping:**
- **Option 1**: No grouping (mixed list, sorted by usage)
- **Option 2**: Subtle grouping by type (Local vs Remote headers)
- **Option 3**: Two tabs (Local | Remote)

**Recommendation**: Option 1 for simplicity, Option 2 for clarity with many models

---

### Message Status Icons

**In Chat Bubbles (Bottom-Right Corner):**

```
Your Message Text                    [✓]    ← Sent
Your Message Text                    [📤⏳] ← Queued
Your Message Text                    [⌛]   ← Sending
Your Message Text [Retry]            [⚠️]   ← Failed
```

**Size:** 16dp
**Color:** Theme-dependent (subtle, not distracting)
**Position:** Absolute bottom-right of message bubble
**Interaction:** Tappable for status details

**Status Details (on tap):**
```
┌─────────────────────────────────┐
│ Message Status                  │
├─────────────────────────────────┤
│ Status: Queued                  │
│ Queued at: 10:31 AM             │
│ Position: 2 of 5 in queue       │
│                                 │
│        [Retry Now] [Cancel]     │
└─────────────────────────────────┘
```

---

## Settings & Configuration

### Inference Mode (Advanced)

**Location:** Settings → Inference

```
┌─────────────────────────────────────────────────┐
│ Inference Mode                                  │
├─────────────────────────────────────────────────┤
│ ⚪ Automatic (Recommended)                      │
│    Use local or remote based on model          │
│                                                 │
│ ○ Remote Only                                   │
│    Always use Ollama server                     │
│                                                 │
│ ○ Local Only                                    │
│    Only use on-device models                    │
└─────────────────────────────────────────────────┘
```

**Default:** Automatic

**Behavior:**
- **Automatic**: System chooses based on model type and availability
- **Remote Only**: Fails if Ollama unavailable (no fallback)
- **Local Only**: Only shows local models in selector

---

### Offline Behavior

```
┌─────────────────────────────────────────────────┐
│ When Offline                                    │
├─────────────────────────────────────────────────┤
│ ☑ Queue messages automatically                  │
│   Messages will send when reconnected           │
│                                                 │
│ ☑ Offer local model fallback                    │
│   Suggest using local model if available        │
│                                                 │
│ ☑ Show queue status banner                      │
│   Display banner when messages are queued       │
└─────────────────────────────────────────────────┘
```

---

### Manage Local Models

```
┌─────────────────────────────────────────────────┐
│ On-Device Models                                │
├─────────────────────────────────────────────────┤
│                                                 │
│ Downloaded (2)                                  │
│                                                 │
│ 📱 Gemma 3 1B                     557 MB   [×]  │
│    Last used: Today                             │
│                                                 │
│ 📱 Phi-4 Mini                     3.6 GB   [×]  │
│    Last used: 2 days ago                        │
│                                                 │
│ ────────────────────────────────────────────    │
│                                                 │
│ Available to Download (3)                       │
│                                                 │
│ 📱 Gemma 3n E2B         2.9 GB    [Download]    │
│    Balanced performance                         │
│                                                 │
│ 📱 Gemma 3n E4B         4.1 GB    [Download]    │
│    High quality                                 │
│                                                 │
│ 📱 Qwen2.5 1.5B         1.5 GB    [Download]    │
│    Multilingual                                 │
│                                                 │
│ ────────────────────────────────────────────    │
│                                                 │
│ Storage: 4.1 GB used of 64 GB available         │
│                                                 │
│ [× Clear All Downloaded Models]                 │
└─────────────────────────────────────────────────┘
```

**Actions:**
- **Download**: Tapping downloads model with progress
- **[×]**: Delete downloaded model
- **Clear All**: Bulk delete with confirmation

---

## Edge Cases & Error Handling

### Edge Case 1: Queue Reaches Limit

**Scenario:** User queues 50+ messages (queue limit)

**Behavior:**
```
┌─────────────────────────────────────────────────┐
│ ⚠️ Queue Full                                   │
│                                                 │
│ Maximum queue size (50) reached.                │
│ Wait for connection or clear queue.             │
│                                                 │
│        [View Queue]  [Dismiss]                  │
└─────────────────────────────────────────────────┘
```

**New messages:**
- Show error immediately
- Don't add to queue
- Suggest viewing/clearing queue

---

### Edge Case 2: Model Deleted While In Use

**Scenario:** User deletes local model that's active in conversation

**Behavior:**
```
┌─────────────────────────────────────────────────┐
│ ⚠️ Model No Longer Available                    │
│                                                 │
│ "Gemma 3 1B" has been removed.                  │
│ Select a different model to continue.           │
│                                                 │
│           [Select Model]                        │
└─────────────────────────────────────────────────┘
```

**Actions:**
- Show dialog when trying to send
- Open model selector
- Don't allow sending until new model selected

---

### Edge Case 3: Download Fails

**Scenario:** Model download interrupted/failed

**Behavior:**
```
Model list shows:

┌─────────────────────────────────────────────────┐
│ 📱 Gemma 3n E2B              [⚠️ Retry Download] │
│    Download failed • 2.9 GB                     │
└─────────────────────────────────────────────────┘
```

**Actions:**
- Show error state in list
- Provide retry button
- Allow manual deletion of partial download

---

### Edge Case 4: Queue Processing Fails

**Scenario:** Connection restored but queue processing fails for some messages

**Behavior:**
```
┌─────────────────────────────────────────────────┐
│ ⚠️ Some Messages Failed                         │
│                                                 │
│ 3 of 5 queued messages couldn't be sent.       │
│                                                 │
│        [Retry Failed]  [View Details]           │
└─────────────────────────────────────────────────┘
```

**Actions:**
- Show which messages failed
- Provide bulk retry
- Allow individual message retry
- Option to cancel/delete failed messages

---

### Edge Case 5: Network Flapping

**Scenario:** Connection repeatedly drops and restores

**Behavior:**
- Debounce status changes (wait 3 seconds before showing)
- Don't spam user with repeated banners
- Consolidate multiple state changes into one notification

```
Instead of:
"Connected" → "Offline" → "Connected" → "Offline"

Show:
"Connection unstable. Messages may be delayed."
```

---

## Accessibility Considerations

### Screen Reader Support

1. **Status Announcements:**
   - Connection state changes announced
   - Queue status changes announced
   - Model selection announced

2. **Message Status:**
   - Each message status read aloud
   - Queue position announced
   - Failed messages clearly indicated

3. **Actions:**
   - All buttons have semantic labels
   - Retry/cancel actions clearly described
   - Progress updates announced

### Visual Accessibility

1. **Color Independence:**
   - Don't rely solely on color for status
   - Use icons + text + color
   - Support high contrast mode

2. **Icon Clarity:**
   - Icons should be recognizable
   - Paired with text labels
   - Size ≥ 24dp for touch targets

3. **Text Contrast:**
   - Status text: 4.5:1 minimum
   - Body text: 7:1 preferred
   - Icons: 3:1 minimum

### Keyboard Navigation

1. **Model Selector:**
   - Arrow keys to navigate list
   - Enter to select
   - Escape to close

2. **Queue Management:**
   - Tab through actions
   - Enter to activate
   - Space for checkboxes

---

## Responsive Design

### Phone (Portrait)

- Single column layout
- Full-width banners
- Stacked buttons in dialogs
- Bottom sheet for model selector

### Tablet (Landscape)

- Two-column layout (list + chat)
- Side panel for model selector
- Inline banners (not full width)
- Compact status indicators

### Desktop/Web

- Multi-column layout
- Persistent sidebar for navigation
- Inline model selector (dropdown)
- Toast notifications for status changes

---

## Animation & Transitions

### Queue Status Banner

**Appearance:**
- Slide down from top (200ms ease-out)
- Scale from 0.9 to 1.0

**Update:**
- Cross-fade text (150ms)
- Smooth progress bar animation

**Dismissal:**
- Slide up with fade (200ms ease-in)

### Message Status Changes

**Queued → Sending:**
- Icon morph animation (300ms)
- Subtle pulse

**Sending → Sent:**
- Checkmark scale-in (200ms)
- Brief highlight (500ms fade)

**Failed:**
- Shake animation (300ms)
- Red tint fade-in (200ms)

### Model Selection

**List Appearance:**
- Stagger items (50ms delay each)
- Fade + slide up

**Selection:**
- Ripple effect on tap
- Scale selected item (0.98)
- Smooth close (300ms)

---

## Implementation Priorities

### Phase 1: Core Functionality (MVP)
- ✅ Unified model list (local + remote)
- ✅ Automatic routing based on model type
- ✅ Basic queue support
- ✅ Message status indicators

### Phase 2: Enhanced UX
- Connection status banner
- Queue status banner with progress
- Retry actions
- Local model fallback prompt

### Phase 3: Advanced Features
- Queue management UI
- Model download in-app
- Offline behavior settings
- Advanced status details

### Phase 4: Polish
- Animations
- Accessibility audit
- Responsive design refinements
- Performance optimization

---

## Success Metrics

### User Experience
- **Seamlessness**: Users shouldn't notice local vs remote distinction
- **Reliability**: 99%+ message delivery success rate
- **Clarity**: Users always know connection/queue status

### Quantitative Metrics
- Average time from queue to send: < 5 seconds after reconnect
- Queue abandonment rate: < 5%
- Local model adoption: > 30% of users
- Offline usage: Users continue chatting without friction

---

## Design Rationale

### Why Unified Model List?
**Alternatives considered:**
1. Separate tabs for local/remote
2. Settings toggle for mode
3. Automatic with no user choice

**Decision:** Unified list with visual distinctions

**Rationale:**
- Reduces cognitive load
- Users think in terms of "models" not "backends"
- Progressive disclosure (advanced users see type, casual users ignore)
- Easier discovery of local models

### Why Automatic Queue?
**Alternatives considered:**
1. Ask user each time
2. Fail immediately
3. Always queue (even when online)

**Decision:** Automatic queue with clear status

**Rationale:**
- Eliminates interruption
- Expected behavior (like email)
- Status banner provides transparency
- User can cancel/retry if needed

### Why Fallback Prompt?
**Alternatives considered:**
1. Automatic fallback (no prompt)
2. No fallback (just queue)

**Decision:** Prompt user with option

**Rationale:**
- Respects user choice
- They might want to wait for remote model
- Educational (shows local models can work offline)
- One-time prompt (can remember preference)

---

## Related Work

**Similar Patterns in Other Apps:**

1. **Email Apps**: Offline mode with outbox
   - Gmail: Queues messages, shows "Sending" label
   - Outlook: Outbox folder with retry

2. **Messaging Apps**: Queue + status indicators
   - WhatsApp: Clock icon for queued, checkmarks for sent
   - Telegram: Cloud icon for uploading

3. **AI Chat Apps**: Model selection
   - ChatGPT: Simple dropdown, no backend distinction
   - Claude: Sidebar selector with model cards

**What we're doing differently:**
- Unifying local + remote seamlessly
- Intelligent fallback based on availability
- Transparent queueing with full control

---

## Future Enhancements

### Potential Features (Not in Scope)

1. **Smart Model Suggestions**
   - Suggest local model for offline
   - Recommend model based on query type

2. **Queue Prioritization**
   - User can reorder queue
   - Priority levels for messages

3. **Partial Sync**
   - Send summary when offline
   - Full message when online

4. **Background Processing**
   - Process queue in background
   - Show notification when complete

5. **Multi-Device Sync**
   - Sync queue across devices
   - Resume on any device

---

## Conclusion

This design provides a **seamless, intelligent, and user-friendly** experience for chatting with both local and remote models. Key strengths:

1. **Unified Interface**: No mental model split
2. **Automatic Behavior**: Queue and route without asking
3. **Clear Status**: Always visible, never confusing
4. **Graceful Degradation**: Works offline, falls back smartly
5. **User Control**: Can manage queue, retry, cancel

The system should be **invisible when working** and **helpful when failing**.

---

## Appendix: Technical Notes

### Model Type Detection

```dart
class UnifiedModelService {
  static const String localModelPrefix = 'local:';
  
  static bool isLocalModel(String modelId) {
    return modelId.startsWith(localModelPrefix);
  }
  
  static bool isRemoteModel(String modelId) {
    return !isLocalModel(modelId);
  }
}
```

### Routing Logic

```dart
Stream<Conversation> sendMessage(String conversationId, String text) async* {
  final conversation = getConversation(conversationId);
  final modelId = conversation.modelName;
  
  // Route based on model type
  if (UnifiedModelService.isLocalModel(modelId)) {
    yield* _sendMessageOnDevice(conversationId, text);
    return;
  }
  
  // Remote model - check connectivity
  if (!isOnline) {
    // Offer fallback if local model available
    if (await hasLocalModelAvailable()) {
      final useLocal = await _promptLocalFallback();
      if (useLocal) {
        yield* _sendMessageOnDevice(conversationId, text);
        return;
      }
    }
    
    // Queue message
    final queued = await queueMessage(conversationId, text);
    yield queued;
    return;
  }
  
  // Online - use remote
  yield* _sendMessageRemote(conversationId, text);
}
```

### Queue Processing

```dart
Future<void> processMessageQueue() async {
  if (!isOnline) return;
  if (_isProcessingQueue) return;
  
  _isProcessingQueue = true;
  
  try {
    final queue = _queueService.getQueue();
    
    for (var i = 0; i < queue.length; i++) {
      final item = queue[i];
      
      // Update UI with progress
      _updateQueueProgress(i + 1, queue.length);
      
      // Send message
      try {
        await _sendQueuedMessage(item);
        await _queueService.remove(item.id);
      } catch (e) {
        // Mark failed, continue with next
        await _queueService.markFailed(item.id);
      }
    }
  } finally {
    _isProcessingQueue = false;
  }
}
```

---

**End of Document**
