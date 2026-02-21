import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification behavior modes.
enum NotificationMode {
  /// Only notify when user is not viewing the response (default).
  smart,

  /// Always show notifications when a response completes.
  always,

  /// Never show notifications.
  never,
}

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

  // Preference key for notification mode
  static const String _notificationModeKey = 'notification_mode';

  // App lifecycle tracking
  bool _isAppInForeground = true;

  // The conversation ID the user is currently viewing (null if not in a chat)
  String? _activeConversationId;

  // Cached notification mode
  NotificationMode _notificationMode = NotificationMode.smart;

  /// Whether the app is currently in the foreground.
  bool get isAppInForeground => _isAppInForeground;

  /// Current notification mode.
  NotificationMode get notificationMode => _notificationMode;

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

    // Load notification mode preference
    await _loadNotificationMode();

    _initialized = true;
  }

  Future<void> _loadNotificationMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_notificationModeKey);
    switch (modeString) {
      case 'always':
        _notificationMode = NotificationMode.always;
        break;
      case 'never':
        _notificationMode = NotificationMode.never;
        break;
      default:
        _notificationMode = NotificationMode.smart;
    }
  }

  /// Set notification mode preference.
  Future<void> setNotificationMode(NotificationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationModeKey, mode.name);
    _notificationMode = mode;
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
  /// Respects the configured [NotificationMode]:
  /// - [NotificationMode.smart]: Only when user is not viewing the conversation.
  /// - [NotificationMode.always]: Always show.
  /// - [NotificationMode.never]: Never show.
  Future<void> showResponseCompleteNotification({
    required String conversationId,
    required String conversationTitle,
    required String responsePreview,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Check notification mode
    if (_notificationMode == NotificationMode.never) return;

    if (_notificationMode == NotificationMode.smart) {
      // Skip notification if user is currently viewing this conversation
      if (_isAppInForeground && _activeConversationId == conversationId) {
        return;
      }
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

  /// Show a custom notification triggered by the AI assistant.
  ///
  /// Used when the LLM calls the show_notification tool to alert the user.
  Future<void> showCustomNotification({
    required String title,
    required String message,
  }) async {
    if (!_initialized) await initialize();

    // Get or assign a notification id using the same counter
    final notificationId = _nextNotificationId++;

    // Truncate message if too long
    final preview = message.length > _maxPreviewLength
        ? '${message.substring(0, _maxPreviewLength)}...'
        : message;

    const androidDetails = AndroidNotificationDetails(
      'llm_alerts',
      'AI Alerts',
      channelDescription: 'Notifications triggered by the AI assistant',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      notificationId,
      title,
      preview,
      notificationDetails,
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

  // Dedicated notification id for the active-streaming foreground notification.
  static const int _streamingNotificationId = 9999;

  /// Show a persistent foreground notification while an AI response is
  /// streaming. This starts a real Android foreground service so the OS keeps
  /// the process and its network connections alive when the app is backgrounded.
  Future<void> showStreamingNotification({
    required String conversationTitle,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'ai_streaming',
      'AI Streaming',
      channelDescription: 'Keeps AI response streaming alive in the background',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      playSound: false,
      enableVibration: false,
      showWhen: false,
    );

    // startForegroundService() launches a real Android ForegroundService,
    // which prevents the OS from killing the process (and its sockets) when
    // the user switches to another app.
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.startForegroundService(
        _streamingNotificationId,
        'AI is thinking…',
        conversationTitle,
        notificationDetails: androidDetails,
        foregroundServiceTypes: <AndroidServiceForegroundType>{
          AndroidServiceForegroundType.foregroundServiceTypeDataSync,
        },
      );
    }
  }

  /// Stop the foreground service and dismiss its notification.
  Future<void> cancelStreamingNotification() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.stopForegroundService();
    } else {
      await _notifications.cancel(_streamingNotificationId);
    }
  }
}
