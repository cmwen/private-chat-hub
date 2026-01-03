# UX Design v2: Component & Interaction Specifications

**Document Version:** 1.0  
**Purpose:** Implementation guide for v2 UI components  
**Scope:** Detailed specifications for all new v2 components

---

## 1. Tool Calling Components

### 1.1 ToolBadge Component

**Purpose:** Inline indicator when tool is invoked

**States:**
- Loading: `🔍 Searching...`
- Success: `🔍 Results loaded`
- Error: `🔍 Search failed`

**Properties:**
```dart
- toolName: String (e.g., "Web Search", "Code Search")
- icon: IconData
- status: ToolStatus (loading, success, error)
- duration: Duration? (show elapsed time during loading)
- onTap: Callback? (tap to expand/collapse results)
- onRetry: Callback? (retry if failed)
```

**Visual Style:**
```
┌─ 🔍 Web Search (1.2s)
│  └─ [Expand arrow]
```

---

### 1.2 ToolResultCard Component

**Purpose:** Display tool results (web search, code search, etc.)

**Variations:**
1. **WebSearchResult** - Article snippet with link
2. **CodeSearchResult** - Code snippet with file path
3. **DataSearchResult** - Structured data display
4. **ErrorResult** - Failure message with retry

**Structure:**
```
┌─ ToolResultCard
│  ├─ Header: [Icon] Title [Source badge]
│  ├─ Content: Snippet/preview text
│  ├─ Footer: [Actions]
│  └─ Metadata: Time, relevance score
```

**Properties:**
```dart
- title: String
- description: String
- url: String?
- source: String
- timestamp: DateTime?
- relevanceScore: double?
- actions: List<ToolAction>
- onAction: Callback
```

**Interactions:**
- Tap: Open result (or expand)
- Long-press: Copy, share, save
- Swipe: Quick actions

---

### 1.3 ToolConfigScreen Component

**Purpose:** Settings for tool integration (API keys, usage)

**Sections:**
1. **Enable/Disable Toggle** - On/off control
2. **API Configuration** - Key management (encrypted)
3. **Usage Analytics** - Monthly/daily statistics
4. **Advanced Options** - Search filters, limits
5. **Test Tool** - Try the tool, see results

**Key Elements:**
```dart
TextField(
  label: "API Key",
  obscureText: true,
  helper: "Encrypted locally",
)

ProgressIndicator(
  label: "Monthly quota",
  value: 0.85, // 85/100
)

Button(
  label: "Test Web Search",
  query: "flutter widgets",
  onResult: (results) {...}
)
```

---

## 2. Model Comparison Components

### 2.1 ModelSelectorDialog

**Purpose:** Select 2-4 models for comparison

**Structure:**
```
┌─ Select Models to Compare (v1.0)
│  ├─ Instructions: "Select 2-4 models"
│  ├─ Model checkboxes (scrollable)
│  │  ☑ llama3.2 (4.1GB, Fast)
│  │  ☑ mistral (4.2GB, Balanced)
│  │  ☐ neural-chat (3.8GB, Creative)
│  ├─ Info section: Selected models, memory, tokens
│  └─ Actions: [Cancel] [Start Comparing]
```

**Properties:**
```dart
List<Model> availableModels;
Set<Model> selectedModels;
int minModels = 2;
int maxModels = 4;
```

---

### 2.2 ComparisonChatView (2 Models)

**Layout:** Split screen horizontally

```
┌──────────────────┬──────────────────┐
│   Model 1        │   Model 2        │
│ (50% width)      │ (50% width)      │
├──────────────────┼──────────────────┤
│ Response 1       │ Response 2       │
│                  │                  │
│ [Actions]        │ [Actions]        │
└──────────────────┴──────────────────┘
```

**Components per Column:**
- Model header (name, size, status)
- Response text (scrollable)
- Metrics footer (tokens, time)
- Action buttons (copy, like, regenerate)

**Properties:**
```dart
List<MessagePair> comparisons; // model1Response, model2Response
String userQuery;
ComparisonMetrics metrics;

onCopy(index) → Copy response
onLike(index) → Save preference
onRegenerate(index) → Retry single model
onClose() → Exit comparison
```

---

