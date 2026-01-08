# Streaming Mode Toggle - Manual Testing Guide

## Overview
A toggle has been added to switch between streaming and sync (non-streaming) modes for chat responses. This allows users to reduce UI pressure caused by continuous rerendering during streaming.

## Location
**Settings > AI Features > Streaming Mode**

## How to Test

### 1. Verify Toggle Appears in Settings
1. Launch the app
2. Navigate to Settings screen
3. Scroll to "AI Features" section
4. Verify "Streaming Mode" toggle is visible
5. Check the subtitle changes based on toggle state:
   - ON: "Responses stream in real-time (may cause more UI updates)"
   - OFF: "Responses load all at once (reduces UI pressure)"

### 2. Test Default State
1. On first launch, streaming should be **enabled by default**
2. This maintains backward compatibility with existing behavior

### 3. Test Streaming Mode (Toggle ON)
1. Enable streaming mode in Settings
2. Go to chat screen
3. Send a message to the AI model
4. **Expected behavior:**
   - Response appears word-by-word or chunk-by-chunk
   - UI updates continuously as text streams in
   - You can see the response building up in real-time

### 4. Test Non-Streaming Mode (Toggle OFF)
1. Disable streaming mode in Settings
2. Go to chat screen
3. Send a message to the AI model
4. **Expected behavior:**
   - Loading indicator appears (if implemented)
   - Response appears all at once when complete
   - No incremental UI updates during generation
   - Reduces UI rerendering pressure

### 5. Test Persistence Across App Restarts
1. Set streaming mode to OFF
2. Close the app completely
3. Relaunch the app
4. Check Settings > AI Features
5. **Expected:** Toggle should still be OFF
6. Repeat with streaming mode ON

### 6. Test Comparison Mode (Dual Model)
If the app supports comparison mode with two models:
1. Enable comparison mode
2. Toggle streaming mode ON/OFF
3. Send a message
4. **Expected:**
   - Streaming ON: Both model responses stream simultaneously
   - Streaming OFF: Both responses appear at once after completion

### 7. Performance Comparison
To test the original issue (UI pressure):
1. With streaming ON:
   - Send a long message requiring detailed response
   - Observe UI updates and any lag/stuttering
   - Note the rendering frequency

2. With streaming OFF:
   - Send the same message
   - Observe that UI only updates once at completion
   - Should feel smoother with reduced rendering pressure

## Technical Implementation Details

### Files Modified
- `lib/screens/settings_screen.dart` - UI toggle
- `lib/services/chat_service.dart` - Streaming logic
- `lib/ollama_toolkit/services/ollama_config_service.dart` - Preference storage (already existed)

### API Methods Used
- Streaming: `client.chatStream()` - Returns `Stream<OllamaChatResponse>`
- Non-streaming: `client.chat()` - Returns `Future<OllamaChatResponse>`

### Storage
Preference is stored using SharedPreferences with key: `ollama_stream_enabled`

## Expected Test Results
✅ Toggle appears in settings
✅ Default state is ON (streaming enabled)
✅ Streaming mode shows incremental updates
✅ Non-streaming mode shows complete response at once
✅ Setting persists across app restarts
✅ Both single and comparison modes respect the setting
✅ UI feels smoother with streaming OFF for long responses

## Troubleshooting

### Issue: Toggle doesn't appear
- Check that ChatService is passed to SettingsScreen
- Verify the "AI Features" section is visible

### Issue: Setting doesn't persist
- Ensure SharedPreferences is properly initialized
- Check permissions for app data storage

### Issue: No difference between modes
- Verify Ollama server is responding
- Check debug logs for "streamingEnabled" value
- Ensure ChatService is using the OllamaConfigService

## Notes
- This feature is designed to help with performance on devices that struggle with frequent UI updates
- Streaming mode provides better UX for seeing progress
- Non-streaming mode is better for stability and reduced resource usage
- Both modes should produce identical final results
