# UX Design v2: Key User Flows

**Document Version:** 1.0  
**Purpose:** Map critical user journeys for v2 features  
**Scope:** End-to-end flows for each phase

---

## Phase 1: Tool Calling Flows

### Flow 1.1: User Asks Question That Requires Web Search

```
User → "What's the latest news about AI?"
         ↓
Model detects question needs current info
         ↓
AI decides to use Web Search tool
         ↓
UI shows: 🔍 "Searching web..." (spinner, 0.0-3.0s)
         ↓
Web search API called (async)
         ↓
Results arrive as stream
         ↓
UI shows: 🔍 Web Search Results
         - Result 1: Title + snippet + link
         - Result 2: Title + snippet + link
         - Result 3: Title + snippet + link
         [See 3 more results] (collapsed)
         ↓
Model incorporates results into response
         ↓
UI shows: Model's answer based on search results
         ↓
User can:
- Read full response
- View search results (collapse/expand)
- Open result links
- Copy response
- Regenerate without search
```

**Time: 3-5s total (search + model response)**

---

### Flow 1.2: Web Search Configuration

```
User → Settings → Tools & Features
         ↓
Sees: Web Search toggle [ON]
      Status: Connected ✓
      Monthly quota: 85/100
      [Configure] [Test Search]
         ↓
Tap [Configure]
         ↓
Dialog shows:
- API Key field (encrypted)
- Search region/language
- Result limit (10/25/50)
- Safe search toggle
         ↓
User updates settings
         ↓
Tap [Save]
         ↓
Settings saved locally
Connection verified ✓
         ↓
Return to chat
         ↓
Web search ready to use
```

**Time: 2-3 min (one-time setup)**

---

### Flow 1.3: Tool Error Recovery

```
User → Asks question requiring web search
         ↓
🔍 "Searching web..." (starts)
         ↓
[After 30s] Connection timeout
         ↓
UI shows error:
❌ "Web search failed: Connection timeout"
         ↓
User sees options:
[↻ Retry search]
[Continue without search]
[Go to settings]
         ↓
Path A: User taps [↻ Retry]
         ↓
Search attempts again
         ↓
[Success] → Show results
[Failure again] → Show error + fallback options
         ↓
Path B: User taps [Continue without search]
         ↓
Model generates response without web search
         ↓
"Based on my training data..."
         ↓
Path C: User taps [Go to settings]
         ↓
Opens tool configuration
         ↓
User checks API key, updates if needed
         ↓
Returns to chat, tries again
```

**Error recovery time: 30-60s total**

---

## Phase 2: Model Comparison Flows

### Flow 2.1: Start Comparison Mode

```
User → Chat screen with single model (llama3.2)
         ↓
Tap model selector dropdown
         ↓
Menu shows:
[✓] Single Model
[  ] Compare Models → [Start Comparison]
         ↓
Tap "Start Comparison"
         ↓
Modal dialog appears:
"Select 2-4 Models to Compare"
☑ llama3.2 (4.1GB, Fast)
☑ mistral (4.2GB, Balanced)
☐ neural-chat (3.8GB, Creative)
☐ qwen2.5 (6.2GB, Detail)
         ↓
User selects 2-4 models (default: select first 2)
         ↓
Tap [Start Comparing]
         ↓
UI transforms to side-by-side comparison view
         ↓
Chat history cleared
Next message will go to all selected models
         ↓
User types message
         ↓
"Explain binary search"
         ↓
Tap [Send]
```

**Setup time: 10-15 seconds**

---

### Flow 2.2: Compare Two Models

```
User → Side-by-side comparison mode (2 models)
         ↓
User types: "Explain binary search"
         ↓
Press Send
         ↓
Messages sent to both models simultaneously
         ↓
UI shows:
llama3.2    |    mistral
Loading...  |    Loading...
⏳ 1.2s     |    ⏳ 0.9s
         ↓
Model responses stream in
         ↓
llama3.2 responds first (at 2.1s)
Response appears in left column
         ↓
[████████░░░░░░░░░░] Progress shown
         ↓
mistral responds (at 1.9s total)
Response appears in right column
         ↓
Both columns show full responses
         ↓
User can:
- Read both responses side-by-side
- Scroll independently
- Tap [😊 Good] to rate
- Long-press to copy, share, etc.
- Swipe left to see metrics (time, tokens)
- Tap [See diff] to highlight unique parts
         ↓
User sends another message
         ↓
Both models respond again
```

**Response time: 2-3 seconds (parallelized)**

---

### Flow 2.3: Compare Four Models (Tabbed)