### 2.3 ComparisonChatView (4 Models - Tabbed)

**Layout:** Tab bar + scrollable content

```
┌─ [Tab1] [Tab2] [Tab3] [Tab4]
│
├─ Model 1 Response
│ [████████░░░░░░] (visible)
│
│ [← Previous] [Next →]
```

**Tab Navigation:**
- Show one model response at a time
- Horizontal swipe to change tabs
- Quick peek at metrics in tab headers

---

### 2.4 ComparisonMetricsPanel

**Purpose:** Show side-by-side statistics

**Metrics Displayed:**
```
Response Time:  Model1: 2.1s  Model2: 1.8s ⚡
Token Count:    Model1: 142   Model2: 156
Quality Score:  Model1: 4.3★  Model2: 4.5★
Clarity Rating: Model1: Good  Model2: Excellent
```

**Visualization:**
- Bar charts for timing
- Badge indicators for quality
- Highlight best performer

---

### 2.5 ResponseDiffView

**Purpose:** Show unique vs common parts

**Structure:**
```
┌─ Compare Responses
├─ Common part (grayed out):
│  "Here's how binary search works..."
├─ Unique to Model2 (highlighted 🟢):
│  "The key insight is..."
├─ Common part (grayed):
│  "This makes it very efficient"
└─ Unique to Model1 (highlighted 🔴):
   "Time complexity: O(log n)"
```

**Interactions:**
- Tap to see full context
- Copy diff as markdown
- Export comparison

---

## 3. Native Integration Components

### 3.1 SharedContentWidget

**Purpose:** Display content shared from another app

**States:**
1. **Text Shared**
   ```
   [Shared from Chrome]
   "Article text here..."
   [Remove]
   ```

2. **Image Shared**
   ```
   [Shared from Gallery]
   [Image preview - 200x200]
   [Remove]
   ```

3. **Link Shared**
   ```
   [Shared from Chrome]
   🔗 "Page Title"
   https://example.com
   [Remove]
   ```

**Properties:**
```dart
enum SharedContentType { text, image, link, file }

class SharedContent {
  final SharedContentType type;
  final String content;
  final String source;
  final DateTime timestamp;
}
```

**Auto-clear:** Remove button or 5s auto-clear after answer

---

### 3.2 ShareMessageDialog

**Purpose:** Send message/conversation to other apps

**Format Selection:**
```
┌─ Share Format
├─ ○ Plain text
├─ ● Markdown (with formatting)
├─ ○ HTML
└─ ○ PDF (future)
```

**Share Targets:**
```
[Gmail] [Messages] [Docs] [Notion] [More...]
```

**Properties:**
```dart
enum ShareFormat { plainText, markdown, html, pdf }

class ShareMessage {
  final String content;
  final ShareFormat format;
  final bool includeMetadata; // author, time, model
  final List<String> recipients;
}
```

---

### 3.3 TTSControls Component

**Purpose:** Play, pause, speed audio output

**Visual Layout:**
```
[▶ Play] [⏸ Pause] [⏹ Stop] [1.0x ▼] [⚙️]
Progress: [██████░░░░░░░░░░░] 40%
Speed: [0.8 --- [●] --- 2.0]x
```

**Properties:**
```dart
class TTSPlayer {
  TTSState state; // playing, paused, stopped
  double progress; // 0.0 to 1.0
  double speed; // 0.8 to 2.0
  bool continueInBackground;
  
  void play()
  void pause()
  void stop()
  void setSpeed(double speed)
  void seekTo(Duration position)
}
```

**Interactions:**
- Tap play to start from current position
- Tap pause to freeze
- Drag progress bar to seek
- Long-press to see transcript

---

### 3.4 TTSSettingsScreen

**Purpose:** Configure text-to-speech behavior

**Options:**
```
Enable TTS for responses         [Toggle: ON]
Voice: [System Default ▼]
Speed: [0.8 --- [●] --- 2.0]
Auto-play on message arrive     [Toggle: OFF]
Continue reading when backgrounded [Toggle: ON]
Voice preview:                   [Test button]
```

**Voice Selection:**
- System default
- Other system voices (if available)
- Future: Download additional voices

---

## 4. Long-Running Task Components

