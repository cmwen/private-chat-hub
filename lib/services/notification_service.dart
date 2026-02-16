import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing local notifications in the app.
///
/// Handles notification setup, display, and interaction for background tasks.
/// Only shows notifications when the app is in the background or the
/// user is not currently viewing the conversation that completed.
class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _conversationIdFromNotification;

  // Map conversation IDs to unique notification IDs
  final Map<String, int> _conversationNotificationIds = {};
  int _nextNotificationId = 1;

  // Maximum length for notification preview text
  static const int _maxPreviewLength = 100;

  // App lifecycle tracking
  bool _isAppInForeground = true;

  // The conversation ID the user is currently viewing (null if not in a chat)
  String? _activeConversationId;

  /// Whether the app is currently in the foreground.
  bool get isAppInForeground => _isAppInForeground;

  /// Set the conversation ID the user is currently viewing.
  void setActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
  }

  /// Get the currently active conversation ID.
  String? get activeConversationId => _activeConversationId;

  /// Gets the conversation ID if the app was opened from a notification.
  String? get conversationIdFromNotification => _conversationIdFromNotification;

  /// Clears the notification conversation ID after it's been handled.
  void clearNotificationConversationId() {
    _conversationIdFromNotification = null;
  }

  /// Initialize the notification service.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    _initialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
  }

  /// Handle notification tap events.
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      _conversationIdFromNotification = response.payload;
    }
  }

  /// Request notification permissions (required for Android 13+).
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  /// Show a notification when an AI response is complete.
  ///
  /// Only shows the notification if the app is in the background or the user
  /// is not currently viewing the conversation that completed.
  Future<void> showResponseCompleteNotification({
    required String conversationId,
    required String conversationTitle,
    required String responsePreview,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Skip notification if user is currently viewing this conversation
    if (_isAppInForeground && _activeConversationId == conversationId) {
      return;
    }

    // Get or assign a unique notification ID for this conversation
    final notificationId = _conversationNotificationIds.putIfAbsent(
      conversationId,
      () => _nextNotificationId++,
    );

    // Truncate preview if too long
    final preview = responsePreview.length > _maxPreviewLength
        ? '${responsePreview.substring(0, _maxPreviewLength)}...'
        : responsePreview;

    const androidDetails = AndroidNotificationDetails(
      'chat_responses',
      'Chat Responses',
      channelDescription: 'Notifications for completed AI chat responses',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      notificationId,
      conversationTitle,
      preview,
      notificationDetails,
      payload: conversationId,
    );
  }

  /// Cancel a specific notification.
  Future<void> cancelNotification(String conversationId) async {
    final notificationId = _conversationNotificationIds[conversationId];
    if (notificationId != null) {
      await _notifications.cancel(notificationId);
      _conversationNotificationIds.remove(conversationId);
    }
  }

  /// Cancel all notifications.
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