```
User → Selects 4 models for comparison
         ↓
UI shows: Tabbed view
[llama3.2] [mistral] [neural] [qwen2.5]
         ↓
User types: "Explain binary search"
         ↓
Send message
         ↓
All 4 models receive message simultaneously
         ↓
UI shows loading state:
llama3.2 ⏳ 1.2s
mistral  ⏳ 0.9s
neural   ⏳ 1.5s
qwen2.5  ⏳ 1.3s
         ↓
Responses stream in (in any order)
         ↓
Tab shows: "llama3.2 (2.1s)" [Completed]
         ↓
User taps tab to see response
         ↓
Can switch between tabs to compare
         ↓
Swipe horizontally to move between tabs
         ↓
Metrics shown: Time, tokens, quality score
         ↓
User can:
- View each response independently
- Quick-switch tabs
- See performance metrics
- Copy/share individual responses
```

**Response time: 3-4 seconds (longest model)**

---

### Flow 2.4: Response Diff View

```
User → In comparison mode with responses
         ↓
Tap [See Diff] on responses
         ↓
Diff view appears showing:
         ↓
[Common text in gray]
"Here's how binary search works..."
         ↓
[Unique to mistral in green 🟢]
"The key insight is that..."
         ↓
[Common text in gray]
"This algorithm is efficient"
         ↓
[Unique to llama3.2 in red 🔴]
"Time complexity: O(log n)"
         ↓
User can:
- Scroll through highlighting
- Tap to expand context
- Copy just the diff
- Export as markdown
- Share comparison
         ↓
Tap [Back] to see full responses again
```

**Diff generation time: <500ms**

---

## Phase 3: Native Integration Flows

### Flow 3.1: Receive Share From Another App

```
User → In Chrome browser, finds article
         ↓
Reads article, wants AI analysis
         ↓
Long-press article → Share menu
         ↓
Sees: Private Chat Hub icon in share sheet
         ↓
Taps: Private Chat Hub
         ↓
App opens/resumes
         ↓
Chat screen shows:
[Shared from Chrome - Article Text]
┌─────────────────────────────────┐
│ "Researchers Announce..."       │
│ [Remove]                        │
└─────────────────────────────────┘

Message input pre-populated:
"[Article text here]"
         ↓
User can:
- Edit the shared text
- Add their own question
- Clear shared content
- Send to model
         ↓
User types additional prompt:
"Summarize this and highlight key points"
         ↓
Send
         ↓
Model processes both context + prompt
         ↓
Response: "Summary: ... Key points: ..."
```

**Time: <2 seconds to receive + show**

---

### Flow 3.2: Send Message to Another App

```
User → Has AI response in chat
         ↓
Long-press response message
         ↓
Context menu appears:
[Copy] [Share] [Regenerate] [More]
         ↓
Tap [Share]
         ↓
Share dialog shows:

Format:
○ Plain text
● Markdown (with formatting)
○ HTML

Preview:
"User: Explain binary search"
"AI: Binary search is..."

[Share to...]
[Gmail] [Messages] [Docs] [Notion] [More]
         ↓
User taps [Gmail]
         ↓
Gmail opens with message in compose
```

**Time: 10-20 seconds (open share → Gmail)**

---

### Flow 3.3: Text-to-Speech Response

```
User → AI gives response
         ↓
Response shows with TTS button:
[▶ Listen] [⏸ Pause] [1.0x▼] [⚙️]
         ↓
Tap [▶ Listen]
         ↓
Audio starts (if already cached) or generates
Possible states:
- <500ms: Already generated, plays immediately
- 1-3s: Generate TTS audio, then play
         ↓
Response highlights current text being read
         ↓
Progress bar shows: [████░░░░░░░░░░░░░░] 20%
         ↓
User can:
- Swipe progress bar to seek
- Tap [⏸ Pause] to pause
- Change speed with [1.0x▼]
- Continue in background (app backgrounded)
- Return to app, resume from where paused
         ↓
TTS ends
         ↓
Button returns to [▶ Listen] (restart)
```

**Time: <5 seconds to start audio**

---

### Flow 3.4: Configure Text-to-Speech

```
User → Settings → Text-to-Speech
         ↓
Sees:
Enable TTS                    [Toggle: ON]
Voice: [System Default ▼]
Speed: [0.8---[●]---2.0]
Auto-play messages           [Toggle: OFF]
Continue when backgrounded   [Toggle: ON]
         ↓
User wants to change voice
         ↓
Tap [System Default ▼]
         ↓
Menu shows available voices:
○ System Default (current)
○ Female Voice 1
○ Male Voice 1
○ Custom Voice (if downloaded)
         ↓
Select different voice
         ↓
Tap [Preview]
         ↓
Generates and plays sample:
"Here's how binary search works..."
         ↓
User adjusts speed slider
         ↓
Tap [Preview] again to hear with new speed
         ↓
Tap [Save]
         ↓
Settings saved
         ↓
TTS ready with new voice + speed
```