### 4.1 TaskProgressCard

**Purpose:** Show task execution progress

**Structure:**
```
┌─ Task Title
├─ Progress bar: [████████░░░░░░] 60%
├─ Time: 2m 30s elapsed, 1m 40s remaining
├─ Step list:
│  ✓ Step 1 (45s)
│  ✓ Step 2 (38s)
│  ⏳ Step 3 (running 51s)
│  ⊙ Step 4 (pending)
│  ⊙ Step 5 (pending)
└─ Actions: [⏸ Pause] [⏹ Cancel] [📌 Pin]
```

**Properties:**
```dart
class TaskProgress {
  String taskId;
  String title;
  String description;
  int totalSteps;
  int currentStep;
  double progress; // 0.0 to 1.0
  Duration elapsed;
  Duration? estimatedRemaining;
  List<TaskStep> steps;
  TaskStatus status; // running, paused, completed, failed
}

class TaskStep {
  String name;
  StepStatus status; // pending, running, completed, failed
  Duration duration;
  String? errorMessage;
  double? progress;
}
```

---

### 4.2 TaskNotification

**Purpose:** Notification while app backgrounded

**Compact View:**
```
🎯 Research Task
Processing: Step 3/5 (65%)
~1m remaining
[⏸ Pause] [⏹ Cancel] [→]
```

**Expanded View:**
```
🎯 Research Task
"Analyze papers and summarize"
Step 3/5: Read & analyze
Progress: [███████░░░░░] 65%
Elapsed: 2m 30s | Remaining: ~1m 30s
```

**Actions:**
- Tap notification: View full task
- Pause button: Pause execution
- Cancel button: Stop task

---

### 4.3 TaskResultView

**Purpose:** Display completed task results

**Structure:**
```
┌─ Task Title                       [✓ Done]
├─ Completion info:
│  Completed in: 3m 45s
│  All steps: ✓ Completed
├─ Step breakdown:
│  ✓ Step 1 (45s): Found 12 papers
│  ✓ Step 2 (38s): Downloaded 2.3GB
│  ✓ Step 3 (1m 22s): Analyzed 1,245 pages
│  ✓ Step 4 (48s): Generated summary
│  ✓ Step 5 (12s): Verified citations
├─ Result content:
│  Key Findings:
│  • Transformers remain dominant
│  • Multi-modal models advancing fast
│  • Efficiency critical
├─ Actions:
│  [💾 Save] [📤 Share] [🔄 Refine] [➕ New]
```

**Properties:**
```dart
class TaskResult {
  String taskId;
  String title;
  DateTime startTime;
  DateTime endTime;
  List<TaskStep> completedSteps;
  String resultContent;
  ResultFormat format; // text, markdown, html
  List<Attachment>? artifacts;
  bool success;
  String? errorMessage;
}
```

---

### 4.4 RunningTasksDashboard

**Purpose:** View all active and recent tasks

**Sections:**
1. **Active Tasks**
   ```
   1️⃣ Research AI Papers (65%)
      Step 3/5 | 1m 10s remaining
      [Tap to view]
   ```

2. **Completed Today**
   ```
   ✓ Document Summary
      Completed 2h ago
      [View result] [Share]
   ```

3. **Past 7 Days**
   ```
   ✓ Code Generation Sprint
      Completed 3d ago
   ```

**Features:**
- Search tasks
- Filter by status
- Sort by date/type
- Bulk actions (archive, delete)

---

### 4.5 ThinkingModelDisplay

**Purpose:** Show reasoning process for extended thinking models

**Collapsed State:**
```
🤖 llama3.2-thinking
[🔄 Show thinking process]
Response tokens: 320 | Thinking tokens: 2,450
```

**Expanded State:**
```
🤖 llama3.2-thinking

Thinking Process:
"First, let me understand this problem..."
"The key insight is..."
"Therefore, the approach should be..."
[⊗ Collapse]

Final Answer:
"To solve this problem, you need to..."
```

**Properties:**
```dart
class ThinkingModel {
  String modelName;
  String thinkingContent;
  String responseContent;
  int thinkingTokens;
  int responseTokens;
  double readingFeeMultiplier; // e.g., 1.5x
  
  void toggleThinking()
  void copyThinking()
  void exportThinkingProcess()
}
```

