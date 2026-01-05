# Web Search Error Messages - User Guidance

This document explains the error messages users may see when using web search and how to fix them.

## Error Message Scenarios

### 1. **Web Search Not Configured** ⚙️

**Message:**
```
⚙️ Web search is not configured. Please:
1. Get a free API key at https://jina.ai/?sui=apikey
2. Add it in Settings > Tools Configuration
3. Enable "Web Search" toggle
4. Restart the app
```

**When it appears:**
- User hasn't added a Jina API key yet
- User hasn't enabled web search in settings
- No API key is configured at app startup

**How to fix:**
1. Go to Settings → Tools Configuration
2. Visit https://jina.ai/?sui=apikey to get a free API key
3. Paste the API key in the "Jina API Key" field
4. Toggle "Enable Web Search" to ON
5. Restart the app
6. Web search will now be available

---

### 2. **Invalid API Key** ❌

**Message:**
```
❌ Invalid Jina API key. Please check your settings and ensure the key is correct.
```

**When it appears:**
- API key format is wrong
- API key has expired
- API key was copied with extra spaces

**How to fix:**
1. Go to Settings → Tools Configuration
2. Double-check the API key (remove any extra spaces)
3. Visit https://jina.ai/?sui=apikey to verify the key is still valid
4. Copy the full key without spaces
5. Restart the app

---

### 3. **API Endpoint Not Accessible** ❌

**Message:**
```
❌ Jina API endpoint not accessible. Your API key may not have web search enabled 
or subscription is invalid. Check https://jina.ai/?sui=apikey
```

**When it appears:**
- API key doesn't have web search subscription
- Account isn't activated
- API subscription expired

**How to fix:**
1. Visit https://jina.ai/?sui=apikey to check your account
2. Verify your email if not already done
3. Ensure "Web Search" is enabled on your account
4. Get a new free API key if needed
5. Update the key in Settings and restart

---

### 4. **Rate Limit Exceeded** ⏱️

**Message:**
```
⏱️ Search rate limit exceeded. Please wait a moment and try again.
```

**When it appears:**
- Too many searches in a short time
- Free tier has been exceeded

**How to fix:**
- Wait a few minutes before searching again
- For higher limits, upgrade your Jina plan at https://jina.ai

---

### 5. **Network Error** 🌐

**Message:**
```
🌐 Network error: [specific error]

Please check your internet connection and try again.
```

**When it appears:**
- Device has no internet connection
- Request timed out after 30 seconds
- Network is temporarily unavailable

**How to fix:**
- Check your internet connection
- Try again in a moment
- Retry the search after connection is stable

---

### 6. **General Search Error** ❌

**Message:**
```
❌ Search failed: [error details]

Troubleshooting: Check your Jina API key in Settings > Tools Configuration
```

**When it appears:**
- Unknown error occurred
- Jina API returned unexpected response

**How to fix:**
1. Verify your API key is correct in Settings
2. Try a different search query
3. Restart the app
4. Check internet connection

---

## Quick Troubleshooting Checklist

- [ ] Do I have a Jina API key? (Get one: https://jina.ai/?sui=apikey)
- [ ] Is the key in Settings > Tools Configuration?
- [ ] Is "Enable Web Search" toggle turned ON?
- [ ] Have I restarted the app after changing settings?
- [ ] Is my internet connection working?
- [ ] Is the API key correct (no extra spaces)?
- [ ] Is my API account active (check at jina.ai)?

## How Web Search Works

When you use a tool-calling model (like gpt-oss:20b) with web search enabled:

1. **Model receives tools list** - Jina API credentials are verified
2. **Model generates search query** - If needed for answering
3. **Search is executed** - Queries the web via Jina
4. **Results are returned** - Model uses results for better answer
5. **Error details shown** - Any issues are displayed with solutions

## Testing Web Search

To test if web search is working:

1. Select a tool-capable model (e.g., gpt-oss:20b)
2. Ask a question that requires current information:
   - "What are the latest AI news?"
   - "Who won the latest sports game?"
   - "What's the current weather?"
3. If configured correctly, the model will search and return current results

---

## Support

If you continue having issues:

1. **Visit Jina Support**: https://jina.ai
2. **Check API Status**: Verify service status
3. **Review Logs**: Check debug logs for detailed error messages
4. **Try Free Tier**: Reset and get a new free API key if old one expired
