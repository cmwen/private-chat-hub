# Web Search Feature

## Overview

The web search feature enables LLMs to search the internet for current information when needed. This is implemented using Ollama's tool calling (function calling) capability.

## How It Works

1. **Tool Definition**: The `WebSearchTool` defines a web search function that the LLM can call
2. **Automatic Detection**: When enabled, the LLM automatically decides when it needs to search the web
3. **Search Execution**: The app performs the search using DuckDuckGo's free API
4. **Result Integration**: Search results are provided back to the LLM, which uses them to answer the user's question

## Features

- **Toggle Control**: Enable/disable web search in Settings → AI Features
- **Visual Indicators**: Messages show when the AI is using web search tools
- **Privacy-Focused**: Uses DuckDuckGo's privacy-respecting search API (no API key required)
- **Automatic Context**: The LLM decides when web search is needed based on the conversation

## Usage

### Enable Web Search

1. Open the app
2. Go to **Settings** tab
3. Under **AI Features**, toggle **Web Search** on
4. Start chatting!

### When Web Search is Used

The LLM will automatically use web search when:
- You ask about current events or recent news
- You request information that requires up-to-date data
- You ask questions about topics the model may not have in its training data

### Visual Indicators

When the AI uses web search, you'll see:
- 🔍 **"Using web search..."** badge on the AI's message
- ✅ **"Search results"** badge on the search results message
- The final answer incorporating the search results

## Example Conversations

### Example 1: Current Information
```
User: What's the weather like in Paris today?
AI: [Using web search...] Let me search for current weather in Paris.
[Search results] ...weather data...
AI: Based on current information, Paris is experiencing...
```

### Example 2: Recent Events
```
User: What are the latest developments in AI?
AI: [Using web search...] Let me find recent AI news.
[Search results] ...news articles...
AI: Recent developments include...
```

## Technical Details

### Architecture

```
User Message
    ↓
ChatService (with web search enabled)
    ↓
OllamaService (sends message with tools definition)
    ↓
LLM decides to call web_search tool
    ↓
ChatService executes web search
    ↓
WebSearchService queries DuckDuckGo API
    ↓
Results returned to ChatService
    ↓
ChatService sends results back to LLM
    ↓
LLM generates final response with search results
    ↓
Response displayed to user
```

### Key Components

- **`lib/models/tool.dart`**: Tool definitions and data structures
- **`lib/services/web_search_service.dart`**: Web search implementation
- **`lib/services/chat_service.dart`**: Tool calling orchestration
- **`lib/services/ollama_service.dart`**: Updated to support tool calling
- **`lib/widgets/message_bubble.dart`**: Visual indicators for tool usage

### Tool Definition

The web search tool is defined as:

```dart
WebSearchTool()
  name: 'web_search'
  description: 'Search the internet for current information, news, facts, or answers to questions'
  parameters:
    - query (required): The search query string
```

### Search Provider

Currently uses **DuckDuckGo Instant Answer API**:
- **Pros**: Free, no API key required, privacy-focused
- **Cons**: Limited to instant answers and related topics
- **Alternative**: Can be extended to use Google Custom Search, Bing Search API, or SerpApi

## Ollama Model Support

Not all Ollama models support tool calling. Tool calling is typically supported by:

✅ **Supported Models:**
- llama3.1 and newer
- mistral-nemo
- qwen2.5
- Other models with function calling support

❌ **Not Supported:**
- llama3 (3.0 and earlier)
- llama2
- gemma
- Most older models

**Note**: If your model doesn't support tool calling, the web search feature will simply be ignored.

## Configuration

### Enable/Disable Web Search

Web search can be toggled in Settings:
```dart
chatService.setWebSearchEnabled(true);  // Enable
chatService.setWebSearchEnabled(false); // Disable
```

Default: **Enabled**

### Storage

The web search setting is persisted using `SharedPreferences`:
- Key: `web_search_enabled`
- Type: `bool`
- Default: `true`

## Testing

Run tests for web search functionality:

```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/models/tool_test.dart
flutter test test/services/web_search_service_test.dart
```

## Future Enhancements

### Planned Improvements

1. **Additional Search Providers**
   - Google Custom Search API
   - Bing Search API
   - SerpApi integration

2. **More Tools**
   - Calculator tool
   - Code execution tool
   - Weather API tool
   - Wikipedia search tool

3. **Advanced Configuration**
   - Select preferred search provider
   - Configure search result count
   - Filter search by date/domain
   - Custom tool definitions

4. **UI Improvements**
   - Show search query in UI
   - Display search source/links
   - Clickable URLs in results
   - Search history

5. **Performance**
   - Cache search results
   - Parallel tool execution
   - Rate limiting

## Troubleshooting

### Web Search Not Working

1. **Check model support**: Ensure your Ollama model supports tool calling (e.g., llama3.1+)
2. **Verify setting**: Make sure web search is enabled in Settings
3. **Check internet**: Ensure the device has internet connectivity
4. **Ollama version**: Update Ollama to the latest version (0.2.0+)

### Search Results Quality

- Try rephrasing your question more specifically
- DuckDuckGo's instant answer API works best for:
  - Definitions
  - Quick facts
  - Well-known topics
- For comprehensive search, consider implementing Google/Bing API

### Privacy Concerns

- All searches go through DuckDuckGo, which doesn't track users
- Searches are made directly from the app to DuckDuckGo
- No search data is logged or stored by the app
- Your Ollama server doesn't see the search queries (unless it has internet access)

## API Documentation

### WebSearchService

```dart
// Create service
final webSearch = WebSearchService();

// Perform search
final results = await webSearch.search('your query');

// Dispose when done
webSearch.dispose();
```

### ChatService

```dart
// Check if web search is enabled
final isEnabled = chatService.getWebSearchEnabled();

// Enable/disable web search
await chatService.setWebSearchEnabled(true);
```

## Contributing

To contribute to the web search feature:

1. Add new search providers in `lib/services/web_search_service.dart`
2. Create new tools in `lib/models/tool.dart`
3. Update tool execution in `lib/services/chat_service.dart`
4. Add tests in `test/services/` and `test/models/`
5. Update this documentation

## License

Same as the main project (MIT).

## Credits

- DuckDuckGo for providing free search API
- Ollama for tool calling support
- Flutter community for guidance
