# TTS Feature Testing Guide

## Manual Test Cases

### Setup
1. Build and install the APK on an Android device
2. Ensure device has TTS engine installed (usually comes with Google Text-to-Speech)
3. Open the app and navigate to a chat conversation

---

## Test Case 1: Basic TTS Functionality

### Objective
Verify that individual messages can be spoken using the "Speak" button.

### Steps
1. Send a message to the AI
2. Wait for a complete response
3. Look for the "Speak" button next to "Copy" in the AI message bubble
4. Click the "Speak" button
5. Verify audio output starts
6. Click the "Stop" button while speaking
7. Verify audio stops immediately

### Expected Results
- ✅ "Speak" button is visible next to "Copy"
- ✅ Audio plays when "Speak" is clicked
- ✅ Button changes to "Stop" with stop icon
- ✅ Audio stops when "Stop" is clicked
- ✅ Button returns to "Speak" state

---

## Test Case 2: TTS Streaming Mode

### Objective
Verify that TTS streaming mode reads AI responses as they arrive.

### Steps
1. Look for the voice icon (🎤) in the AppBar (top right)
2. Click the voice icon to enable TTS streaming
3. Verify snackbar message: "TTS streaming enabled"
4. Icon should change to 🔊 (record_voice_over)
5. Send a new message to the AI
6. Observe as the response streams in
7. Verify audio starts playing as chunks arrive
8. Wait for complete response
9. Click the voice icon again to disable
10. Verify snackbar message: "TTS streaming disabled"

### Expected Results
- ✅ Voice icon toggles between two states
- ✅ Snackbar appears on toggle
- ✅ Audio plays during streaming when enabled
- ✅ Audio speaks in chunks as text arrives
- ✅ No audio when streaming is disabled
- ✅ Icon state persists during conversation

---

## Test Case 3: Message Actions Menu

### Objective
Verify TTS can be controlled from the long-press menu.

### Steps
1. Long-press an AI message bubble
2. Verify bottom sheet appears with actions
3. Look for "Speak Message" option
4. Tap "Speak Message"
5. Verify audio starts playing
6. Long-press the same message again
7. Verify option changed to "Stop Speaking"
8. Tap "Stop Speaking"
9. Verify audio stops

### Expected Results
- ✅ Bottom sheet opens on long-press
- ✅ "Speak Message" option visible for AI messages
- ✅ Option changes to "Stop Speaking" when active
- ✅ Audio plays/stops as expected
- ✅ Menu closes after selection

---

## Test Case 4: Multiple Messages

### Objective
Verify only one message can be spoken at a time.

### Steps
1. Have at least 2 AI responses in the conversation
2. Click "Speak" on the first message
3. Verify audio starts playing
4. Immediately click "Speak" on the second message
5. Verify first message stops and second starts

### Expected Results
- ✅ First message audio stops when second is clicked
- ✅ Second message audio starts immediately
- ✅ Only one "Stop" button visible at a time
- ✅ No audio overlap or confusion

---

## Test Case 5: Markdown Cleaning

### Objective
Verify code blocks and markdown are handled properly.

### Test Messages to Send
1. "Explain this code: `console.log('hello')`"
2. "Show me a markdown table with **bold** text"
3. "Write a code block with Python"

### Steps
1. Send each test message
2. Wait for AI response (should contain markdown)
3. Click "Speak" on each response
4. Listen to audio output

### Expected Results
- ✅ Code blocks are read as "[code block]" not character by character
- ✅ Inline code is read as "[code]"
- ✅ Bold/italic markers are not spoken
- ✅ Links are read without URLs
- ✅ Headers read without hash marks
- ✅ Overall speech sounds natural

---

## Test Case 6: Streaming Mode with Code

### Objective
Verify streaming handles code blocks well.

### Steps
1. Enable TTS streaming mode
2. Ask AI: "Write a Python function to calculate fibonacci"
3. Listen as response streams in
4. Verify code blocks are summarized

### Expected Results
- ✅ Text portions are spoken normally
- ✅ Code blocks are announced as "[code block]"
- ✅ No character-by-character reading of code
- ✅ Streaming doesn't break on code sections

---

## Test Case 7: Widget Lifecycle

### Objective
Verify TTS stops when leaving the chat.