---

## 5. MCP Integration Components

### 5.1 MCPServerCard

**Purpose:** Display connected MCP server status

**Connected Server:**
```
🔌 Code Tools (Local)
Status: 🟢 Connected
Tools available: 12
Last sync: 2m ago

[View Tools] [Settings] [Disconnect]
```

**Disconnected Server:**
```
🔌 Research Assistant
Status: 🔴 Disconnected
Tools available: 8
Last sync: 45m ago

[Reconnect] [Settings] [Remove]
```

**Properties:**
```dart
class MCPServer {
  String name;
  String host;
  int port;
  MCPStatus status; // connected, disconnected, error
  List<MCPTool> tools;
  DateTime lastSync;
  String? errorMessage;
}
```

---

### 5.2 MCPToolLibrary

**Purpose:** Browse and configure tools from all servers

**Display:**
```
MCP Tools (20 total)
[Search...]

Code Tools (12)
☑ Git Status
   Get current repository status
   
☑ Search Codebase
   Find code by pattern
   
⚠️ Execute Script
   Run shell scripts (requires confirmation)
   [Edit permissions]

Research Tools (8)
☑ Find Paper
   Search arXiv and databases
```

**Interactions:**
- Toggle auto-allow per tool
- Configure permissions (confirm, deny, whitelist)
- Search tools
- View tool details (description, parameters)

**Properties:**
```dart
enum ToolPermission { autoAllow, requireConfirm, deny }

class MCPTool {
  String name;
  String description;
  String serverName;
  List<Parameter> parameters;
  ToolPermission permission;
  int usageCount;
  DateTime? lastUsed;
}
```

---

### 5.3 MCPToolUsageInChat

**Purpose:** Show when MCP tool is invoked during chat

**Inline Display:**
```
Let me search for that function...

🔌 Code Tools: Using "Search Codebase"
   Searching for: "binary_search"
   Found 3 matches (0.8s)

Results:
┌─ src/algorithms/search.py (Line 42)
│  def binary_search(arr, target):
│  [View] [Copy] [Share]
│
└─ tests/test_search.py (Line 156)

Based on the code, the function...
```

**Components:**
- Tool invocation indicator
- Parameters used (highlighted)
- Results display
- Model response incorporating results

---

## 6. Updated Navigation Components

### 6.1 NavigationDrawerItems (v2)

**New Items:**
```
🎯 Running Tasks [Badge: 3]
   (Only shows if active tasks exist)
   
🔌 MCP Servers
   (Links to MCP configuration)
```

**Updated Settings:**
```
⚙️ Settings
├─ Connection
├─ Tools & Features
│  ├─ Web Search
│  ├─ MCP Servers
├─ Text-to-Speech
├─ Appearance
└─ About
```

---

### 6.2 ChatScreenAppBar (v2)

**Single Model:**
```
🤖 llama3.2 (4.1GB)
Local • Connected ✓
```

**Comparison Mode:**
```
⚖️ Comparing 2 Models
llama3.2 vs mistral
```

**With Tools Available:**
```
🤖 llama3.2 (4.1GB)
Local • Connected ✓ | 🔍 Tools ready
```

---

## 7. Error Handling Components

### 7.1 ToolErrorState

```
🔍 Web search failed
❌ "Connection timeout (30s)"

[↻ Retry]  [Continue without]  [Settings]
```

### 7.2 TaskErrorState

```
🎯 Task paused
⚠️ Step 3 failed: "API rate limit"

[▶ Resume]  [Skip step]  [Cancel]  [Logs]
```

### 7.3 MCPErrorState

```
🔌 Code Tools disconnected
❌ "Connection refused (localhost:3000)"

[↻ Reconnect]  [Settings]  [Remove]
```

---

## 8. Animation & Transitions

### 8.1 Tool Result Animation

```
Tool invoked
    ↓
[Loading spinner starts]
    ↓
Result arrives
    ↓
[Slide in from bottom with fade]
    ↓
[Stay visible, content scrollable]
```

### 8.2 Task Progress Animation

