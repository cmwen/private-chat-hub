# Implementation Notes: Input Box Max Lines and Background Notifications

## Problem Statement
1. **UX Issue**: Input box should limit to max 3 lines of text to prevent hiding the enter button and other UI elements
2. **Background Execution**: When LLM responses take long (especially for synchronous mode), allow users to navigate to other apps, let requests run in the background, and show a native Android notification when the response completes. Tapping the notification should bring the user back to the chat.

## Implementation Summary

### 1. Input Box Max Lines Constraint
**File**: `lib/widgets/message_input.dart`

**Changes**:
- Set `maxLines: 3` on the TextField widget (previously was `null` allowing unlimited expansion)
- Added `minLines: 1` to ensure the field starts at a reasonable height

**Impact**:
- The input text field will now expand up to 3 lines as the user types
- After 3 lines, the field becomes scrollable internally
- The send button and other UI elements remain visible at all times
- Improves UX by preventing the input field from taking over the entire screen

### 2. Background Execution with Notifications

#### 2.1 Dependencies
**File**: `pubspec.yaml`

**Changes**:
- Added `flutter_local_notifications: ^18.0.1` package for Android notifications

#### 2.2 Android Permissions and Build Configuration
**Files**: 
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`

**Changes**:
- Added `POST_NOTIFICATIONS` permission (required for Android 13+)
- Enabled core library desugaring in build.gradle.kts (required by flutter_local_notifications)
- Added desugar_jdk_libs dependency

#### 2.3 Notification Service
**File**: `lib/services/notification_service.dart` (new)

**Features**:
- Singleton service for managing local notifications
- Handles notification initialization and permission requests
- Shows notifications when AI responses complete
- Tracks notification taps to enable navigation back to conversations
- Provides methods for:
  - `initialize()`: Set up notification plugin
  - `requestPermissions()`: Request notification permissions (Android 13+)
  - `showResponseCompleteNotification()`: Display notification with response preview
  - `cancelNotification()`: Cancel specific notification
  - `cancelAllNotifications()`: Clear all notifications

#### 2.4 ChatService Integration
**File**: `lib/services/chat_service.dart`

**Changes**:
- Added NotificationService instance
- Added `_showResponseCompleteNotification()` helper method
- Integrated notification calls at all message completion points:
  - Streaming mode completion (`_generateSimpleChat`)
  - Non-streaming mode completion (`_generateSimpleChat`)
  - Tool-based generation completion (`_generateWithTools`)

**How Background Execution Works**:
1. When a user sends a message, ChatService creates a stream for the response
2. The stream continues running independently of the UI (managed by `_activeStreams` and `_activeSubscriptions`)
3. When the user navigates away from the chat screen:
   - The UI subscription is cancelled (in ChatScreen.dispose)
   - But the underlying stream in ChatService continues running
4. When the response completes, ChatService shows a notification
5. Tapping the notification reopens the app to the relevant conversation

#### 2.5 Main App Integration
**File**: `lib/main.dart`

**Changes**:
- Initialize NotificationService in main()
- Request notification permissions on app startup
- Added `_checkNotificationLaunch()` in HomeScreen to handle notification taps
- When app is opened from notification, automatically navigate to the conversation

## Architecture Notes

### Stream Management
The implementation leverages Flutter's Stream architecture:
- **ChatService** maintains active streams in `_activeStreams` Map
- Streams continue running even when UI listeners are cancelled
- Only explicitly cancelled when `cancelMessageGeneration()` is called
- This allows background execution without additional complexity

### Notification Flow
1. User sends message → ChatService starts generating response
2. User navigates away → UI unsubscribes but stream continues
3. Response completes → ChatService calls NotificationService
4. NotificationService shows Android notification with preview
5. User taps notification → Android launches app with conversation ID
6. HomeScreen checks for notification data and navigates to conversation

## Testing Recommendations

### Manual Testing Checklist

#### Input Box Max Lines
- [ ] Open a chat
- [ ] Type a short message (1 line) - verify normal behavior
- [ ] Type a longer message (2-3 lines) - verify field expands
- [ ] Type a very long message (more than 3 lines) - verify field stops expanding and becomes scrollable
- [ ] Verify send button remains visible at all times
- [ ] Verify attachment button (if present) remains visible

#### Background Notifications
- [ ] Send a message to a model (especially with synchronous/slow responses)
- [ ] Press home button to background the app
- [ ] Wait for response to complete
- [ ] Verify notification appears with:
  - Conversation title
  - Response preview (truncated to 100 characters)
- [ ] Tap notification
- [ ] Verify app opens to the correct conversation
- [ ] Verify response is displayed correctly

#### Permissions
- [ ] Fresh install: verify notification permission is requested on first launch
- [ ] Deny permission → verify app still works but no notifications shown
- [ ] Grant permission later → verify notifications work after granting

### Automated Testing
Current tests continue to pass:
- All existing unit tests pass ✅
- Widget tests pass ✅
- Build succeeds for debug and release ✅

Potential additional tests:
- Widget test for TextField maxLines behavior
- Unit test for NotificationService initialization
- Integration test for notification display (requires emulator)

## Known Limitations

1. **iOS Support**: This implementation is Android-only. iOS would require:
   - Different notification setup (ios-specific configuration)
   - APNs setup if remote notifications needed
   - Different permission handling

2. **Notification Persistence**: Notifications are cleared when tapped. They don't persist in notification history after dismissal.

3. **Multiple Active Generations**: If multiple conversations have active generations, each will show its own notification. The implementation handles this by using conversation ID hash as notification ID.

4. **App Force-Killed**: If the Android system force-kills the app process, active streams will be terminated and notifications won't be shown. This is a platform limitation unless a background service is implemented.

## Future Enhancements

1. **Notification Actions**: Add action buttons to notifications (e.g., "Read Aloud", "Share")
2. **Notification Grouping**: Group multiple conversation notifications together
3. **Progress Notifications**: Show ongoing notification while response is generating
4. **Background Service**: Implement a proper Android foreground service for guaranteed background execution
5. **iOS Support**: Extend implementation to iOS platform
6. **Notification Sound/Vibration Settings**: Allow users to customize notification behavior
7. **Do Not Disturb**: Respect system DND settings and provide in-app quiet hours

## Security and Privacy Considerations

1. **Notification Content**: Response previews are shown in notifications, which are visible on lock screen by default. Consider:
   - Adding a setting to disable response previews
   - Truncating sensitive content
   - Respecting Android's notification visibility settings

2. **Background Execution**: The current implementation runs in the app process. If privacy is critical:
   - Consider not showing response previews
   - Add explicit user consent for background notifications

## Dependencies Added

```yaml
flutter_local_notifications: ^18.0.1
```

Build configuration:
```kotlin
coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
```

## Files Modified

1. `lib/widgets/message_input.dart` - Input max lines
2. `lib/services/notification_service.dart` - New file, notification handling
3. `lib/services/chat_service.dart` - Notification integration
4. `lib/main.dart` - Notification initialization
5. `android/app/src/main/AndroidManifest.xml` - Permissions
6. `android/app/build.gradle.kts` - Build configuration
7. `pubspec.yaml` - Dependencies

## Conclusion

The implementation successfully addresses both requirements:
1. Input box is now constrained to 3 lines maximum
2. Responses continue generating in the background with notifications on completion

The solution is minimal, leverages existing Flutter/Dart patterns, and integrates seamlessly with the existing architecture.
