# UX Design Decisions: Private Chat Hub

**Document Version:** 1.0  
**Created:** December 31, 2025  
**Purpose:** Document the rationale behind UX design choices  
**Audience:** Developers, designers, stakeholders

---

## Table of Contents

1. [Design Philosophy Decisions](#1-design-philosophy-decisions)
2. [Navigation & Structure Decisions](#2-navigation--structure-decisions)
3. [Chat Experience Decisions](#3-chat-experience-decisions)
4. [Model Management Decisions](#4-model-management-decisions)
5. [Onboarding Decisions](#5-onboarding-decisions)
6. [Error Handling Decisions](#6-error-handling-decisions)
7. [Accessibility Decisions](#7-accessibility-decisions)
8. [Visual Design Decisions](#8-visual-design-decisions)
9. [Trade-offs & Alternatives Considered](#9-trade-offs--alternatives-considered)

---

## 1. Design Philosophy Decisions

### Decision 1.1: "Familiar Yet Powerful" Approach

**Decision:** Mirror ChatGPT/Claude UX patterns while adding local-first features.

**Rationale:**
- Users already have mental models from existing AI chat apps
- Reduces learning curve for new users (personas: Alex, Sam)
- Power features (model switching, local storage) are progressive enhancements

**Alternatives Considered:**
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Novel UI design | Unique branding | Learning curve, confusion | ❌ Rejected |
| Clone ChatGPT exactly | Zero learning curve | No differentiation, legal risk | ❌ Rejected |
| **Familiar + local features** | Best of both worlds | Slightly more complex | ✅ Chosen |

**Impact on User Flows:**
- Chat screen layout matches ChatGPT (messages, input at bottom)
- Added: model chip in app bar, connection indicator, local storage cues

---

### Decision 1.2: Privacy-First Visual Language

**Decision:** Use visual cues to reinforce data stays local throughout the app.

**Rationale:**
- Target persona Alex (Privacy Advocate) needs constant reassurance
- Differentiates from cloud-based competitors
- Builds trust with privacy-conscious users

**Implementation:**
- Lock icon (🔒) in logo and branding
- "Local" badge on connection status
- No cloud sync icons or terminology
- Explicit messaging: "Your data never leaves this device"

**Affected Screens:** Welcome, Connection Setup, Settings, About

---

### Decision 1.3: Dark Mode First

**Decision:** Design for dark mode as the primary theme, with light mode as secondary.

**Rationale:**
- Privacy-conscious users often prefer dark themes
- Reduces eye strain during extended AI conversations
- Better for late-night coding/research sessions (personas: Maya, Jordan)
- OLED battery savings on Android devices

**Implementation:**
- Design all wireframes in dark mode first
- Use Material 3 dark color tokens as baseline
- Light mode is a simple inversion, not a redesign

---

## 2. Navigation & Structure Decisions

### Decision 2.1: Drawer Navigation (Not Bottom Tabs)

**Decision:** Use a navigation drawer for conversations, not bottom tab navigation.

**Rationale:**
| Criteria | Drawer | Bottom Tabs |
|----------|--------|-------------|
| Conversation list | ✅ Fits naturally | ❌ Awkward fit |
| Chat focus | ✅ Full screen for chat | ❌ Tab bar takes space |
| Similar apps pattern | ✅ ChatGPT uses drawer | - |
| Gesture compatibility | ✅ Swipe from edge | ✅ Tap tabs |
| Model switching | ✅ Use app bar chip | ❌ Would need tab |

**User Flow Impact:**
```
With Drawer:                    With Bottom Tabs:
┌──────────────┐               ┌──────────────┐
│ ☰  Chat  🤖 │               │    Chat      │
│              │               │              │
│   Messages   │               │   Messages   │
│              │               │              │
│   [Input]    │               │   [Input]    │
│              │               ├──────────────┤
│              │               │ 💬  🤖  ⚙️  │
└──────────────┘               └──────────────┘
    ✅ More chat space              ❌ Less space
```

---

### Decision 2.2: Model Selector in App Bar

**Decision:** Place the current model as a tappable chip in the app bar.

**Rationale:**
- Model selection is a frequent action (Jordan switches 5+ times/day)
- One tap to open selector, one tap to switch = 2-tap workflow
- Always visible, reinforcing which model is active
- Matches pattern from professional tools (VS Code, IDE toolbars)

**Alternatives Rejected:**
- Separate Models tab: Too hidden for frequent action
- Floating button: Obscures chat content
- Settings page: Too many taps (4+)

---

### Decision 2.3: Flat Information Architecture

**Decision:** Maximum 3 levels deep for any navigation path.

**Rationale:**
- Deep hierarchies cause user disorientation
- Most actions should be 2-3 taps from home
- Supports quick task completion

**Hierarchy Mapping:**
```
Level 1: Chat Screen (home)
Level 2: Drawer, Model Selector, Settings
Level 3: Model Details, Connection Setup, Export Options
```

---

## 3. Chat Experience Decisions

### Decision 3.1: Streaming Text Display

**Decision:** Show AI responses as they stream, character by character.

**Rationale:**
- Matches user expectations from ChatGPT/Claude
- Provides immediate feedback (system is working)
- Allows user to start reading before completion
- Can stop generation if going off-track

**Technical Implementation:**
- Use Dio streaming response
- Render with flutter_markdown
- Show cursor/typing indicator while streaming
- "Stop" button appears during generation

---

### Decision 3.2: Message Bubbles with Distinct Styling

**Decision:** User messages right-aligned (filled), AI messages left-aligned (outlined).

**Rationale:**
- Standard chat UX pattern (SMS, WhatsApp, ChatGPT)
- Instant visual distinction between speakers
- Supports quick scanning of long conversations

**Visual Specification:**
```
┌─────────────────────────────────────────┐
│                                         │
│                    ┌─────────────────┐  │
│                    │  User message   │  │  ← Filled, primary color
│                    └─────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  AI response with markdown      │    │  ← Outlined, surface color
│  │  support and code blocks        │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

---

### Decision 3.3: Long-Press Context Menu (Not Swipe)

**Decision:** Use long-press for message actions, not swipe gestures.

**Rationale:**
| Gesture | Pros | Cons | Decision |
|---------|------|------|----------|
| Long-press | Standard Android, discoverable | Slight delay | ✅ Chosen |
| Swipe | Quick | Conflicts with drawer swipe, accidental triggers | ❌ Rejected |
| Visible buttons | No gesture learning | Clutters UI | ❌ Rejected |

**Context Menu Actions:**
- Copy (text to clipboard)
- Share (Android share sheet)
- Regenerate (AI messages only)
- Delete

---

### Decision 3.4: Attachment Preview Before Send

**Decision:** Show attachment preview in input area, removable before sending.

**Rationale:**
- Prevents accidental sends with wrong attachment
- User can add/remove multiple items
- Shows thumbnail for images, icon for files
- "X" button to remove each attachment

**User Flow:**
```
Tap 📎 → Pick file → Preview appears → Add text (optional) → Send
                          ↓
                    [🖼️ image.jpg ✕]  [Type message...]  [➤]
```

---

### Decision 3.5: Vision Model Auto-Detect

**Decision:** Warn user if attaching image to non-vision model, offer to switch.

**Rationale:**
- Prevents frustrating error after sending
- Educates users about model capabilities
- Smooth path to vision features (llava, etc.)

**Dialog Flow:**
```
User attaches image with llama3.2 selected
                    ↓
┌─────────────────────────────────────┐
│  Image Attachment                   │
│                                     │
│  llama3.2 doesn't support images.  │
│  Switch to a vision model?          │
│                                     │
│  [Cancel]  [Switch to llava]        │
└─────────────────────────────────────┘
```

---

## 4. Model Management Decisions

### Decision 4.1: Two-Tab Model Screen (Downloaded / Available)

**Decision:** Separate downloaded models from available-to-download models.

**Rationale:**
- Clear mental model: "what I have" vs "what I can get"
- Downloaded models load instantly (already local)
- Available models require network + download time
- Reduces accidental download clicks

**Tab Design:**
```
┌────────────────────────────────────┐
│  ┌──────────┐ ┌──────────┐        │
│  │Downloaded│ │Available │        │
│  │   (3)    │ │   (50+)  │        │
│  └──────────┘ └──────────┘        │
├────────────────────────────────────┤
│  Local models shown here          │
└────────────────────────────────────┘
```

---

### Decision 4.2: Curated Model Recommendations

**Decision:** Show recommended models prominently, with device-appropriate suggestions.

**Rationale:**
- Ollama has 100+ models; overwhelming for new users (Sam)
- Curated list guides beginners to working configurations
- Hardware-appropriate suggestions prevent OOM crashes
- Still allow advanced users to search/browse all

**Recommendation Categories:**
| Category | Example Models | Criteria |
|----------|----------------|----------|
| Best for Chat | llama3.2, mistral | General purpose, good quality |
| Best for Code | codellama, deepseek-coder | Code-optimized |
| Vision Models | llava, bakllava | Support image input |
| Lightweight | phi, tinyllama | < 2GB, mobile-friendly |
| Power Users | mixtral, llama2:70b | High VRAM needed |

---

### Decision 4.3: Download Progress with Background Support

**Decision:** Show download progress with option to continue in background.

**Rationale:**
- Large models (7B+) take 5-30 minutes to download
- User shouldn't be blocked from using app
- Notification shows progress when app minimized
- Multiple downloads can queue

**UI States:**
```
Downloading:                    Backgrounded:
┌─────────────────────┐        ┌─────────────────────┐
│ llama3.2 (3.2GB)    │        │ 📥 Downloading      │
│ ████████░░ 78%      │   →    │    llama3.2 78%     │
│ 2.5GB / 3.2GB       │        │                     │
│ 12.5 MB/s • 45s     │        │ (Notification bar)  │
│ [Cancel]            │        └─────────────────────┘
└─────────────────────┘
```

---

### Decision 4.4: Model Size Warnings

**Decision:** Warn before downloading models larger than 4GB.

**Rationale:**
- Large downloads consume mobile data if not on WiFi
- May exceed device storage
- Very large models may not run on device
- Prevents accidental multi-GB downloads

**Warning Dialog:**
```
┌─────────────────────────────────────┐
│  ⚠️ Large Download                  │
│                                     │
│  llama2:13b is 7.4 GB.              │
│                                     │
│  • Check you're on WiFi             │
│  • Needs 8GB+ RAM to run            │
│  • Will use significant storage     │
│                                     │
│  [Cancel]  [Download Anyway]        │
└─────────────────────────────────────┘
```

---

## 5. Onboarding Decisions

### Decision 5.1: Minimal Onboarding (3 Screens Max)

**Decision:** Onboarding is: Welcome → Setup Connection → Success.

**Rationale:**
- Users want to start chatting, not read tutorials
- Connection setup is the only required step
- Advanced features discoverable through use
- Can add optional tutorial later

**Rejected:** Multi-screen feature tours, permission requests upfront, account creation

---

### Decision 5.2: Connection Test Before Proceeding

**Decision:** Require successful connection test before completing setup.

**Rationale:**
- Prevents users entering main app with broken connection
- Immediate feedback on configuration errors
- Guides troubleshooting if needed
- Success screen can show discovered models

---

### Decision 5.3: Auto-Discovery Option

**Decision:** Offer optional auto-discovery of Ollama servers on local network.

**Rationale:**
- Reduces manual configuration for home users
- mDNS/Bonjour can find Ollama services
- Still allow manual entry for advanced setups
- Non-blocking if discovery fails

**Limitations:** Only works on same network, may require permissions

---

## 6. Error Handling Decisions

### Decision 6.1: Connection Status Always Visible

**Decision:** Show connection status indicator in app bar at all times.

**Rationale:**
- Users need to know if they're connected before sending
- Prevents confusion when messages fail
- Quick visual check without navigating

**Status Indicators:**
```
🟢 Connected (green dot)    - Ollama responding
🟡 Connecting (yellow pulse) - Testing connection
🔴 Disconnected (red dot)   - Cannot reach server
```

---

### Decision 6.2: Inline Error Messages (Not Blocking Dialogs)

**Decision:** Show errors inline where they occur, not as modal dialogs.

**Rationale:**
- Dialogs interrupt flow and require dismissal
- Inline errors are contextual and actionable
- User can continue with other actions
- Less intrusive for minor issues

**Examples:**
```
Message send failed:
┌─────────────────────────────────────┐
│  │ User message that failed   │ ⚠️ │
│  │                            │    │
│  │               [Retry] [Delete]  │
└─────────────────────────────────────┘

Connection lost (banner):
┌─────────────────────────────────────┐
│ ⚠️ Connection lost. Retry in 5s... │  ← Dismissible banner
├─────────────────────────────────────┤
│  │ Chat continues below (read-only) │
```

---

### Decision 6.3: Graceful Degradation for Offline Mode

**Decision:** Allow viewing chat history when offline, queue sends for retry.

**Rationale:**
- Don't block app entirely when connection drops
- Users can review past conversations
- Queued messages send automatically when reconnected
- Clear indication of what's pending

---

## 7. Accessibility Decisions

### Decision 7.1: Minimum Touch Targets 48dp

**Decision:** All interactive elements are at least 48x48dp.

**Rationale:**
- Android accessibility guidelines requirement
- Supports users with motor impairments
- Works better with device cases that reduce accuracy
- Consistent with Material Design specifications

---

### Decision 7.2: Screen Reader Support (TalkBack)

**Decision:** Full TalkBack compatibility with semantic labels.

**Rationale:**
- Legal accessibility requirements
- Persona Chris (Enterprise) may have accessibility needs
- Good practice for all users

**Implementation:**
```dart
Semantics(
  label: 'Send message button',
  button: true,
  child: IconButton(...),
)
```

---

### Decision 7.3: Respect System Font Scaling

**Decision:** Support Android system font size preferences (0.85x to 1.3x).

**Rationale:**
- Users with vision impairments set larger fonts
- System preference should be respected
- Test all layouts at maximum font scale

---

## 8. Visual Design Decisions

### Decision 8.1: Material Design 3 (Material You)

**Decision:** Use Material Design 3 with dynamic color support.

**Rationale:**
- Modern Android design language (Android 12+)
- Dynamic color adapts to user's wallpaper
- Consistent with other Android apps
- Well-documented component library

---

### Decision 8.2: Limited Color Palette

**Decision:** Primary + Surface + Error only, no decorative colors.

**Rationale:**
- Clean, professional appearance
- Reduces visual noise during long reading sessions
- Color reserved for semantic meaning (errors, success, status)
- Works well in dark mode

**Color Usage:**
| Color | Usage |
|-------|-------|
| Primary | Buttons, active states, user messages |
| Surface | Backgrounds, cards, AI messages |
| Error | Errors, warnings, destructive actions |
| Green | Success, connected status |
| Yellow | Pending, warning states |

---

### Decision 8.3: Code Block Styling

**Decision:** Syntax-highlighted code blocks with copy button.

**Rationale:**
- AI often generates code (Maya, Jordan)
- Syntax highlighting improves readability
- One-tap copy for code reuse
- Horizontal scroll for long lines

**Design:**
```
┌─────────────────────────────────────────┐
│ python                            📋   │  ← Language label + copy
├─────────────────────────────────────────┤
│ def hello():                            │
│     print("Hello, World!")              │
│                                         │
└─────────────────────────────────────────┘
```

---

## 9. Trade-offs & Alternatives Considered

### Trade-off 9.1: Simplicity vs Power

**Tension:** Beginners want simple UI; power users want advanced features.

**Resolution:** Progressive disclosure
- Default UI is simple (Chat, Model picker)
- Advanced features in Settings or long-press menus
- Model parameters hidden by default, expandable

---

### Trade-off 9.2: Immediate Feedback vs Performance

**Tension:** Streaming text is resource-intensive.

**Resolution:** Optimize rendering
- Debounce UI updates during fast streaming
- Use efficient markdown parser
- Virtualized list for long conversations
- Option to reduce animation

---

### Trade-off 9.3: Offline Support vs Complexity

**Tension:** Full offline mode adds complexity.

**Resolution:** Partial offline support
- Read-only access to history when offline
- Queue new messages for later send
- Clear UI indication of offline state
- No attempt to cache models (too large)

---

### Alternative Rejected: Voice Input on MVP

**Reason:** Adds complexity to v1, better as Phase 4 feature
- Requires audio permissions
- Speech-to-text adds dependencies
- Core chat experience should be solid first
- Documented for future roadmap

---

### Alternative Rejected: Multiple Chat Windows

**Reason:** Complexity vs mobile UX
- Tabs/windows work on desktop, not mobile
- Drawer navigation covers use case
- Focus on one conversation at a time
- Power users can open multiple app instances

---

## Design Decision Log

| ID | Decision | Date | Status |
|----|----------|------|--------|
| 1.1 | Familiar + local features approach | 2025-12-31 | ✅ Approved |
| 1.2 | Privacy-first visual language | 2025-12-31 | ✅ Approved |
| 1.3 | Dark mode first | 2025-12-31 | ✅ Approved |
| 2.1 | Drawer navigation | 2025-12-31 | ✅ Approved |
| 2.2 | Model selector in app bar | 2025-12-31 | ✅ Approved |
| 2.3 | 3-level max navigation | 2025-12-31 | ✅ Approved |
| 3.1 | Streaming text display | 2025-12-31 | ✅ Approved |
| 3.2 | Distinct message bubbles | 2025-12-31 | ✅ Approved |
| 3.3 | Long-press context menu | 2025-12-31 | ✅ Approved |
| 3.4 | Attachment preview | 2025-12-31 | ✅ Approved |
| 3.5 | Vision model auto-detect | 2025-12-31 | ✅ Approved |
| 4.1 | Two-tab model screen | 2025-12-31 | ✅ Approved |
| 4.2 | Curated recommendations | 2025-12-31 | ✅ Approved |
| 4.3 | Background download | 2025-12-31 | ✅ Approved |
| 4.4 | Model size warnings | 2025-12-31 | ✅ Approved |
| 5.1 | Minimal onboarding | 2025-12-31 | ✅ Approved |
| 5.2 | Connection test required | 2025-12-31 | ✅ Approved |
| 5.3 | Auto-discovery option | 2025-12-31 | ✅ Approved |
| 6.1 | Visible connection status | 2025-12-31 | ✅ Approved |
| 6.2 | Inline error messages | 2025-12-31 | ✅ Approved |
| 6.3 | Graceful offline degradation | 2025-12-31 | ✅ Approved |
| 7.1 | 48dp touch targets | 2025-12-31 | ✅ Approved |
| 7.2 | TalkBack support | 2025-12-31 | ✅ Approved |
| 7.3 | System font scaling | 2025-12-31 | ✅ Approved |
| 8.1 | Material Design 3 | 2025-12-31 | ✅ Approved |
| 8.2 | Limited color palette | 2025-12-31 | ✅ Approved |
| 8.3 | Code block styling | 2025-12-31 | ✅ Approved |

---

## Related Documents

- [UX_DESIGN.md](UX_DESIGN.md) - Complete wireframes and specifications
- [USER_FLOWS.md](USER_FLOWS.md) - Visual user flow diagrams
- [USER_PERSONAS.md](USER_PERSONAS.md) - Target user definitions
- [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) - Functional requirements
- [TECHNICAL_FEASIBILITY.md](TECHNICAL_FEASIBILITY.md) - Technical validation

---

*This document should be updated when design decisions are revisited or new decisions are made during development.*
