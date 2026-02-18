import 'dart:async';
import 'dart:convert';
import 'package:private_chat_hub/models/queue_item.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Service for managing the message queue for offline support.
///
/// Handles queuing messages when offline, retry logic with exponential backoff,
/// and FIFO processing when connection is restored.
class MessageQueueService {
  final StorageService _storage;
  static const String _queueKey = 'message_queue';
  static const int _maxQueueSize = 50;
  static const List<int> _retryDelays = [3, 10, 30]; // seconds

  // Stream controller for queue updates
  final _queueUpdateController = StreamController<List<QueueItem>>.broadcast();

  MessageQueueService(this._storage);

  /// Stream of queue updates.
  Stream<List<QueueItem>> get queueUpdates => _queueUpdateController.stream;

  /// Gets all queued items.
  List<QueueItem> getQueue() {
    final jsonString = _storage.getString(_queueKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => QueueItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[MessageQueueService] Error loading queue: $e');
      return [];
    }
  }

  /// Gets queued items for a specific conversation.
  List<QueueItem> getConversationQueue(String conversationId) {
    return getQueue()
        .where((item) => item.conversationId == conversationId)
        .toList();
  }

  /// Gets the count of queued messages.
  int getQueueCount() {
    return getQueue().length;
  }

  /// Gets the count of queued messages for a specific conversation.
  int getConversationQueueCount(String conversationId) {
    return getConversationQueue(conversationId).length;
  }

  /// Checks if the queue is full.
  bool isQueueFull() {
    return getQueueCount() >= _maxQueueSize;
  }

  /// Adds a message to the queue.
  ///
  /// Throws [QueueFullException] if queue is at max capacity.
  Future<QueueItem> enqueue({
    required String conversationId,
    required String messageId,
  }) async {
    if (isQueueFull()) {
      throw QueueFullException(
        'Queue is full (max $_maxQueueSize messages). '
        'Please wait for connection or clear old messages.',
      );
    }

    final queueItem = QueueItem(
      id: const Uuid().v4(),
      conversationId: conversationId,
      messageId: messageId,
      queuedAt: DateTime.now(),
    );

    final queue = getQueue();
    queue.add(queueItem);
    await _saveQueue(queue);

    debugPrint(
      '[MessageQueueService] Enqueued message $messageId in conversation $conversationId',
    );

    return queueItem;
  }

  /// Removes an item from the queue.
  Future<void> dequeue(String queueItemId) async {
    final queue = getQueue();
    final updatedQueue = queue.where((item) => item.id != queueItemId).toList();
    await _saveQueue(updatedQueue);

    debugPrint('[MessageQueueService] Dequeued item $queueItemId');
  }

  /// Removes a message from the queue by message ID.
  Future<void> removeByMessageId(String messageId) async {
    final queue = getQueue();
    final updatedQueue = queue
        .where((item) => item.messageId != messageId)
        .toList();
    await _saveQueue(updatedQueue);

    debugPrint('[MessageQueueService] Removed message $messageId from queue');
  }

  /// Clears all queued items for a conversation.
  Future<void> clearConversationQueue(String conversationId) async {
    final queue = getQueue();
    final updatedQueue = queue
        .where((item) => item.conversationId != conversationId)
        .toList();
    await _saveQueue(updatedQueue);

    debugPrint(
      '[MessageQueueService] Cleared queue for conversation $conversationId',
    );
  }

  /// Clears the entire queue.
  Future<void> clearQueue() async {
    await _saveQueue([]);
    debugPrint('[MessageQueueService] Cleared entire queue');
  }

  /// Updates a queue item (for retry tracking).
  Future<void> updateQueueItem(QueueItem updatedItem) async {
    final queue = getQueue();
    final index = queue.indexWhere((item) => item.id == updatedItem.id);

    if (index != -1) {
      queue[index] = updatedItem;
      await _saveQueue(queue);
    }
  }

  /// Increments the retry count for a queue item.
  Future<QueueItem> incrementRetryCount(
    String queueItemId,
    String? errorMessage,
  ) async {
    final queue = getQueue();
    final index = queue.indexWhere((item) => item.id == queueItemId);

    if (index == -1) {
      throw Exception('Queue item not found: $queueItemId');
    }

    final updatedItem = queue[index].copyWith(
      retryCount: queue[index].retryCount + 1,
      lastRetryAt: DateTime.now(),
      errorMessage: errorMessage,
    );

    queue[index] = updatedItem;
    await _saveQueue(queue);

    return updatedItem;
  }

  /// Gets the next queue item to process (FIFO).
  QueueItem? getNextQueueItem() {
    final queue = getQueue();
    return queue.isNotEmpty ? queue.first : null;
  }

  /// Checks if a queue item has exceeded max retries.
  bool hasExceededMaxRetries(QueueItem item) {
    return item.retryCount >= _retryDelays.length;
  }

  /// Gets the delay duration for the current retry count.
  Duration getRetryDelay(int retryCount) {
    if (retryCount >= _retryDelays.length) {
      return Duration(seconds: _retryDelays.last);
    }
    return Duration(seconds: _retryDelays[retryCount]);
  }

  /// Calculates time until next retry for a queue item.
  Duration? getTimeUntilNextRetry(QueueItem item) {
    if (item.lastRetryAt == null || hasExceededMaxRetries(item)) {
      return null;
    }

    final delay = getRetryDelay(item.retryCount);
    final nextRetryTime = item.lastRetryAt!.add(delay);
    final now = DateTime.now();

    if (nextRetryTime.isBefore(now)) {
      return Duration.zero;
    }

    return nextRetryTime.difference(now);
  }

  /// Saves the queue to storage.
  Future<void> _saveQueue(List<QueueItem> queue) async {
    final jsonString = jsonEncode(queue.map((item) => item.toJson()).toList());
    await _storage.setString(_queueKey, jsonString);

    // Notify listeners of queue update
    if (!_queueUpdateController.isClosed) {
      _queueUpdateController.add(queue);
    }
  }

  /// Disposes of resources.
  void dispose() {
    _queueUpdateController.close();
  }
}

/// Helper for debug printing.
void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
