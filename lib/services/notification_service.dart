import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing local notifications in the app.
///
/// Handles notification setup, display, and interaction for background tasks.
class NotificationService {
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

  /// Gets the conversation ID if the app was opened from a notification.
  String? get conversationIdFromNotification => _conversationIdFromNotification;

  /// Clears the notification conversation ID after it's been handled.
  void clearNotificationConversationId() {
    _conversationIdFromNotification = null;
  }

  /// Initialize the notification service.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap events.
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      _conversationIdFromNotification = response.payload;
    }
  }

  /// Request notification permissions (required for Android 13+).
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    
    return false;
  }

  /// Show a notification when an AI response is complete.
  Future<void> showResponseCompleteNotification({
    required String conversationId,
    required String conversationTitle,
    required String responsePreview,
  }) async {
    if (!_initialized) {
      await initialize();
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