```
Step starts
    ↓
[Progress bar extends smoothly]
    ↓
[Step completes]
    ↓
[Checkmark fade-in]
    ↓
[Move to next step]
```

### 8.3 Model Response Animation

**Single Model:**
Fade in + slide from left (existing)

**Comparison Mode:**
```
Model 1 response arrives
    ↓
[Slide from left]
    ↓
[Both visible]
    ↓
Model 2 response arrives
    ↓
[Slide from right]
```

---

## 9. Haptic Feedback Map

| Event | Pattern | Intensity |
|-------|---------|-----------|
| Tool invoked | Light tap | Subtle |
| Tool result received | Medium tap | Medium |
| Task step completed | Success pattern | Medium |
| Task failed | Error pattern | Strong |
| Tool error | Warning pattern | Strong |
| Model comparison started | Double tap | Medium |
| Response ready | Success tone | Medium |

---

## 10. Accessibility Specs

### Color Contrast
- Text on background: ≥ 4.5:1 (WCAG AA)
- UI controls: ≥ 3:1 (WCAG AA)
- Tool error: Red + ❌ icon (not color alone)
- Tool success: Green + ✓ icon (not color alone)

### Touch Targets
- All buttons: ≥ 48dp × 48dp
- Tool result links: ≥ 44dp tall
- Comparison model headers: ≥ 48dp tall
- Task progress card actions: ≥ 48dp × 48dp

### Screen Reader
- Tool badges: "Web search in progress, 1.2 seconds"
- Task progress: "Task: Research AI Papers, 65% complete, 1 minute remaining"
- Tool results: "Web search result: Title, from source.com, tap to open"
- Thinking model: "Thinking model expansion button, 2450 thinking tokens"

---

## 11. Component Library Summary

| Component | File | States | v2 Phase |
|-----------|------|--------|----------|
| ToolBadge | widgets/tool_badge.dart | loading, success, error | Phase 1 |
| ToolResultCard | widgets/tool_result_card.dart | 4 types | Phase 1 |
| ToolConfigScreen | screens/settings/tool_config_screen.dart | 1 | Phase 1 |
| ModelSelectorDialog | dialogs/model_selector_dialog.dart | 1 | Phase 2 |
| ComparisonChatView | screens/comparison_chat_screen.dart | 2, 4 model modes | Phase 2 |
| SharedContentWidget | widgets/shared_content_widget.dart | 4 types | Phase 3 |
| ShareMessageDialog | dialogs/share_message_dialog.dart | 3 formats | Phase 3 |
| TTSControls | widgets/tts_controls.dart | playing, paused, stopped | Phase 3 |
| TTSSettingsScreen | screens/settings/tts_settings_screen.dart | 1 | Phase 3 |
| TaskProgressCard | widgets/task_progress_card.dart | running, paused, error | Phase 4 |
| TaskResultView | screens/task_result_screen.dart | success, error | Phase 4 |
| RunningTasksDashboard | screens/running_tasks_screen.dart | 1 | Phase 4 |
| ThinkingModelDisplay | widgets/thinking_model_display.dart | collapsed, expanded | Phase 4 |
| MCPServerCard | widgets/mcp_server_card.dart | connected, disconnected | Phase 5 |
| MCPToolLibrary | screens/mcp_tool_library_screen.dart | 1 | Phase 5 |

---

## 12. Implementation Priority

**Phase 1 (Weeks 1-8):**
1. ToolBadge
2. ToolResultCard
3. ToolConfigScreen
4. Web search integration

**Phase 2 (Weeks 9-16):**
1. ModelSelectorDialog
2. ComparisonChatView (2 & 4 model)
3. Update ChatScreen for comparison

**Phase 3 (Weeks 17-24):**
1. SharedContentWidget
2. ShareMessageDialog
3. TTSControls
4. TTSSettingsScreen
5. Android intent receivers

**Phase 4 (Weeks 25-34):**
1. TaskProgressCard
2. TaskNotification
3. TaskResultView
4. RunningTasksDashboard
5. ThinkingModelDisplay

**Phase 5 (Weeks 35-42):**
1. MCPServerCard
2. MCPToolLibrary
3. MCP chat integration

---

This document provides developers with complete specifications needed to implement all v2 components.