### Steps
1. Start playing a long message
2. While it's still speaking, press back button
3. Navigate to different screen
4. Verify audio stops

### Expected Results
- ✅ Audio stops when leaving chat screen
- ✅ No memory leaks or crashes
- ✅ Can return to chat without issues

---

## Test Case 8: Error Handling

### Objective
Verify graceful handling when TTS is unavailable.

### Steps
1. On a device without TTS engine (or with it disabled)
2. Try to click "Speak" button
3. Observe behavior

### Expected Results
- ✅ Error message appears via snackbar
- ✅ No crash occurs
- ✅ Button returns to normal state
- ✅ User can continue using app

---

## Test Case 9: Streaming Toggle Persistence

### Objective
Verify streaming mode toggle state during conversation.

### Steps
1. Enable TTS streaming
2. Send a message and verify it speaks
3. Send another message while first is speaking
4. Verify second message also speaks (queued or replaces)
5. Disable streaming
6. Send a third message
7. Verify no automatic speaking

### Expected Results
- ✅ Streaming mode stays enabled across messages
- ✅ Each new message is spoken when mode is on
- ✅ Disabling stops automatic speaking
- ✅ Manual "Speak" button still works when streaming is off

---

## Test Case 10: Performance

### Objective
Verify TTS doesn't impact app performance.

### Steps
1. Enable streaming mode
2. Send multiple rapid messages
3. Observe app responsiveness
4. Check for lag or stuttering
5. Monitor device temperature

### Expected Results
- ✅ UI remains responsive
- ✅ Scrolling is smooth
- ✅ Message input works normally
- ✅ No significant battery drain
- ✅ No excessive heating

---

## Edge Cases to Test

### Long Messages
- Test with very long AI responses (1000+ words)
- Verify complete playback
- Check stop functionality mid-speech

### Quick Responses
- Test streaming with very fast, short responses
- Verify audio doesn't overlap or skip

### Empty Messages
- Test with empty or whitespace-only responses
- Should handle gracefully without speaking

### Special Characters
- Test messages with emojis, symbols, numbers
- Verify proper pronunciation

### Network Interruption
- Start speaking during active generation
- Interrupt network mid-stream
- Verify graceful handling

---

## Automated Test Scenarios (Future)

```dart
testWidgets('TTS button appears for assistant messages', (tester) async {
  // Arrange
  final message = Message.assistant(
    id: '1',
    text: 'Hello world',
    timestamp: DateTime.now(),
  );
  
  // Act
  await tester.pumpWidget(TestApp(message: message));
  
  // Assert
  expect(find.text('Speak'), findsOneWidget);
});

testWidgets('TTS toggle changes icon', (tester) async {
  // Arrange
  await tester.pumpWidget(TestApp());
  
  // Act
  await tester.tap(find.byIcon(Icons.voice_over_off));
  await tester.pump();
  
  // Assert
  expect(find.byIcon(Icons.record_voice_over), findsOneWidget);
});
```

---

## Test Report Template

### Test Execution: [Date]

| Test Case | Status | Notes | Issues |
|-----------|--------|-------|--------|
| TC1: Basic TTS | ⬜ Pass / ❌ Fail | | |
| TC2: Streaming | ⬜ Pass / ❌ Fail | | |
| TC3: Menu Actions | ⬜ Pass / ❌ Fail | | |
| TC4: Multiple Messages | ⬜ Pass / ❌ Fail | | |
| TC5: Markdown | ⬜ Pass / ❌ Fail | | |
| TC6: Code Streaming | ⬜ Pass / ❌ Fail | | |
| TC7: Lifecycle | ⬜ Pass / ❌ Fail | | |
| TC8: Error Handling | ⬜ Pass / ❌ Fail | | |
| TC9: Toggle State | ⬜ Pass / ❌ Fail | | |
| TC10: Performance | ⬜ Pass / ❌ Fail | | |

**Device Info:**
- Model:
- Android Version:
- TTS Engine:
- App Version:

**Overall Assessment:**
- [ ] All core features working
- [ ] Minor issues (list below)
- [ ] Major issues (list below)
- [ ] Recommend for release

**Issues Found:**
1.
2.
3.

**Recommendations:**
1.
2.
3.