**Time: 2-3 minutes (one-time setup)**

---

## Phase 4: Long-Running Tasks Flows

### Flow 4.1: Start Long-Running Task

```
User → Chat screen
         ↓
Wants to do complex task:
"Research latest AI papers, analyze them, 
create 5-page summary"
         ↓
Model detects this is multi-step task
         ↓
Suggests:
"This is a complex task (5 steps, ~10 min).
Create a task to track progress?"
         ↓
User taps [Create Task]
         ↓
Task created with steps:
1. Search for papers
2. Download papers
3. Analyze content
4. Compile summary
5. Final review
         ↓
UI shows: TaskProgressCard
🎯 Research Task
[░░░░░░░░░░░░░░░░░░] 0%
Step 1: Search for papers (pending)
         ↓
Execution starts
         ↓
Step 1 running:
[████░░░░░░░░░░░░░░] 20%
⏳ Searching for papers (45s elapsed)
         ↓
Step 1 completes:
✓ Found 12 papers on arXiv
         ↓
Step 2 starts:
[████████░░░░░░░░░░] 40%
⏳ Downloading papers (38s elapsed)
```

**Estimated total time: 8-12 minutes**

---

### Flow 4.2: Monitor Background Task

```
User → Task is running (Step 3/5 at 65%)
         ↓
User needs to do something else
         ↓
Closes app or navigates elsewhere
         ↓
Task continues in background
         ↓
Notification appears (Android notification center):
🎯 Research Task
Processing: Step 3/5 (65%)
~1m 30s remaining
[⏸] [⏹] [→ View]
         ↓
User can:
- Tap [→ View]: Return to task details
- Tap [⏸]: Pause task
- Tap [⏹]: Cancel task
- Ignore: Task continues in background
         ↓
Option A: User taps [→ View]
         ↓
App opens/resumes
Returns to TaskProgressCard
Shows current step: Step 3/5 (65%)
         ↓
User watches progress, then navigates away again
         ↓
Task continues in background
         ↓
Notification updates: Step 4/5 (75%), 1m remaining
         ↓
[Notification] Task complete! (click to view results)
         ↓
Option B: User ignores notifications
         ↓
Task completes silently in background
         ↓
When user returns to app, sees completion in task list
```

**Background execution: 8-12 minutes**

---

### Flow 4.3: Task Completes Successfully

```
Task: Research AI Papers (Step 5/5)
         ↓
Final review step completes
         ↓
✓ All steps completed
         ↓
TaskProgressCard updates:
🎯 Research Task                [✓ Done]
"Research AI papers and summarize"
Completed in: 10m 32s
         ↓
Shows breakdown:
✓ Step 1: Search papers (45s) → Found 12
✓ Step 2: Download (38s) → 2.3GB
✓ Step 3: Analyze (5m 22s) → 1,245 pages
✓ Step 4: Compile (1m 48s) → 5 pages
✓ Step 5: Review (12s) → Verified
         ↓
Result content shows:
Key Findings:
• Transformers remain dominant
• Multi-modal models advancing
• Efficiency improvements critical
         ↓
User can:
[💾 Save] [📤 Share] [🔄 Refine] [➕ New]
         ↓
Tap [Share]
         ↓
Export as markdown/PDF and share
         ↓
Tap [Refine]
         ↓
"What would you like to refine?"
         ↓
User asks follow-up question
         ↓
New task created based on previous results
```

**Task completion time: 8-12 minutes**

---

### Flow 4.4: Task Error & Recovery

```
Task: Code Generation Sprint (Step 2/8)
         ↓
Step 2 executes
         ↓
API rate limit exceeded
         ↓
❌ Step 2 failed: "API quota exceeded"
         ↓
Task pauses automatically
         ↓
TaskProgressCard shows:
🎯 Code Generation Sprint     ⚠️ Paused
Step 2/8: Generate functions
Status: Failed - API rate limit exceeded
[▶ Resume] [Skip step] [Cancel] [Logs]
         ↓
Notification: Task paused - API error
         ↓
User has options:
         ↓
Path A: Wait for rate limit to reset
         ↓
[▶ Resume] → Task tries step 2 again
         ↓
Success → Continues to Step 3
         ↓
Path B: Skip problematic step
         ↓
[Skip step] → Task moves to Step 3
         ↓
Continues without Step 2 result
         ↓
Path C: Cancel entire task
         ↓
[Cancel] → Task stops
         ↓
Results saved so far
Can restart later
         ↓
Path D: View logs
         ↓
[Logs] → Shows detailed error
Can diagnose and retry with different settings
```

**Error recovery: 5-30 seconds (depending on fix)**

