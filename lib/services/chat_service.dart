import 'dart:async';
import 'dart:convert';
import 'package:private_chat_hub/models/comparison_conversation.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/queue_item.dart';
import 'package:private_chat_hub/models/tool_models.dart' as app_tools;
import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/services/connectivity_service.dart';
import 'package:private_chat_hub/services/inference_config_service.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/message_queue_service.dart';
import 'package:private_chat_hub/services/notification_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/services/on_device_llm_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:private_chat_hub/services/tool_executor_service.dart';
import 'package:private_chat_hub/services/unified_model_service.dart';
import 'package:uuid/uuid.dart';

/// Service for managing chat conversations and sending messages to Ollama using the toolkit.
///
/// This is a clean rewrite that properly integrates with the ollama_toolkit.
/// Now also supports hybrid mode with on-device inference via LiteRT-LM.
class ChatService {
  final OllamaConnectionManager _ollamaManager;
  final StorageService _storage;
  final ToolExecutorService? _toolExecutor;
  final app_tools.ToolConfig? _toolConfig;
  final OllamaConfigService _configService = OllamaConfigService();
  final NotificationService _notificationService = NotificationService();

  // Hybrid inference mode support
  InferenceConfigService? _inferenceConfigService;
  OnDeviceLLMService? _onDeviceLLMService;

  // Conversation update stream (for UI sync)
  final StreamController<Conversation> _conversationUpdatesController =
      StreamController<Conversation>.broadcast();

  // Offline mode support
  late final ConnectivityService _connectivityService;
  late final MessageQueueService _queueService;
  bool _isProcessingQueue = false;

  static const String _conversationsKey = 'conversations';
  static const String _currentConversationKey = 'current_conversation_id';
  static const bool _debugLogging = true; // Set to false to disable debug logs

  // Track active message generation streams
  final Map<String, StreamController<Conversation>> _activeStreams = {};
  final Map<String, StreamSubscription> _activeSubscriptions = {};

  /// Stream of conversation updates.
  Stream<Conversation> get conversationUpdates =>
      _conversationUpdatesController.stream;

  ChatService(
    this._ollamaManager,
    this._storage, {
    ToolExecutorService? toolExecutor,
    app_tools.ToolConfig? toolConfig,
    InferenceConfigService? inferenceConfigService,
    OnDeviceLLMService? onDeviceLLMService,
  }) : _toolExecutor = toolExecutor,
       _toolConfig = toolConfig,
       _inferenceConfigService = inferenceConfigService,
       _onDeviceLLMService = onDeviceLLMService {
    // Initialize offline mode services
    _connectivityService = ConnectivityService(_ollamaManager);
    _queueService = MessageQueueService(_storage);

    // Listen for connectivity changes and process queue when online
    _connectivityService.statusStream.listen((status) {
      if (status == OllamaConnectivityStatus.connected && !_isProcessingQueue) {
        _log('Connection restored, processing message queue');
        processMessageQueue();
      }
    });
  }

  /// Set the inference configuration service (for hybrid mode)
  void setInferenceConfigService(InferenceConfigService service) {
    _inferenceConfigService = service;
  }

  /// Set the on-device LLM service (for hybrid mode)
  void setOnDeviceLLMService(OnDeviceLLMService service) {
    _onDeviceLLMService = service;
    _log('On-device LLM service attached');
  }

  /// Get current inference mode
  InferenceMode get currentInferenceMode {
    return _inferenceConfigService?.inferenceMode ?? InferenceMode.remote;
  }

  /// Check if on-device inference is available
  Future<bool> isOnDeviceAvailable() async {
    if (_onDeviceLLMService == null) return false;
    return _onDeviceLLMService!.isAvailable();
  }

  /// Get the on-device LLM service
  OnDeviceLLMService? get onDeviceLLMService => _onDeviceLLMService;

  void _log(String message) {
    _debugLog(message);
  }

  static void _debugLog(String message) {
    if (_debugLogging) {
      // ignore: avoid_print
      print('[ChatService] $message');
    }
  }

  // ============================================================================
  // CONVERSATION MANAGEMENT
  // ============================================================================

  /// Gets all saved conversations.
  List<Conversation> getConversations({
    String? projectId,
    bool excludeProjectConversations = false,
  }) {
    final jsonString = _storage.getString(_conversationsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      var conversations = jsonList.map((json) {
        final jsonMap = json as Map<String, dynamic>;
        if (jsonMap['isComparisonMode'] == true) {
          return ComparisonConversation.fromJson(jsonMap);
        }
        return Conversation.fromJson(jsonMap);
      }).toList();

      if (projectId != null) {
        conversations = conversations
            .where((c) => c.projectId == projectId)
            .toList();
      } else if (excludeProjectConversations) {
        conversations = conversations
            .where((c) => c.projectId == null)
            .toList();
      }

      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    } catch (e) {
      return [];
    }
  }

  /// Gets conversations for a specific project.
  List<Conversation> getProjectConversations(String projectId) {
    return getConversations(projectId: projectId);
  }

  /// Gets the count of conversations in a project.
  int getProjectConversationCount(String projectId) {
    return getProjectConversations(projectId).length;
  }

  /// Saves conversations to storage.
  Future<void> _saveConversations(List<Conversation> conversations) async {
    final jsonString = jsonEncode(
      conversations.map((c) => c.toJson()).toList(),
    );
    await _storage.setString(_conversationsKey, jsonString);
  }

  /// Creates a new conversation.
  Future<Conversation> createConversation({
    required String modelName,
    String? title,
    String? systemPrompt,
    String? projectId,
  }) async {
    final conversation = Conversation(
      id: const Uuid().v4(),
      title: title ?? 'New Conversation',
      modelName: modelName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      systemPrompt: systemPrompt,
      projectId: projectId,
    );

    final conversations = getConversations();
    conversations.insert(0, conversation);
    await _saveConversations(conversations);
    await setCurrentConversation(conversation.id);

    return conversation;
  }

  /// Creates a new comparison conversation.
  Future<ComparisonConversation> createComparisonConversation({
    required String model1Name,
    required String model2Name,
    String? title,
    String? systemPrompt,
  }) async {
    final conversation = ComparisonConversation(
      id: const Uuid().v4(),
      title: title ?? 'Compare: $model1Name vs $model2Name',
      modelName: model1Name,
      model2Name: model2Name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      systemPrompt: systemPrompt,
    );

    final conversations = getConversations();
    conversations.insert(0, conversation);
    await _saveConversations(conversations);
    await setCurrentConversation(conversation.id);

    return conversation;
  }

