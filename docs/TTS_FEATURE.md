# Text-to-Speech (TTS) Feature

This app includes Android native text-to-speech functionality to read AI responses aloud.

## Features

### 1. TTS Streaming Mode (Experimental)
- **Location**: Voice icon button in the chat screen AppBar
- **Icon**: 🎤 (voice_over) when disabled, 🔊 (record_voice_over) when enabled
- **Function**: When enabled, the app will read AI responses as they stream in
- **How it works**: The TTS engine speaks text in chunks as the AI generates the response
- **Note**: This is experimental and may sound choppy depending on response speed

### 2. Manual Message Playback
- **Location**: "Speak" button next to "Copy" in each AI message bubble
- **Icon**: 🔊 (volume_up) to start, ⏹️ (stop) when playing
- **Function**: Read the complete message text aloud
- **Control**: Click "Stop" to stop playback at any time

### 3. Message Actions Menu
- **Location**: Long-press any AI message to open actions menu
- **Option**: "Speak Message" / "Stop Speaking"
- **Function**: Alternative way to control TTS for individual messages

## How TTS Streaming Works

When TTS streaming is enabled:

1. As the AI generates a response, text chunks are captured
2. When a chunk reaches 50+ characters OR ends with punctuation (. ! ?), it's spoken
3. This provides near real-time audio feedback as the AI responds
4. The feature automatically resets when the response completes

**Pros:**
- Real-time audio feedback
- More engaging conversation experience
- Useful for hands-free usage

**Cons:**
- May sound fragmented for slow responses
- Can interrupt if stopped mid-sentence
- Uses more system resources

## Technical Details

### Android Native TTS
- Uses Android's `TextToSpeech` API via flutter_tts package
- No internet required - uses on-device TTS engine
- Settings: English (US), normal speed, normal pitch
- Automatically removes markdown formatting for natural speech

### Markdown Cleaning
The TTS service automatically removes:
- Code blocks → "[code block]"
- Inline code → "[code]"
- Bold/italic markers
- Headers (#)
- Links (keeps text, removes URL)
- List markers

### Performance
- Minimal overhead when TTS is disabled
- Streaming mode uses slightly more resources
- TTS engine is initialized on first use
- Properly cleaned up when leaving chat

## Usage Tips

1. **For Long Responses**: Use streaming mode to hear the response as it generates
2. **For Reading Later**: Click the "Speak" button on completed messages
3. **To Stop**: Click the stop button or toggle off streaming mode
4. **Multiple Messages**: Only one message can be spoken at a time
5. **Code Heavy**: TTS works best with text-heavy responses (code is summarized)

## Future Improvements

Potential enhancements:
- [ ] Adjustable speech rate, pitch, and volume
- [ ] Language selection
- [ ] Voice selection (male/female, different accents)
- [ ] Better handling of code blocks and technical terms
- [ ] Pause/resume functionality
- [ ] Queue multiple messages
- [ ] Save TTS preferences per conversation

## Troubleshooting

**TTS doesn't work:**
- Ensure Android TTS engine is installed on your device
- Go to Android Settings → Accessibility → Text-to-Speech
- Install or update speech engine if needed

**Speech sounds robotic:**
- This is normal for Android's default TTS
- Install Google Text-to-Speech for better quality
- Available on Google Play Store

**Streaming sounds choppy:**
- This is expected - the AI generates text in chunks
- Try using manual playback on completed messages instead
- Streaming works best with fast, consistent response generation

## Implementation Notes

### Key Files
- `lib/services/tts_service.dart` - TTS service implementation
- `lib/screens/chat_screen.dart` - UI integration and streaming logic

### Dependencies
- `flutter_tts: ^4.2.0` - Cross-platform TTS plugin
- Uses Android native TTS engine (no additional setup required)

### Architecture
```
ChatScreen
  ├── TtsService (singleton per screen)
  ├── Streaming Handler (monitors message updates)
  └── Message Widgets (individual TTS controls)
```

The streaming handler tracks:
- Last spoken text position
- Current message being generated
- Whether to speak new chunks
- When to reset for next message