---

### Flow 4.5: Thinking Model Response

```
User → Sends question to thinking model
         ↓
"How would you approach this algorithm problem?"
         ↓
Send to llama3.2-thinking
         ↓
Model processes (extended thinking)
         ↓
Thinking phase: Internal reasoning (2-5 min)
No UI updates (background)
         ↓
Response ready
         ↓
ThinkingModelDisplay shows:
🤖 llama3.2-thinking
[🔄 Show thinking process]
Thinking tokens: 2,450
Response tokens: 320
Reading fee: 1.5x (thinking premium)
         ↓
User taps [🔄 Show thinking]
         ↓
Expanded view shows:
"First, let me understand this problem..."
"The key insight is..."
"Therefore, the approach should be..."
[⊗ Collapse]
         ↓
Final Answer:
"To approach this problem, you should..."
         ↓
User can:
- Copy thinking
- Copy response
- Export thinking process
- Use in task
```

**Thinking time: 2-5 minutes**

---

## Phase 5: MCP Integration Flows

### Flow 5.1: Connect MCP Server

```
User → Settings → MCP Servers
         ↓
Sees: "Connected Servers: 0"
         ↓
Taps [➕ Add MCP Server]
         ↓
Dialog shows options:
○ Auto-discover (local network)
○ Manual connection (host + port)
         ↓
User selects [Manual connection]
         ↓
Form shows:
Server Name: [_________________]
Host: [localhost]
Port: [3000]
         ↓
User enters:
Server Name: "Code Tools"
Host: "localhost"
Port: "3000"
         ↓
Tap [Connect]
         ↓
Connection attempt:
⏳ Connecting to localhost:3000...
         ↓
🟢 Connected!
Fetching tools...
         ↓
🔌 Code Tools
Status: Connected ✓
Tools: 12 available
         ↓
User can:
[View Tools] [Disconnect] [Settings]
         ↓
Server now available in chat
```

**Connection time: 2-5 seconds**

---

### Flow 5.2: Discover Tools

```
User → MCP Servers screen
         ↓
🔌 Code Tools (Connected)
         ↓
Taps [View Tools]
         ↓
MCPToolLibrary screen shows:
Code Tools (12 total)
[Search...]
         ↓
All tools listed:
☑ Git Status
   Get current repository status
   Status: Auto-allow
         ↓
☑ Search Codebase
   Find code by pattern
   Status: Auto-allow
         ↓
⚠️ Execute Script
   Run shell scripts (SENSITIVE)
   Status: Requires confirmation
   [Configure permissions]
         ↓
User can:
- Toggle auto-allow per tool
- Configure permissions
- View tool parameters
- Search tools
         ↓
User sets Execute Script to "Deny"
         ↓
Saved
         ↓
Return to chat
         ↓
Tools ready to use
```

**Configuration time: 2-3 minutes (one-time)**

---

### Flow 5.3: Use MCP Tool in Chat

```
User → Chat screen (MCP server connected)
         ↓
User asks: "Show me the binary_search function"
         ↓
Model detects this requires code search
         ↓
Model invokes MCP tool: "Search Codebase"
         ↓
Parameters: { query: "binary_search" }
         ↓
UI shows:
🔌 Code Tools: Using "Search Codebase"
   Searching for: "binary_search"
   Found 3 matches (0.8s)
         ↓
Tool results display:
┌─ src/algorithms/search.py (Line 42)
│ def binary_search(arr, target):
│   left = 0
│   right = len(arr) - 1
│   while left <= right:
│     mid = (left + right) // 2
│     if arr[mid] == target:
│       return mid
│ [View] [Copy] [Share]
│
├─ tests/test_search.py (Line 156)
│ ...
│
└─ docs/examples.md (Line 42)
   ...
         ↓
Model response uses results:
"I found the binary_search function in your codebase
at src/algorithms/search.py, line 42. Here's the
implementation and how it works..."
         ↓
User can:
- View each result
- Copy code snippets
- Share files
- Send follow-up questions using code context
```

**Tool invocation time: <2 seconds**

---

## Summary: v2 User Journey Complexity

| Feature | Setup | Per-Use | Error Recovery |
|---------|-------|---------|-----------------|
| Tool Calling | 2-3 min | <5 sec | 30-60 sec |
| Comparison | 10-15 sec | 2-3 sec | 5-10 sec |
| Native Share | <2 sec | <5 sec | Immediate |
| TTS | 2-3 min | <5 sec | Immediate |
| Tasks | Automatic | 1-2 sec | 5-30 sec |
| MCP | 2-5 sec | <2 sec | 5-10 sec |

**Total setup time for v2 features: ~10-15 minutes (one-time)**

**Regular usage: Seamless, <5 seconds per feature**

