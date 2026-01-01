# Web Search Feature - Visual Guide

## UI Screenshots Description

Since this is a code implementation, here's what users will see:

### 1. Settings Screen - Web Search Toggle

```
┌─────────────────────────────────────┐
│ Settings                            │
├─────────────────────────────────────┤
│                                     │
│ Ollama Connections                  │
│ ┌─────────────────────────────────┐ │
│ │ 🔵 Local Server (Default)       │ │
│ │ http://localhost:11434          │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                     │
│ AI Features                         │
│ ┌─────────────────────────────────┐ │
│ │ 🔍 Web Search            [ON] ◉ │ │
│ │ Allow AI to search the internet │ │
│ │ for current information         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                     │
│ ℹ️  About                           │
│ Private Chat Hub v1.0.0             │
│                                     │
└─────────────────────────────────────┘
```

### 2. Chat Screen - Web Search in Action

```
┌─────────────────────────────────────┐
│ < Conversation with llama3.1        │
├─────────────────────────────────────┤
│                                     │
│         ┌─────────────────────────┐ │
│         │ What's the weather in   │ │
│    You │ Paris today?       14:23│ │
│         └─────────────────────────┘ │
│                                     │
│ ┌───────────────────────────────────┤
│ │ 🤖                                │
│ │ ┌─────────────────────────────┐  │
│ │ │ 🔍 Using web search...      │  │
│ │ └─────────────────────────────┘  │
│ │ Let me search for current       │
│ AI│ weather information in Paris.│
│ │                          14:23  │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌───────────────────────────────────┤
│ │ 🤖                                │
│ │ ┌─────────────────────────────┐  │
│ │ │ ✅ Search results           │  │
│ │ └─────────────────────────────┘  │
│ │ Web Search Results for:         │
│ │ "Paris weather today"           │
│ │                                 │
│ │ Summary:                        │
│ │ Paris is experiencing partly    │
│ AI│ cloudy conditions with a      │
│ │ temperature of 18°C...          │
│ │ Source: Weather.com             │
│ │                          14:23  │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌───────────────────────────────────┤
│ │ 🤖                                │
│ │ Based on current information,   │
│ │ Paris is experiencing partly    │
│ │ cloudy weather today with a     │
│ AI│ temperature of 18°C (64°F).   │
│ │ It's a pleasant day with light  │
│ │ winds from the northwest.       │
│ │                          14:24  │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ 📎  Type a message...          🎤   │
└─────────────────────────────────────┘
```

### 3. Message Bubbles - Visual Indicators

#### Tool Call Badge
```
┌─────────────────────────────┐
│ 🔍 Using web search...      │  ← Blue badge with search icon
└─────────────────────────────┘
```
- **Color**: Light blue background
- **Icon**: 🔍 Search icon
- **Text**: "Using web search..." or "Using N tools..."
- **Position**: Top of AI message bubble

#### Tool Result Badge
```
┌─────────────────────────────┐
│ ✅ Search results           │  ← Green badge with check
└─────────────────────────────┘
```
- **Color**: Light green background
- **Icon**: ✅ Check circle
- **Text**: "Search results"
- **Position**: Top of search result message bubble

### 4. Color Scheme

**Tool Call Indicator:**
- Background: `Colors.blue.withOpacity(0.1)`
- Border: `Colors.blue.withOpacity(0.3)`
- Text/Icon: `Colors.blue[700]`

**Tool Result Indicator:**
- Background: `Colors.green.withOpacity(0.1)`
- Border: `Colors.green.withOpacity(0.3)`
- Text/Icon: `Colors.green[700]`

### 5. Example Conversations

#### Example 1: Current Events
```
User: "Who won the latest Formula 1 race?"

AI: [🔍 Using web search...]
    "Let me find the latest F1 race results."

System: [✅ Search results]
        "Latest F1 race winner: [driver name]"

AI: "According to recent results, [driver] won 
     the latest Formula 1 race..."
```

#### Example 2: Technical Question
```
User: "How do I center a div in CSS?"

AI: "There are several ways to center a div..."
    (No web search - uses training data)
```

#### Example 3: Recent Information
```
User: "What are the latest AI developments?"

AI: [🔍 Using web search...]
    "Let me search for recent AI news."

System: [✅ Search results]
        "Recent AI developments include..."

AI: "Based on current information, recent 
     developments in AI include..."
```

## When Web Search is NOT Used

The LLM decides when search is needed. It won't search for:
- General knowledge questions
- Math problems
- Code explanations
- Historical facts (unless explicitly recent)
- Definitions of common terms

## Animation & Interaction

### Loading State
When performing a search:
1. Tool call badge appears immediately
2. Message text may say "Let me search..."
3. Brief pause (1-3 seconds) for API call
4. Search result message appears
5. Final AI response with information

### No Additional User Action Required
- Everything happens automatically
- User just types question and waits
- No special commands needed
- Works like a normal conversation

## Mobile-Optimized Design

- **Touch-friendly**: All badges are read-only, no accidental taps
- **Readable**: Clear icons and text
- **Scrollable**: Long search results can be scrolled
- **Responsive**: Works on all Android screen sizes
- **Accessible**: Uses Material Design 3 for accessibility

## Error Handling

If search fails:
```
┌───────────────────────────────────┐
│ 🤖                                │
│ I tried to search for that        │
│ information, but encountered an   │
AI│ error. Let me answer based on   │
│ what I know: [answer from         │
│ training data]                    │
└───────────────────────────────────┘
```

## Comparison: Before vs After

### Before (Without Web Search)
```
User: "What's the weather today?"

AI: "I don't have access to current weather 
     information. You can check weather.com 
     or your local weather app for up-to-date 
     forecasts."
```

### After (With Web Search)
```
User: "What's the weather today?"

AI: [🔍 Using web search...]
    [✅ Search results]
    
    "Based on current information, the weather 
     is 72°F and sunny with clear skies. 
     Perfect day to go outside!"
```

## Privacy Indicators

Users can verify privacy:
1. **Settings shows**: "Web search enabled"
2. **Messages show**: When search is used (blue badge)
3. **Results show**: Search source (DuckDuckGo)
4. **No tracking**: DuckDuckGo privacy notice in docs

---

**Note**: Actual UI will use real Flutter Material Design 3 components with smooth animations and proper theming. ASCII art above is for visualization only.