  /// Gets a conversation by ID.
  Conversation? getConversation(String id) {
    final conversations = getConversations();
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Updates a conversation.
  Future<void> updateConversation(Conversation conversation) async {
    final conversations = getConversations();
    final index = conversations.indexWhere((c) => c.id == conversation.id);

    if (index != -1) {
      conversations[index] = conversation;
      await _saveConversations(conversations);

      if (!_conversationUpdatesController.isClosed) {
        _conversationUpdatesController.add(conversation);
      }
    }
  }

  /// Deletes a conversation.
  Future<void> deleteConversation(String id) async {
    final conversations = getConversations();
    final updatedConversations = conversations
        .where((c) => c.id != id)
        .toList();
    await _saveConversations(updatedConversations);

    if (getCurrentConversationId() == id) {
      await _storage.remove(_currentConversationKey);
    }
  }

  /// Deletes all conversations in a project.
  Future<void> deleteProjectConversations(String projectId) async {
    final conversations = getConversations();
    final updatedConversations = conversations
        .where((c) => c.projectId != projectId)
        .toList();
    await _saveConversations(updatedConversations);
  }

  /// Moves a conversation to a project.
  Future<void> moveConversationToProject(
    String conversationId,
    String? projectId,
  ) async {
    final conversations = getConversations();
    final index = conversations.indexWhere((c) => c.id == conversationId);

    if (index != -1) {
      conversations[index] = conversations[index].copyWith(
        projectId: projectId,
        clearProjectId: projectId == null,
        updatedAt: DateTime.now(),
      );
      await _saveConversations(conversations);
    }
  }

  /// Clears all messages in a conversation but keeps the conversation.
  Future<void> clearConversation(String id) async {
    final conversation = getConversation(id);
    if (conversation != null) {
      final clearedConversation = conversation.copyWith(
        messages: [],
        updatedAt: DateTime.now(),
      );
      await updateConversation(clearedConversation);
    }
  }

  /// Gets the current conversation ID.
  String? getCurrentConversationId() {
    return _storage.getString(_currentConversationKey);
  }

  /// Sets the current conversation.
  Future<void> setCurrentConversation(String id) async {
    await _storage.setString(_currentConversationKey, id);
  }

  /// Gets the current conversation.
  Conversation? getCurrentConversation() {
    final id = getCurrentConversationId();
    if (id == null) return null;
    return getConversation(id);
  }

  /// Deletes all conversations.
  Future<void> deleteAllConversations() async {
    await _storage.remove(_conversationsKey);
    await _storage.remove(_currentConversationKey);
  }

  // ============================================================================
  // MESSAGE MANAGEMENT
  // ============================================================================

  /// Adds a message to a conversation.
  Future<Conversation> addMessage(
    String conversationId,
    Message message,
  ) async {
    var conversation = getConversation(conversationId);
    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    conversation = conversation.addMessage(message);

    // Update title from first user message if still default
    if (conversation.title == 'New Conversation' &&
        message.role == MessageRole.user) {
      conversation = conversation.copyWith(
        title: Conversation.generateTitle(message.text),
      );
    }

    await updateConversation(conversation);
    return conversation;
  }

  /// Deletes a message from a conversation.
  Future<Conversation?> deleteMessage(
    String conversationId,
    String messageId,
  ) async {
    var conversation = getConversation(conversationId);
    if (conversation == null) {
      return null;
    }

    final updatedMessages = conversation.messages
        .where((m) => m.id != messageId)
        .toList();

    conversation = conversation.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    await updateConversation(conversation);
    return conversation;
  }

  // ============================================================================
  // MESSAGE QUEUE MANAGEMENT (OFFLINE MODE)
  // ============================================================================

  /// Gets the connectivity service.
  ConnectivityService get connectivityService => _connectivityService;

  /// Gets the message queue service.
  MessageQueueService get queueService => _queueService;

  /// Whether the service is currently online.
  bool get isOnline => _connectivityService.isOnline;

  /// Whether the service is currently offline.
  bool get isOffline => _connectivityService.isOffline;

  /// Gets the count of queued messages for a conversation.
  int getQueuedMessageCount(String conversationId) {
    return _queueService.getConversationQueueCount(conversationId);
  }

  /// Gets all queued messages for a conversation.
  List<QueueItem> getQueuedMessages(String conversationId) {
    return _queueService.getConversationQueue(conversationId);
  }

  /// Queues a message to be sent when connection is restored.
  Future<Conversation> queueMessage(String conversationId, String text) async {
    _log('Queueing message for conversation $conversationId (offline mode)');

    // Add user message with queued status
    final userMessage = Message.user(
      id: const Uuid().v4(),
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.queued,
      queuedAt: DateTime.now(),
    );

    var conversation = await addMessage(conversationId, userMessage);

    // Add to queue
    try {
      await _queueService.enqueue(
        conversationId: conversationId,
        messageId: userMessage.id,
      );
      _log('Message queued successfully: ${userMessage.id}');
    } catch (e) {
      _log('Failed to queue message: $e');
      // Update message status to failed
      final failedMessage = userMessage.copyWith(status: MessageStatus.failed);
      final messages = conversation.messages.map((m) {
        return m.id == userMessage.id ? failedMessage : m;
      }).toList();
      conversation = conversation.copyWith(messages: messages);
      await updateConversation(conversation);
      rethrow;
    }

    return conversation;
  }

  /// Cancels a queued message.
  Future<void> cancelQueuedMessage(String messageId) async {
    _log('Cancelling queued message: $messageId');
    await _queueService.removeByMessageId(messageId);

    // Find and remove the message from its conversation
    final conversations = getConversations();
    for (final conversation in conversations) {
      final message = conversation.messages
          .where((m) => m.id == messageId)
          .firstOrNull;
      if (message != null) {
        await deleteMessage(conversation.id, messageId);
        break;
      }
    }
  }

  /// Retries a failed message.
  Future<void> retryFailedMessage(String messageId) async {
    _log('Retrying failed message: $messageId');

    // Find the message
    final conversations = getConversations();
    Conversation? targetConversation;
    Message? targetMessage;

    for (final conversation in conversations) {
      final message = conversation.messages
          .where((m) => m.id == messageId)
          .firstOrNull;
      if (message != null) {
        targetConversation = conversation;
        targetMessage = message;
        break;
      }
    }

    if (targetConversation == null || targetMessage == null) {
      throw Exception('Message not found: $messageId');
    }

    // Check if online
    if (isOnline) {
      // Update message status to sending
      final messages = targetConversation.messages.map((m) {
        return m.id == messageId
            ? m.copyWith(status: MessageStatus.sending)
            : m;
      }).toList();
      var conversation = targetConversation.copyWith(messages: messages);
      await updateConversation(conversation);

      // Try to send immediately
      try {
        await _sendQueuedMessageSync(targetConversation.id, targetMessage);
      } catch (e) {
        _log('Retry failed: $e');
        // Mark as failed again
        final failedMessages = conversation.messages.map((m) {
          return m.id == messageId
              ? m.copyWith(status: MessageStatus.failed)
              : m;
        }).toList();
        conversation = conversation.copyWith(messages: failedMessages);
        await updateConversation(conversation);
      }
    } else {
      // Re-queue the message
      await _queueService.enqueue(
        conversationId: targetConversation.id,
        messageId: messageId,
      );

      // Update message status to queued
      final messages = targetConversation.messages.map((m) {
        return m.id == messageId
            ? m.copyWith(status: MessageStatus.queued, queuedAt: DateTime.now())
            : m;
      }).toList();
      final conversation = targetConversation.copyWith(messages: messages);
      await updateConversation(conversation);
    }
  }

  /// Processes the message queue (sends all queued messages).
  Future<void> processMessageQueue() async {
    if (_isProcessingQueue) {
      _log('Queue processing already in progress');
      return;
    }

    if (!isOnline) {
      _log('Cannot process queue while offline');
      return;
    }

    _isProcessingQueue = true;
    _log('Starting queue processing');

    try {
      while (true) {
        final queueItem = _queueService.getNextQueueItem();
        if (queueItem == null) {
          _log('Queue is empty');
          break;
        }

        _log('Processing queue item: ${queueItem.id}');

        // Check if max retries exceeded
        if (_queueService.hasExceededMaxRetries(queueItem)) {
          _log(
            'Max retries exceeded for ${queueItem.messageId}, marking as failed',
          );
          await _markMessageAsFailed(
            queueItem.conversationId,
            queueItem.messageId,
          );
          await _queueService.dequeue(queueItem.id);
          continue;
        }

        // Apply retry delay if needed
        if (queueItem.retryCount > 0) {
          final delay = _queueService.getRetryDelay(queueItem.retryCount);
          _log(
            'Waiting ${delay.inSeconds}s before retry ${queueItem.retryCount}',
          );
          await Future.delayed(delay);
        }

        // Try to send the message
        try {
          await _processQueueItem(queueItem);
          await _queueService.dequeue(queueItem.id);
          _log('Successfully sent queued message: ${queueItem.messageId}');
        } catch (e) {
          _log('Failed to send queued message: $e');
          await _queueService.incrementRetryCount(queueItem.id, e.toString());

          // Check if we should continue or stop
          if (!isOnline) {
            _log('Lost connection during queue processing, stopping');
            break;
          }
        }
      }
    } finally {
      _isProcessingQueue = false;
      _log('Queue processing finished');
    }
  }

  /// Processes a single queue item.
  Future<void> _processQueueItem(QueueItem queueItem) async {
    final conversation = getConversation(queueItem.conversationId);
    if (conversation == null) {
      throw Exception('Conversation not found: ${queueItem.conversationId}');
    }

    final message = conversation.messages
        .where((m) => m.id == queueItem.messageId)
        .firstOrNull;
    if (message == null) {
      throw Exception('Message not found: ${queueItem.messageId}');
    }

    await _sendQueuedMessageSync(conversation.id, message);
  }

  /// Sends a queued message synchronously (no streaming for queued messages).
  Future<void> _sendQueuedMessageSync(
    String conversationId,
    Message userMessage,
  ) async {
    final conversation = getConversation(conversationId);
    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    final client = _ollamaManager.client;
    if (client == null) {
      throw Exception('No Ollama connection configured');
    }

    // Update message status to sending
    await _updateMessageStatus(
      conversationId,
      userMessage.id,
      MessageStatus.sending,
    );

    try {
      // Build message history (excluding the user message being sent and any assistant responses after it)
      final messageIndex = conversation.messages.indexWhere(
        (m) => m.id == userMessage.id,
      );
      final ollamaMessages = _buildOllamaMessageHistory(
        conversation.copyWith(
          messages: conversation.messages.sublist(0, messageIndex + 1),
        ),
      );

      // Send message (without tool calling for queued messages)
      final response = await client.chat(
        conversation.modelName,
        ollamaMessages,
        options: conversation.parameters.toOllamaOptions(),
      );

      // Update user message status to sent
      await _updateMessageStatus(
        conversationId,
        userMessage.id,
        MessageStatus.sent,
      );

      // Add assistant response
      final assistantMessage = Message.assistant(
        id: const Uuid().v4(),
        text: response.message.content,
        timestamp: DateTime.now(),
      );
      await addMessage(conversationId, assistantMessage);

      _log('Successfully sent queued message: ${userMessage.id}');
    } catch (e) {
      _log('Error sending queued message: $e');
      await _updateMessageStatus(
        conversationId,
        userMessage.id,
        MessageStatus.failed,
      );
      rethrow;
    }
  }

  /// Updates a message status.
  Future<void> _updateMessageStatus(
    String conversationId,
    String messageId,
    MessageStatus status,
  ) async {
    var conversation = getConversation(conversationId);
    if (conversation == null) return;

    final messages = conversation.messages.map((m) {
      return m.id == messageId ? m.copyWith(status: status) : m;
    }).toList();

    conversation = conversation.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    await updateConversation(conversation);
  }

  /// Marks a message as failed.
  Future<void> _markMessageAsFailed(
    String conversationId,
    String messageId,
  ) async {
    await _updateMessageStatus(conversationId, messageId, MessageStatus.failed);
  }

  // ============================================================================
  // CHAT GENERATION - SINGLE MODEL
  // ============================================================================

  /// Sends a message and gets a streaming response from Ollama.
  ///
  /// Returns a stream of updated conversations as the response streams in.
  /// If offline and on-device models available, automatically uses local inference.
  /// Otherwise queues the message.
  /// Supports hybrid mode: uses on-device inference when mode is set to onDevice or as fallback.
  /// Also detects local models by prefix and routes to on-device inference automatically.
  Stream<Conversation> sendMessage(String conversationId, String text) async* {
    await cancelMessageGeneration(conversationId);

    final initialConversation = getConversation(conversationId);
    if (initialConversation == null) {
      throw Exception('Conversation not found');
    }

    // Check if model is a local model (has local: prefix)
    final isLocalModel = UnifiedModelService.isLocalModel(
      initialConversation.modelName,
    );

    _log(
      'Routing decision: model=${initialConversation.modelName}, '
      'isLocalModel=$isLocalModel, '
      'inferenceMode=$currentInferenceMode, '
      'onDeviceServiceReady=${_onDeviceLLMService != null}, '
      'isOnline=$isOnline',
    );

    if (isLocalModel && _onDeviceLLMService == null) {
      _log(
        'Local model selected but on-device service is not ready; aborting instead of falling back to remote model path.',
      );
      throw Exception(
        'On-device service is still initializing. Please wait a few seconds and try again.',
      );
    }

    // Route to on-device if local model is selected
    if (isLocalModel && _onDeviceLLMService != null) {
      _log('Using on-device inference (local model selected)');
      yield* _sendMessageOnDevice(conversationId, text);
      return;
    }

    // Check inference mode - route to on-device if explicitly enabled
    if (currentInferenceMode == InferenceMode.onDevice &&
        _onDeviceLLMService != null) {
      _log('Using on-device inference mode (explicitly enabled)');
      yield* _sendMessageOnDevice(conversationId, text);
      return;
    }

    // Check if offline - try on-device fallback before queueing
    if (!isOnline) {
      // Check if on-device inference is available as fallback
      if (_onDeviceLLMService != null && await isOnDeviceAvailable()) {
        _log('Ollama offline: falling back to on-device inference');
        yield* _sendMessageOnDevice(conversationId, text);
        return;
      }

      // No on-device fallback available - queue the message
      _log('Offline mode: queueing message (no on-device models available)');
      final conversation = await queueMessage(conversationId, text);
      yield conversation;
      return;
    }

    // Add user message
    final userMessage = Message.user(
      id: const Uuid().v4(),
      text: text,
      timestamp: DateTime.now(),
    );
    var conversation = await addMessage(conversationId, userMessage);

    // Create stream controller
    final streamController = StreamController<Conversation>.broadcast();
    _activeStreams[conversationId] = streamController;

    streamController.add(conversation);
    yield conversation;

    // Create placeholder assistant message
    final assistantMessageId = const Uuid().v4();
    var assistantMessage = Message.assistant(
      id: assistantMessageId,
      text: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    conversation = await addMessage(conversationId, assistantMessage);
    streamController.add(conversation);
    yield conversation;

    // Start generation in background
    _generateSingleModelMessage(
      conversationId,
      conversation,
      assistantMessageId,
      streamController,
    );

    // Yield updates from the stream
    await for (final updatedConversation in streamController.stream) {
      yield updatedConversation;
    }
  }

  /// Sends a message using on-device inference via LiteRT-LM
  Stream<Conversation> _sendMessageOnDevice(
    String conversationId,
    String text, {
    bool addUserMessage = true,
  }) async* {
    final initialConversation = getConversation(conversationId);
    if (initialConversation == null) {
      throw Exception('Conversation not found');
    }

    // Check if on-device service is available
    if (_onDeviceLLMService == null) {
      throw Exception('On-device inference not configured');
    }

    final isAvailable = await _onDeviceLLMService!.isAvailable();
    _log(
      'On-device availability check: isAvailable=$isAvailable, '
      'conversationModel=${initialConversation.modelName}',
    );
    if (!isAvailable) {
      String reason = 'On-device inference not available on this device';
      try {
        final readiness = await _onDeviceLLMService!.getReadinessReport();
        final unsupportedReasons =
            (readiness['unsupportedReasons'] as List<dynamic>? ?? [])
                .whereType<String>()
                .toList();
        if (unsupportedReasons.isNotEmpty) {
          reason = unsupportedReasons.first;
        }

        _log(
          'On-device readiness details: isSupported=${readiness['isSupported']}, '
          'unsupportedReasons=$unsupportedReasons, '
          'warnings=${readiness['warnings']}',
        );
      } catch (e) {
        _log('Failed to fetch readiness report: $e');
      }

      throw Exception(
        'On-device inference not available on this device: $reason',
      );
    }

    var conversation = initialConversation;

    if (addUserMessage) {
      // Add user message for direct send flow.
      final userMessage = Message.user(
        id: const Uuid().v4(),
        text: text,
        timestamp: DateTime.now(),
      );
      conversation = await addMessage(conversationId, userMessage);
    }

    // Create stream controller
    final streamController = StreamController<Conversation>.broadcast();
    _activeStreams[conversationId] = streamController;

    streamController.add(conversation);
    yield conversation;

    // Create placeholder assistant message
    final assistantMessageId = const Uuid().v4();
    var assistantMessage = Message.assistant(
      id: assistantMessageId,
      text: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    conversation = await addMessage(conversationId, assistantMessage);
    streamController.add(conversation);
    yield conversation;

    // Get the on-device model to use
    // If conversation has local: prefix, extract the actual model ID
    String onDeviceModelId;
    if (UnifiedModelService.isLocalModel(initialConversation.modelName)) {
      onDeviceModelId = UnifiedModelService.getLocalModelId(
        initialConversation.modelName,
      );
      _log('Using local model from conversation: $onDeviceModelId');
    } else {
      onDeviceModelId =
          _inferenceConfigService?.lastOnDeviceModel ?? 'gemma3-1b';
      _log('Using default on-device model: $onDeviceModelId');
    }

    // Build conversation history (exclude the placeholder assistant message)
    final conversationHistory = conversation.messages
        .where((m) => m.id != assistantMessageId && !m.isError)
        .toList();

    // Start on-device generation in background so stream subscribers
    // receive token updates in real time.
    () async {
      try {
        final buffer = StringBuffer();
        var chunkCount = 0;
        final generationStartedAt = DateTime.now();

        _log(
          'Starting on-device streaming generation: model=$onDeviceModelId, '
          'promptLength=${text.length}, historyCount=${conversationHistory.length}',
        );

        await for (final token in _onDeviceLLMService!.generateResponse(
          prompt: text,
          modelId: onDeviceModelId,
          conversationHistory: conversationHistory,
          systemPrompt: conversation.systemPrompt,
          temperature: conversation.parameters.temperature,
          maxTokens: conversation.parameters.maxTokens,
        )) {
          if (streamController.isClosed) break;

          chunkCount++;
          buffer.write(token);

          if (chunkCount == 1 || chunkCount % 25 == 0) {
            _log(
              'On-device stream progress: chunks=$chunkCount, accumulatedChars=${buffer.length}',
            );
          }

          conversation = await _updateAssistantMessage(
            conversation,
            assistantMessageId,
            buffer.toString(),
            isStreaming: true,
          );

          if (!streamController.isClosed) {
            streamController.add(conversation);
          }
        }

        final finalText = buffer.toString();
        final elapsedMs = DateTime.now()
            .difference(generationStartedAt)
            .inMilliseconds;
        _log(
          'On-device stream completed: chunks=$chunkCount, chars=${finalText.length}, elapsedMs=$elapsedMs',
        );

        if (finalText.trim().isEmpty) {
          _handleError(
            conversationId,
            conversation,
            assistantMessageId,
            streamController,
            'On-device model returned an empty response. Try again or switch model/backend.',
          );
          return;
        }

        // Finalize the message
        conversation = await _updateAssistantMessage(
          conversation,
          assistantMessageId,
          finalText,
          isStreaming: false,
        );

        if (!streamController.isClosed) {
          streamController.add(conversation);
          await streamController.close();
        }

        // Show notification
        await _showResponseCompleteNotification(conversation, finalText);

        // Update last used on-device model
        await _inferenceConfigService?.setLastOnDeviceModel(onDeviceModelId);
      } catch (e) {
        _log('On-device generation error: $e');
        _handleError(
          conversationId,
          conversation,
          assistantMessageId,
          streamController,
          'On-device inference error: ${e.toString()}',
        );
      } finally {
        _cleanupStream(conversationId);
      }
    }();

    // Yield updates as they arrive
    await for (final updatedConversation in streamController.stream) {
      yield updatedConversation;
    }
  }

  /// Streams a response for the current conversation context.
  ///
  /// Used when messages (with attachments) have already been added.
  Stream<Conversation> sendMessageWithContext(String conversationId) async* {
    await cancelMessageGeneration(conversationId);

    final initialConversation = getConversation(conversationId);
    if (initialConversation == null) {
      throw Exception('Conversation not found');
    }

    var conversation = initialConversation;

    final isLocalModel = UnifiedModelService.isLocalModel(
      initialConversation.modelName,
    );
    _log(
      'sendMessageWithContext routing: model=${initialConversation.modelName}, '
      'isLocalModel=$isLocalModel, '
      'inferenceMode=$currentInferenceMode, '
      'onDeviceServiceReady=${_onDeviceLLMService != null}, '
      'isOnline=$isOnline',
    );

    String lastUserText(Conversation c) {
      for (final message in c.messages.reversed) {
        if (message.role == MessageRole.user) return message.text;
      }
      return '';
    }

    if (isLocalModel) {
      if (_onDeviceLLMService == null) {
        _log(
          'Local model selected in sendMessageWithContext but on-device service is null',
        );
        throw Exception(
          'On-device service is still initializing. Please wait a few seconds and try again.',
        );
      }

      _log(
        'Routing sendMessageWithContext to on-device inference (local model selected)',
      );
      yield* _sendMessageOnDevice(
        conversationId,
        lastUserText(conversation),
        addUserMessage: false,
      );
      return;
    }

    if (currentInferenceMode == InferenceMode.onDevice &&
        _onDeviceLLMService != null) {
      _log(
        'Routing sendMessageWithContext to on-device inference (onDevice mode enabled)',
      );
      yield* _sendMessageOnDevice(
        conversationId,
        lastUserText(conversation),
        addUserMessage: false,
      );
      return;
    }

    // If not online, queue the last user message and return
    if (!isOnline) {
      final lastUserMessage = conversation.messages.lastWhere(
        (m) => m.role == MessageRole.user,
        orElse: () => Message.user(id: '', text: '', timestamp: DateTime.now()),
      );

      if (lastUserMessage.id.isNotEmpty) {
        conversation = await _queueExistingMessage(
          conversationId,
          lastUserMessage.id,
        );
      }

      yield conversation;
      return;
    }

    final streamController = StreamController<Conversation>.broadcast();
    _activeStreams[conversationId] = streamController;

    final assistantMessageId = const Uuid().v4();
    var assistantMessage = Message.assistant(
      id: assistantMessageId,
      text: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    conversation = await addMessage(conversationId, assistantMessage);
    streamController.add(conversation);
    yield conversation;

    _generateSingleModelMessage(
      conversationId,
      conversation,
      assistantMessageId,
      streamController,
    );

    await for (final updatedConversation in streamController.stream) {
      yield updatedConversation;
    }
  }

  /// Internal: generates a message from a single model.
  Future<void> _generateSingleModelMessage(
    String conversationId,
    Conversation conversation,
    String assistantMessageId,
    StreamController<Conversation> streamController,
  ) async {
    final client = _ollamaManager.client;
    if (client == null) {
      _handleError(
        conversationId,
        conversation,
        assistantMessageId,
        streamController,
        'No Ollama connection configured',
      );
      return;
    }

    // Check model capabilities
    final modelCapabilities = conversation.modelCapabilities;
    final supportsTools = modelCapabilities.supportsTools;
    final toolCallingEnabled = conversation.toolCallingEnabled;

    // Debug logging
    _log('Starting message generation for model: ${conversation.modelName}');
    _log(
      'Model capabilities: tools=$supportsTools, vision=${modelCapabilities.supportsVision}',
    );
    _log('Tool calling enabled: $toolCallingEnabled');
    _log('Tool executor available: ${_toolExecutor != null}');

    try {
      // If model supports tools, user has enabled them, and we have a tool executor, use agent-based approach
      if (supportsTools && toolCallingEnabled && _toolExecutor != null) {
        _log('Using agent-based approach with tools');
        await _generateWithTools(
          conversationId,
          conversation,
          assistantMessageId,
          streamController,
          client,
        );
      } else {
        _log('Using simple chat approach without tools');
        // Use simple chat without tools
        await _generateSimpleChat(
          conversationId,
          conversation,
          assistantMessageId,
          streamController,
          client,
        );
      }
    } catch (e) {
      _log('Error during message generation: $e');
      _handleError(
        conversationId,
        conversation,
        assistantMessageId,
        streamController,
        e.toString(),
      );
    }
  }

  /// Generates response using simple chat without tools.
  Future<void> _generateSimpleChat(
    String conversationId,
    Conversation conversation,
    String assistantMessageId,
    StreamController<Conversation> streamController,
    OllamaClient client,
  ) async {
    // Build message history for Ollama
    final ollamaMessages = _buildOllamaMessageHistory(
      conversation,
      excludeMessageId: assistantMessageId,
    );

    // Check streaming preference
    final streamingEnabled = await _configService.getStreamEnabled();

    if (streamingEnabled) {
      // Stream the response
      final buffer = StringBuffer();
      final subscription = client
          .chatStream(
            conversation.modelName,
            ollamaMessages,
            options: conversation.parameters.toOllamaOptions(),
          )
          .listen(
            (response) async {
              if (streamController.isClosed) return;

              final content = response.message.content;
              if (content.isNotEmpty) {
                buffer.write(content);
              }

              conversation = await _updateAssistantMessage(
                conversation,
                assistantMessageId,
                buffer.toString(),
                isStreaming: true,
              );

              if (!streamController.isClosed) {
                streamController.add(conversation);
              }
            },
            onError: (error) {
              _handleError(
                conversationId,
                conversation,
                assistantMessageId,
                streamController,
                error.toString(),
              );
            },
            onDone: () async {
              if (streamController.isClosed) return;

              conversation = await _updateAssistantMessage(
                conversation,
                assistantMessageId,
                buffer.toString(),
                isStreaming: false,
              );

              if (!streamController.isClosed) {
                streamController.add(conversation);
                streamController.close();
              }

              _activeSubscriptions.remove(conversationId);

              // Show notification when response completes
              await _showResponseCompleteNotification(
                conversation,
                buffer.toString(),
              );
            },
          );

      _activeSubscriptions[conversationId] = subscription;
    } else {
      // Non-streaming mode: get complete response at once
      try {
        final response = await client.chat(
          conversation.modelName,
          ollamaMessages,
          options: conversation.parameters.toOllamaOptions(),
        );

        if (streamController.isClosed) return;

        conversation = await _updateAssistantMessage(
          conversation,
          assistantMessageId,
          response.message.content,
          isStreaming: false,
        );

        if (!streamController.isClosed) {
          streamController.add(conversation);
          streamController.close();
        }

        _activeSubscriptions.remove(conversationId);

        // Show notification when response completes
        await _showResponseCompleteNotification(
          conversation,
          response.message.content,
        );
      } catch (error) {
        _handleError(
          conversationId,
          conversation,
          assistantMessageId,
          streamController,
          error.toString(),
        );
      }
    }
  }

  /// Generates response using agent with tool calling support.
  Future<void> _generateWithTools(
    String conversationId,
    Conversation conversation,
    String assistantMessageId,
    StreamController<Conversation> streamController,
    OllamaClient client,
  ) async {
    _log('Starting agent-based generation for _generateWithTools');

    // Check streaming preference - apply to tool calling as well
    final streamingEnabled = await _configService.getStreamEnabled();
    _log('Streaming enabled for tool calling: $streamingEnabled');

    // Create an agent for this conversation
    final systemPromptWithInstructions = _buildAgentSystemPrompt(
      conversation.systemPrompt,
    );
    final maxIterations = _toolConfig?.maxToolCalls ?? 15;
    final agent = OllamaAgent(
      client: client,
      model: conversation.modelName,
      systemPrompt: systemPromptWithInstructions,
      maxIterations: maxIterations,
    );

    // Get available tools
    final executor = _toolExecutor!;
    final tools = executor.getAvailableTools().map((tool) {
      return _OllamaToolWrapper(tool, executor);
    }).toList();

    _log('Available tools: ${tools.map((t) => t.name).toList()}');

    // Get the last user message as input
    final userMessages = conversation.messages
        .where((m) => m.role == MessageRole.user)
        .toList();
    if (userMessages.isEmpty) {
      throw Exception('No user message found');
    }
    final lastUserMessage = userMessages.last;

    // Run agent with tools
    final List<app_tools.ToolCall> toolCalls = [];
    var responseText = StringBuffer();

    try {
      _log('Running agent.runWithTools for model: ${conversation.modelName}');

      // Show initial status
      conversation = await _updateStatusMessage(
        conversation,
        assistantMessageId,
        '🔄 Starting tool execution...',
      );
      if (!streamController.isClosed) {
        streamController.add(conversation);
      }

      final result = await agent.runWithTools(lastUserMessage.text, tools);

      _log('Agent completed with ${result.steps.length} steps');

      // Check if agent failed (e.g., max iterations reached)
      if (!result.success && result.error != null) {
        _log('Agent failed: ${result.error}');
        // Throw error to trigger error message display
        throw Exception(result.error);
      }

      // Collect tool calls from agent steps and update status
      for (final step in result.steps) {
        _log('Step: type=${step.type}, tool=${step.toolName}');

        // Update status for tool calls
        if (step.type == 'tool_call' && step.toolName != null) {
          final toolDisplayName = _getToolDisplayName(step.toolName!);
          conversation = await _updateStatusMessage(
            conversation,
            assistantMessageId,
            '⚙️ Executing $toolDisplayName...',
          );
          if (!streamController.isClosed) {
            streamController.add(conversation);
          }

          final toolCall = app_tools.ToolCall(
            id: const Uuid().v4(),
            toolName: step.toolName!,
            arguments: step.toolArgs ?? {},
            status: app_tools.ToolCallStatus.success,
            createdAt: step.timestamp,
          );
          toolCalls.add(toolCall);
          _log('Added tool call: ${step.toolName}');
        }
      }

      // Clear status message before final response
      conversation = await _updateStatusMessage(
        conversation,
        assistantMessageId,
        null,
      );

      responseText.write(result.response);
      _log('Final response length: ${result.response.length}');
    } catch (e) {
      _log('Error during agent execution: $e');
      // Re-throw to use the error handling mechanism
      _handleError(
        conversationId,
        conversation,
        assistantMessageId,
        streamController,
        e.toString(),
      );
      return;
    }

    // Update message with final response and tool calls
    // Note: Agent execution completes before we can stream, so isStreaming is always false
    // But we respect the streaming preference for consistency
    conversation = await _updateAssistantMessage(
      conversation,
      assistantMessageId,
      responseText.toString(),
      isStreaming:
          false, // Agent runs to completion, can't stream intermediate states
      toolCalls: toolCalls,
    );

    if (!streamController.isClosed) {
      streamController.add(conversation);
      streamController.close();
    }

    _activeSubscriptions.remove(conversationId);

    // Show notification when response completes
    await _showResponseCompleteNotification(
      conversation,
      responseText.toString(),
    );
  }

  // ============================================================================
  // CHAT GENERATION - DUAL MODEL (COMPARISON)
  // ============================================================================

  /// Sends a message to two models simultaneously for comparison.
  Stream<ComparisonConversation> sendDualModelMessage(
    String conversationId,
    String text, {
    List<Attachment>? attachments,
  }) async* {
    await cancelMessageGeneration(conversationId);

    final initialConversation = getConversation(conversationId);
    if (initialConversation == null) {
      throw Exception('Conversation not found');
    }
    if (initialConversation is! ComparisonConversation) {
      throw Exception('Not a comparison conversation');
    }

    ComparisonConversation conversation = initialConversation;

    // Add user message
    final userMessage = Message.user(
      id: const Uuid().v4(),
      text: text,
      timestamp: DateTime.now(),
      modelSource: ModelSource.user,
      attachments: attachments,
    );
    conversation =
        (await addMessage(conversationId, userMessage))
            as ComparisonConversation;

    final streamController =
        StreamController<ComparisonConversation>.broadcast();
    _activeStreams[conversationId] =
        streamController as StreamController<Conversation>;

    streamController.add(conversation);
    yield conversation;

    // Create placeholders for both models
    final model1MessageId = const Uuid().v4();
    final model2MessageId = const Uuid().v4();

    var model1Message = Message.assistant(
      id: model1MessageId,
      text: '',
      timestamp: DateTime.now(),
      isStreaming: true,
      modelSource: ModelSource.model1,
    );

    var model2Message = Message.assistant(
      id: model2MessageId,
      text: '',
      timestamp: DateTime.now(),
      isStreaming: true,
      modelSource: ModelSource.model2,
    );

    conversation =
        (await addMessage(conversationId, model1Message))
            as ComparisonConversation;
    conversation =
        (await addMessage(conversationId, model2Message))
            as ComparisonConversation;

    streamController.add(conversation);
    yield conversation;

    // Start both generations
    _generateDualModelMessages(
      conversationId,
      conversation,
      model1MessageId,
      model2MessageId,
      streamController,
    );

    await for (final updatedConversation in streamController.stream) {
      yield updatedConversation;
    }
  }

  /// Internal: generates messages from both models in parallel.
  Future<void> _generateDualModelMessages(
    String conversationId,
    ComparisonConversation conversation,
    String model1MessageId,
    String model2MessageId,
    StreamController<ComparisonConversation> streamController,
  ) async {
    final client = _ollamaManager.client;
    if (client == null) {
      streamController.addError('No Ollama connection configured');
      _cleanupStream(conversationId);
      await streamController.close();
      return;
    }

    // Check streaming preference
    final streamingEnabled = await _configService.getStreamEnabled();

    bool model1Done = false;
    bool model2Done = false;

    final ollamaMessages = _buildOllamaMessageHistory(
      conversation,
      excludeMessageId: model1MessageId,
      excludeMessageId2: model2MessageId,
      includeModel1Only: true,
    );

    Future<void> updateConversationSafely(Message updatedMessage) async {
      if (streamController.isClosed) return;

      final messages = conversation.messages.map((m) {
        if (m.id == updatedMessage.id) return updatedMessage;
        return m;
      }).toList();

      conversation = conversation.copyWith(
        messages: messages,
        updatedAt: DateTime.now(),
      );
      await updateConversation(conversation);

      if (!streamController.isClosed) {
        streamController.add(conversation);
      }
    }

    if (streamingEnabled) {
      // Streaming mode - original implementation
      // Model 1 stream
      final buffer1 = StringBuffer();
      final subscription1 = client
          .chatStream(
            conversation.model1Name,
            ollamaMessages,
            options: conversation.parameters1.toOllamaOptions(),
          )
          .listen(
            (response) async {
              final content = response.message.content;
              if (content.isNotEmpty) {
                buffer1.write(content);
              }

              var model1Message = conversation.messages
                  .firstWhere((m) => m.id == model1MessageId)
                  .copyWith(text: buffer1.toString());
              await updateConversationSafely(model1Message);
            },
            onError: (error) async {
              var model1Message = Message.error(
                id: model1MessageId,
                errorMessage: _formatUserFacingError(error.toString()),
                timestamp: DateTime.now(),
              ).copyWith(modelSource: ModelSource.model1);
              await updateConversationSafely(model1Message);
              model1Done = true;
              if (model2Done) _cleanupStream(conversationId);
            },
            onDone: () async {
              var model1Message = conversation.messages
                  .firstWhere((m) => m.id == model1MessageId)
                  .copyWith(isStreaming: false);
              await updateConversationSafely(model1Message);
              model1Done = true;
              if (model2Done) {
                _cleanupStream(conversationId);
                await streamController.close();
              }
            },
            cancelOnError: true,
          );

      // Model 2 stream
      final buffer2 = StringBuffer();
      final subscription2 = client
          .chatStream(
            conversation.model2Name,
            ollamaMessages,
            options: conversation.parameters2.toOllamaOptions(),
          )
          .listen(
            (response) async {
              final content = response.message.content;
              if (content.isNotEmpty) {
                buffer2.write(content);
              }

              var model2Message = conversation.messages
                  .firstWhere((m) => m.id == model2MessageId)
                  .copyWith(text: buffer2.toString());
              await updateConversationSafely(model2Message);
            },
            onError: (error) async {
              var model2Message = Message.error(
                id: model2MessageId,
                errorMessage: _formatUserFacingError(error.toString()),
                timestamp: DateTime.now(),
              ).copyWith(modelSource: ModelSource.model2);
              await updateConversationSafely(model2Message);
              model2Done = true;
              if (model1Done) _cleanupStream(conversationId);
            },
            onDone: () async {
              var model2Message = conversation.messages
                  .firstWhere((m) => m.id == model2MessageId)
                  .copyWith(isStreaming: false);
              await updateConversationSafely(model2Message);
              model2Done = true;
              if (model1Done) {
                _cleanupStream(conversationId);
                await streamController.close();
              }
            },
            cancelOnError: true,
          );

      _activeSubscriptions[conversationId] = subscription1;
      _activeSubscriptions['${conversationId}_model2'] = subscription2;
    } else {
      // Non-streaming mode: get complete responses at once
      try {
        // Generate both responses in parallel
        final responses = await Future.wait([
          client.chat(
            conversation.model1Name,
            ollamaMessages,
            options: conversation.parameters1.toOllamaOptions(),
          ),
          client.chat(
            conversation.model2Name,
            ollamaMessages,
            options: conversation.parameters2.toOllamaOptions(),
          ),
        ]);

        if (streamController.isClosed) return;

        // Update model 1 message
        var model1Message = conversation.messages
            .firstWhere((m) => m.id == model1MessageId)
            .copyWith(text: responses[0].message.content, isStreaming: false);
        await updateConversationSafely(model1Message);

        // Update model 2 message
        var model2Message = conversation.messages
            .firstWhere((m) => m.id == model2MessageId)
            .copyWith(text: responses[1].message.content, isStreaming: false);
        await updateConversationSafely(model2Message);

        _cleanupStream(conversationId);
        await streamController.close();
      } catch (error) {
        if (streamController.isClosed) return;

        // Handle error for both models
        var model1Message = Message.error(
          id: model1MessageId,
          errorMessage: _formatUserFacingError(error.toString()),
          timestamp: DateTime.now(),
        ).copyWith(modelSource: ModelSource.model1);
        await updateConversationSafely(model1Message);

        var model2Message = Message.error(
          id: model2MessageId,
          errorMessage: _formatUserFacingError(error.toString()),
          timestamp: DateTime.now(),
        ).copyWith(modelSource: ModelSource.model2);
        await updateConversationSafely(model2Message);

        _cleanupStream(conversationId);
        await streamController.close();
      }
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Builds Ollama message history from conversation.
  List<OllamaMessage> _buildOllamaMessageHistory(
    Conversation conversation, {
    String? excludeMessageId,
    String? excludeMessageId2,
    bool includeModel1Only = false,
  }) {
    final messages = <OllamaMessage>[];

    // Add system prompt
    if (conversation.systemPrompt != null) {
      messages.add(OllamaMessage.system(conversation.systemPrompt!));
    }

    // Add conversation history
    for (final msg in conversation.messages) {
      if (msg.id == excludeMessageId ||
          msg.id == excludeMessageId2 ||
          msg.isError) {
        continue;
      }

      if (includeModel1Only &&
          msg.modelSource != ModelSource.user &&
          msg.modelSource != ModelSource.model1) {
        continue;
      }

      messages.add(_convertMessageToOllama(msg));
    }

    return messages;
  }

  /// Converts app Message to OllamaMessage.
  OllamaMessage _convertMessageToOllama(Message message) {
    switch (message.role) {
      case MessageRole.user:
        // Handle attachments (images)
        List<String>? images;
        if (message.attachments.isNotEmpty) {
          images = message.attachments
              .where((a) => a.isImage)
              .map((a) => base64Encode(a.data))
              .toList();
        }
        return OllamaMessage.user(message.text, images: images);

      case MessageRole.assistant:
        return OllamaMessage.assistant(message.text);

      case MessageRole.system:
        return OllamaMessage.system(message.text);

      case MessageRole.tool:
        // Tool messages - extract tool name from message if needed
        return OllamaMessage.tool(message.text, toolName: 'tool');
    }
  }

  /// Updates an assistant message in the conversation.
  Future<Conversation> _updateAssistantMessage(
    Conversation conversation,
    String messageId,
    String text, {
    required bool isStreaming,
    List<app_tools.ToolCall>? toolCalls,
  }) async {
    final messages = conversation.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(
          text: text,
          isStreaming: isStreaming,
          toolCalls: toolCalls ?? m.toolCalls,
        );
      }
      return m;
    }).toList();

    final updatedConversation = conversation.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    await updateConversation(updatedConversation);
    return updatedConversation;
  }

  /// Handles errors during message generation.
  void _handleError(
    String conversationId,
    Conversation conversation,
    String assistantMessageId,
    StreamController<Conversation> streamController,
    String errorMessage,
  ) async {
    if (streamController.isClosed) return;

    final friendlyError = _formatUserFacingError(errorMessage);

    final errorMsg = Message.error(
      id: assistantMessageId,
      errorMessage: friendlyError,
      timestamp: DateTime.now(),
    );

    final messages = conversation.messages.map((m) {
      if (m.id == assistantMessageId) return errorMsg;
      return m;
    }).toList();

    final errorConversation = conversation.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    await updateConversation(errorConversation);

    if (!streamController.isClosed) {
      streamController.add(errorConversation);
    }

    _cleanupStream(conversationId);
    await streamController.close();
  }

  /// Cleans up stream resources.
  void _cleanupStream(String conversationId) {
    _activeSubscriptions.remove(conversationId)?.cancel();
    _activeSubscriptions.remove('${conversationId}_model2')?.cancel();
    _activeStreams.remove(conversationId);
  }

  /// Updates the status message of a specific message in the conversation
  Future<Conversation> _updateStatusMessage(
    Conversation conversation,
    String messageId,
    String? statusMessage,
  ) async {
    final messages = conversation.messages.map((msg) {
      if (msg.id == messageId) {
        return msg.copyWith(statusMessage: statusMessage);
      }
      return msg;
    }).toList();

    final updated = conversation.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );

    await updateConversation(updated);
    return updated;
  }

  /// Gets a user-friendly display name for a tool
  String _getToolDisplayName(String toolName) {
    switch (toolName) {
      case 'web_search':
        return '🔍 Web Search';
      case 'read_url':
        return '📖 Reading URL';
      case 'get_current_datetime':
        return '🕒 Getting Time';
      default:
        return toolName;
    }
  }

  /// Show a notification when a response completes.
  Future<void> _showResponseCompleteNotification(
    Conversation conversation,
    String responseText,
  ) async {
    try {
      // Only show notification if response has content
      if (responseText.trim().isEmpty) return;

      await _notificationService.showResponseCompleteNotification(
        conversationId: conversation.id,
        conversationTitle: conversation.title,
        responsePreview: responseText,
      );
    } catch (e) {
      _log('Error showing notification: $e');
    }
  }

  // ============================================================================
  // STREAM MANAGEMENT
  // ============================================================================

  /// Check if a message is currently being generated for a conversation.
  bool isGenerating(String conversationId) {
    return _activeStreams.containsKey(conversationId);
  }

  /// Cancel ongoing message generation for a conversation.
  Future<void> cancelMessageGeneration(String conversationId) async {
    final subscription = _activeSubscriptions.remove(conversationId);
    await subscription?.cancel();

    final subscription2 = _activeSubscriptions.remove(
      '${conversationId}_model2',
    );
    await subscription2?.cancel();

    final controller = _activeStreams.remove(conversationId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }

    // Mark any streaming messages as cancelled
    final conversation = getConversation(conversationId);
    if (conversation != null) {
      final hasStreamingMessage = conversation.messages.any(
        (m) => m.isStreaming,
      );
      if (hasStreamingMessage) {
        final updatedMessages = conversation.messages.map((m) {
          if (m.isStreaming) {
            return m.copyWith(
              isStreaming: false,
              text: m.text.isEmpty ? '[Generation cancelled]' : m.text,
            );
          }
          return m;
        }).toList();

        final updatedConversation = conversation.copyWith(
          messages: updatedMessages,
          updatedAt: DateTime.now(),
        );
        await updateConversation(updatedConversation);
      }
    }
  }

  /// Get active stream for a conversation (allows reconnecting).
  Stream<Conversation>? getActiveStream(String conversationId) {
    return _activeStreams[conversationId]?.stream;
  }

  /// Dispose of all resources.
  void dispose() {
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();

    for (final controller in _activeStreams.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _activeStreams.clear();

    if (!_conversationUpdatesController.isClosed) {
      _conversationUpdatesController.close();
    }

    // Dispose offline mode services
    _connectivityService.dispose();
    _queueService.dispose();

    // Dispose on-device LLM service if present
    _onDeviceLLMService?.dispose();
    _inferenceConfigService?.dispose();
  }

  // ============================================================================
  // SYNCHRONOUS CHAT (NON-STREAMING)
  // ============================================================================

  /// Sends a message and gets a non-streaming response from Ollama.
  Future<Conversation> sendMessageSync(
    String conversationId,
    String text,
  ) async {
    final initialConversation = getConversation(conversationId);
    if (initialConversation == null) {
      throw Exception('Conversation not found');
    }

    final client = _ollamaManager.client;
    if (client == null) {
      throw Exception('No Ollama connection configured');
    }

    // Add user message
    final userMessage = Message.user(
      id: const Uuid().v4(),
      text: text,
      timestamp: DateTime.now(),
    );
    var conversation = await addMessage(conversationId, userMessage);

    try {
      // Build message history
      final ollamaMessages = _buildOllamaMessageHistory(conversation);

      // Get response
      final response = await client.chat(
        conversation.modelName,
        ollamaMessages,
        options: conversation.parameters.toOllamaOptions(),
      );

      // Add assistant message
      final assistantMessage = Message.assistant(
        id: const Uuid().v4(),
        text: response.message.content,
        timestamp: DateTime.now(),
      );
      conversation = await addMessage(conversationId, assistantMessage);
    } catch (e) {
      // Add error message
      final errorMessage = Message.error(
        id: const Uuid().v4(),
        errorMessage: _formatUserFacingError(e.toString()),
        timestamp: DateTime.now(),
      );
      conversation = await addMessage(conversationId, errorMessage);
    }

    return conversation;
  }

  /// Build system prompt with agent-specific instructions
  String _buildAgentSystemPrompt(String? basePrompt) {
    final agentInstructions =
        '''You are a helpful assistant with access to tools.

IMPORTANT RULES:
1. Use tools only when needed to find information or complete tasks
2. After using tools and getting results, ALWAYS provide a final answer
3. Do NOT keep asking for more tools after you have enough information
4. Synthesize tool results into a clear, complete answer
5. If you have tried multiple tools and gathered information, stop and provide your answer

When you have sufficient information from tool results, provide a complete response and do NOT call more tools.''';

    if (basePrompt != null && basePrompt.isNotEmpty) {
      return '$basePrompt\n\n$agentInstructions';
    }
    return agentInstructions;
  }

  // ============================================================================
  // OFFLINE HELPERS
  // ============================================================================

  /// Queues an existing user message when connectivity is unavailable.
  Future<Conversation> _queueExistingMessage(
    String conversationId,
    String messageId,
  ) async {
    var conversation = getConversation(conversationId);
    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    final alreadyQueued = _queueService.getQueue().any(
      (item) => item.messageId == messageId,
    );

    if (!alreadyQueued) {
      await _queueService.enqueue(
        conversationId: conversationId,
        messageId: messageId,
      );
    }

    final messages = conversation.messages.map((m) {
      return m.id == messageId
          ? m.copyWith(status: MessageStatus.queued, queuedAt: DateTime.now())
          : m;
    }).toList();

    conversation = conversation.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    await updateConversation(conversation);
    return conversation;
  }

  /// Converts raw errors to user-friendly messages.
  String _formatUserFacingError(String errorMessage) {
    var cleaned = errorMessage.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^Exception:\s*'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^Error:\s*'), '');

    if (cleaned.startsWith('PlatformException(') && cleaned.endsWith(')')) {
      final parts = cleaned.substring(
        'PlatformException('.length,
        cleaned.length - 1,
      );
      final segments = parts.split(',');
      if (segments.length >= 2) {
        cleaned = segments[1].trim();
      }
    }

    if (cleaned.isEmpty) {
      return 'Something went wrong while generating a response. Please try again.';
    }

    final status = _connectivityService.currentStatus;
    final baseUrl = _ollamaManager.connection?.url;
    final location = baseUrl != null ? ' at $baseUrl' : '';

    if (status == OllamaConnectivityStatus.offline) {
      return 'You appear to be offline. Check your network and try again.';
    }

    if (status == OllamaConnectivityStatus.disconnected) {
      return 'Cannot reach Ollama$location. Make sure it is running and reachable.';
    }

    final lower = cleaned.toLowerCase();

    if (lower.contains('on-device') ||
        lower.contains('litert') ||
        lower.contains('model_not_loaded')) {
      return 'On-device model is not ready. Open Settings > On-device Models, load a model, then try again.';
    }

    if (lower.contains('not available on this device')) {
      return 'On-device inference is not supported on this device. Use a remote model instead.';
    }

    if (lower.contains('not downloaded')) {
      return 'This local model is not downloaded yet. Download it from Settings > On-device Models and retry.';
    }

    if (lower.contains('generation_in_progress')) {
      return 'A response is already being generated. Please wait for it to finish.';
    }

    if (lower.contains('no ollama connection configured')) {
      return 'No Ollama connection configured. Add one in Settings.';
    }

    if (lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('time out')) {
      return 'Request timed out. Try again or increase the timeout in Settings.';
    }

    if (lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('socketexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('no route to host')) {
      return 'Cannot reach Ollama$location. Make sure it is running and reachable.';
    }

    if (lower.contains('ollamaexception')) {
      return cleaned.replaceFirst(RegExp(r'^OllamaException:\s*'), '');
    }

    return cleaned;
  }
}

/// Wrapper to adapt our Tool model to OllamaAgent's Tool interface.
class _OllamaToolWrapper extends Tool {
  final app_tools.Tool _tool;
  final ToolExecutorService _executor;

  _OllamaToolWrapper(this._tool, this._executor);

  @override
  String get name => _tool.name;

  @override
  String get description => _tool.description;

  @override
  Map<String, dynamic> get parameters => _tool.parameters;

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    ChatService._debugLog(
      'ToolWrapper.execute: Executing tool: $name with args: $args',
    );
    try {
      final toolCall = await _executor.executeToolCall(
        toolName: name,
        arguments: args,
      );

      ChatService._debugLog(
        'ToolWrapper.execute: Tool execution status: ${toolCall.status}',
      );

      if (toolCall.status == app_tools.ToolCallStatus.success &&
          toolCall.result != null) {
        // Return the summary or a JSON representation of the result
        if (toolCall.result!.summary != null &&
            toolCall.result!.summary!.isNotEmpty) {
          ChatService._debugLog(
            'ToolWrapper.execute: Tool returned summary: ${toolCall.result!.summary}',
          );
          return toolCall.result!.summary!;
        } else if (toolCall.result!.data != null) {
          final dataStr = toolCall.result!.data.toString();
          ChatService._debugLog(
            'ToolWrapper.execute: Tool returned data: $dataStr',
          );
          return dataStr;
        } else {
          return 'Tool executed successfully';
        }
      } else {
        final error = 'Error: ${toolCall.errorMessage ?? "Unknown error"}';
        ChatService._debugLog('ToolWrapper.execute: Tool failed: $error');
        return error;
      }
    } catch (e) {
      final error = 'Error executing tool: $e';
      ChatService._debugLog('ToolWrapper.execute: Exception: $error');
      return error;
    }
  }
}

// Helper methods for status messages and tool display names
extension ChatServiceHelpers on ChatService {
  /// Gets a user-friendly display name for a tool
  String getToolDisplayName(String toolName) {
    switch (toolName) {
      case 'web_search':
        return '🔍 Web Search';
      case 'read_url':
        return '📖 Reading URL';
      case 'get_current_datetime':
        return '🕒 Getting Time';
      default:
        return toolName;
    }
  }
}
