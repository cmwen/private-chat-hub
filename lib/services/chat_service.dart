import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;
import 'package:private_chat_hub/models/comparison_conversation.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/services/ollama_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Service for managing chat conversations and sending messages to Ollama.
class ChatService {
  final OllamaService _ollama;
  final StorageService _storage;
  static const String _conversationsKey = 'conversations';
  static const String _currentConversationKey = 'current_conversation_id';

  // Track active message generation streams
  final Map<String, StreamController<Conversation>> _activeStreams = {};
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  
  // Cache for model capabilities
  final Map<String, bool> _modelCapabilitiesCache = {};

  ChatService(this._ollama, this._storage);

  /// Checks if a model supports tool calling by querying the Ollama API.
  /// 
  /// Fetches the model information from Ollama's /api/show endpoint and checks
  /// the capabilities field. This is more reliable than hardcoding model names,
  /// as it respects what the model actually supports.
  /// 
  /// Uses caching to avoid repeated API calls.
  Future<bool> modelSupportsTools(String modelName) async {
    final modelFamily = modelName.split(':').first.toLowerCase();
    
    // Check cache first
    if (_modelCapabilitiesCache.containsKey(modelFamily)) {
      print('[DEBUG] Model capabilities retrieved from cache: $modelFamily');
      return _modelCapabilitiesCache[modelFamily] ?? false;
    }
    
    print('[DEBUG] Fetching capabilities for model: $modelName');
    
    try {
      final modelInfo = await _ollama.showModel(modelName);
      
      // The /api/show endpoint returns a "capabilities" array
      // Example: "capabilities": ["completion", "vision", "tools"]
      final capabilities = modelInfo['capabilities'] as List<dynamic>?;
      
      if (capabilities != null) {
        final supportsTools = capabilities.contains('tools');
        print('[DEBUG] Model $modelName capabilities: $capabilities');
        print('[DEBUG] Model $modelName supports tools: $supportsTools');
        
        // Cache the result
        _modelCapabilitiesCache[modelFamily] = supportsTools;
        return supportsTools;
      } else {
        print('[DEBUG] No capabilities info found for model: $modelName');
        // Fallback to hardcoded list if capabilities not available
        return _modelSupportsFallback(modelFamily);
      }
    } catch (e) {
      print('[DEBUG] Error checking model capabilities: $e');
      // Fallback to hardcoded list on error
      return _modelSupportsFallback(modelFamily);
    }
  }

  /// Fallback method that checks if a model supports tools based on hardcoded names.
  /// 
  /// This is used when the Ollama API doesn't return capabilities information.
  /// Based on Ollama documentation:
  /// - llama3.1+ have native function calling
  /// - mistral-3 has native function calling
  /// - mistral-nemo has function calling
  /// - qwen2.5+ have tool support
  /// - command-r models have tool support
  bool _modelSupportsFallback(String modelFamily) {
    print('[DEBUG] Using fallback hardcoded model detection for: $modelFamily');
    
    // llama3.1+ (but not llama3.0 or llama2)
    if (modelFamily.startsWith('llama3.')) {
      final versionMatch = RegExp(r'llama3\.(\d+)').firstMatch(modelFamily);
      if (versionMatch != null) {
        final minorVersion = int.tryParse(versionMatch.group(1) ?? '0') ?? 0;
        return minorVersion >= 1;
      }
    }
    
    // Mistral models with tool support
    if (modelFamily.startsWith('mistral-3') ||
        modelFamily.startsWith('mistral-nemo') ||
        modelFamily.startsWith('mistral-large')) {
      return true;
    }
    
    // Other known tool-capable models
    if (modelFamily.startsWith('qwen2.5') ||
        modelFamily.startsWith('qwen2.6') ||
        modelFamily.startsWith('qwen3') ||
        modelFamily.startsWith('command-r')) {
      return true;
    }
    
    return false;
  }

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
        // Check if it's a comparison conversation
        if (jsonMap['isComparisonMode'] == true) {
          return ComparisonConversation.fromJson(jsonMap);
        }
        return Conversation.fromJson(jsonMap);
      }).toList();

      // Filter by project if specified
      if (projectId != null) {
        conversations = conversations
            .where((c) => c.projectId == projectId)
            .toList();
      } else if (excludeProjectConversations) {
        // Only show standalone conversations (not in any project)
        conversations = conversations
            .where((c) => c.projectId == null)
            .toList();
      }

      // Sort by updated date, most recent first
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
    }
  }

  /// Deletes a conversation.
  Future<void> deleteConversation(String id) async {
    final conversations = getConversations();
    final updatedConversations = conversations
        .where((c) => c.id != id)
        .toList();
    await _saveConversations(updatedConversations);

    // Clear current if we deleted it
    if (getCurrentConversationId() == id) {
      await _storage.remove(_currentConversationKey);
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

  /// Sends a message and gets a streaming response from Ollama.
  ///
  /// Returns a stream of updated conversations as the response streams in.
  /// The stream continues in the background even if the listener is cancelled.
  Stream<Conversation> sendMessage(String conversationId, String text) async* {
    // Cancel any existing stream for this conversation
    await cancelMessageGeneration(conversationId);

    // Get the conversation
    final initialConversation = getConversation(conversationId);
    if (initialConversation == null) {
      throw Exception('Conversation not found');
    }

    // Create and add user message
    final userMessage = Message.user(
      id: const Uuid().v4(),
      text: text,
      timestamp: DateTime.now(),
    );
    var conversation = await addMessage(conversationId, userMessage);

    // Create a broadcast stream controller for this conversation
    final streamController = StreamController<Conversation>.broadcast();
    _activeStreams[conversationId] = streamController;

    // Yield initial state with user message
    streamController.add(conversation);
    yield conversation;

    // Create a placeholder for the assistant response
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

    // Start the background generation process
    _generateMessageInBackground(
      conversationId,
      conversation,
      assistantMessageId,
      streamController,
    );

    // Listen to the broadcast stream and yield updates
    await for (final updatedConversation in streamController.stream) {
      yield updatedConversation;
    }
  }

  /// Sends a message to two models simultaneously for comparison.
  ///
  /// Returns a stream of updated ComparisonConversations as both models respond.
  /// Responses from both models stream independently and update as they arrive.
  Stream<ComparisonConversation> sendDualModelMessage(
    String conversationId,
    String text,
  ) async* {
    // Cancel any existing streams for this conversation
    await cancelMessageGeneration(conversationId);

    // Get the comparison conversation
    final initialConversation = getConversation(conversationId);
    if (initialConversation == null) {
      throw Exception('Conversation not found');
    }
    if (initialConversation is! ComparisonConversation) {
      throw Exception('Not a comparison conversation');
    }

    ComparisonConversation conversation = initialConversation;

    // Create and add user message
    final userMessage = Message.user(
      id: const Uuid().v4(),
      text: text,
      timestamp: DateTime.now(),
      modelSource: ModelSource.user,
    );
    conversation = (await addMessage(conversationId, userMessage))
        as ComparisonConversation;

    // Create a broadcast stream controller
    final streamController =
        StreamController<ComparisonConversation>.broadcast();
    _activeStreams[conversationId] = streamController as StreamController<Conversation>;

    // Yield initial state with user message
    streamController.add(conversation);
    yield conversation;

    // Create placeholder messages for both models
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

    conversation = (await addMessage(conversationId, model1Message))
        as ComparisonConversation;
    conversation = (await addMessage(conversationId, model2Message))
        as ComparisonConversation;

    streamController.add(conversation);
    yield conversation;

    // Start both generation processes in parallel
    _generateDualModelMessagesInBackground(
      conversationId,
      conversation,
      model1MessageId,
      model2MessageId,
      streamController,
    );

    // Listen to the broadcast stream and yield updates
    await for (final updatedConversation in streamController.stream) {
      yield updatedConversation;
    }
  }

  /// Internal method to generate messages from both models in background
  Future<void> _generateDualModelMessagesInBackground(
    String conversationId,
    ComparisonConversation conversation,
    String model1MessageId,
    String model2MessageId,
    StreamController<ComparisonConversation> streamController,
  ) async {
    var model1Message = conversation.messages.firstWhere(
      (m) => m.id == model1MessageId,
    );
    var model2Message = conversation.messages.firstWhere(
      (m) => m.id == model2MessageId,
    );

    bool model1Done = false;
    bool model2Done = false;

    // Prepare messages for Ollama API (shared conversation history)
    final ollamaMessages = <Map<String, dynamic>>[];

    // Add system prompt if present
    if (conversation.systemPrompt != null) {
      ollamaMessages.add({
        'role': 'system',
        'content': conversation.systemPrompt,
      });
    }

    // Add conversation history (only user messages and responses, excluding current placeholders)
    for (final msg in conversation.messages) {
      if (msg.id != model1MessageId &&
          msg.id != model2MessageId &&
          !msg.isError) {
        // For comparison mode, only include user messages and messages from Model1
        // to maintain conversation continuity (or use separate histories if preferred)
        if (msg.modelSource == ModelSource.user ||
            msg.modelSource == ModelSource.model1) {
          ollamaMessages.add(msg.toOllamaMessage());
        }
      }
    }

    // Helper function to update conversation safely
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

    // Stream Model 1 response
    final buffer1 = StringBuffer();
    final subscription1 = _ollama
        .sendChatStream(
          model: conversation.model1Name,
          messages: ollamaMessages,
          options: conversation.parameters1.toOllamaOptions(),
        )
        .listen(
          (data) async {
            final message = data['message'] as Map<String, dynamic>?;
            if (message == null) return;

            final content = message['content'] as String?;
            if (content != null && content.isNotEmpty) {
              buffer1.write(content);
            }

            model1Message = model1Message.copyWith(text: buffer1.toString());
            await updateConversationSafely(model1Message);
          },
          onError: (error) async {
            model1Message = Message.error(
              id: model1MessageId,
              errorMessage: error.toString(),
              timestamp: DateTime.now(),
            ).copyWith(modelSource: ModelSource.model1);
            await updateConversationSafely(model1Message);
            model1Done = true;
            if (model2Done) _cleanupStream(conversationId);
          },
          onDone: () async {
            model1Message = model1Message.copyWith(isStreaming: false);
            await updateConversationSafely(model1Message);
            model1Done = true;
            if (model2Done) {
              _cleanupStream(conversationId);
              await streamController.close();
            }
          },
          cancelOnError: true,
        );

    // Stream Model 2 response
    final buffer2 = StringBuffer();
    final subscription2 = _ollama
        .sendChatStream(
          model: conversation.model2Name,
          messages: ollamaMessages,
          options: conversation.parameters2.toOllamaOptions(),
        )
        .listen(
          (data) async {
            final message = data['message'] as Map<String, dynamic>?;
            if (message == null) return;

            final content = message['content'] as String?;
            if (content != null && content.isNotEmpty) {
              buffer2.write(content);
            }

            model2Message = model2Message.copyWith(text: buffer2.toString());
            await updateConversationSafely(model2Message);
          },
          onError: (error) async {
            model2Message = Message.error(
              id: model2MessageId,
              errorMessage: error.toString(),
              timestamp: DateTime.now(),
            ).copyWith(modelSource: ModelSource.model2);
            await updateConversationSafely(model2Message);
            model2Done = true;
            if (model1Done) _cleanupStream(conversationId);
          },
          onDone: () async {
            model2Message = model2Message.copyWith(isStreaming: false);
            await updateConversationSafely(model2Message);
            model2Done = true;
            if (model1Done) {
              _cleanupStream(conversationId);
              await streamController.close();
            }
          },
          cancelOnError: true,
        );

    // Store subscriptions (we'll store model1's subscription as the primary one)
    _activeSubscriptions[conversationId] = subscription1;
    // Store model2's subscription with a special key for cleanup
    _activeSubscriptions['${conversationId}_model2'] = subscription2;
  }

  /// Internal method to generate message in background
  Future<void> _generateMessageInBackground(
    String conversationId,
    Conversation conversation,
    String assistantMessageId,
    StreamController<Conversation> streamController,
  ) async {
    var assistantMessage = conversation.messages.firstWhere(
      (m) => m.id == assistantMessageId,
    );

    try {
      // Prepare messages for Ollama API
      final ollamaMessages = <Map<String, dynamic>>[];

      // Add system prompt if present
      if (conversation.systemPrompt != null) {
        ollamaMessages.add({
          'role': 'system',
          'content': conversation.systemPrompt,
        });
      }

      // Add conversation history
      for (final msg in conversation.messages) {
        if (msg.id != assistantMessageId && !msg.isError) {
          final ollamaMsg = msg.toOllamaMessage();
          ollamaMessages.add(ollamaMsg);
          print('[DEBUG] Adding message to history: role=${ollamaMsg['role']}');
        }
      }

      print('[DEBUG] Preparing message for model: ${conversation.modelName}');

      // Stream the response with model parameters
      final buffer = StringBuffer();

      print('[DEBUG] About to send chat to Ollama:');
      print('[DEBUG]   Model: ${conversation.modelName}');
      print('[DEBUG]   Messages: ${ollamaMessages.length}');

      final subscription = _ollama
          .sendChatStream(
            model: conversation.modelName,
            messages: ollamaMessages,
            options: conversation.parameters.toOllamaOptions(),
          )
          .listen(
            (data) async {
              if (streamController.isClosed) return;

              final message = data['message'] as Map<String, dynamic>?;
              if (message == null) return;

              print('[DEBUG] Stream event keys: ${message.keys.toList()}');

              // Handle regular content
              final content = message['content'] as String?;
              if (content != null && content.isNotEmpty) {
                buffer.write(content);
              } else {
                print('[DEBUG] No tool_calls in stream message');
              }
              // Update the assistant message with accumulated text
              assistantMessage = assistantMessage.copyWith(
                text: buffer.toString(),
              );

              // Update the conversation with the updated message
              final messages = conversation.messages.map((m) {
                if (m.id == assistantMessageId) return assistantMessage;
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
            },
            onError: (error) async {
              if (streamController.isClosed) return;

              // Update the assistant message to show error
              assistantMessage = Message.error(
                id: assistantMessageId,
                errorMessage: error.toString(),
                timestamp: DateTime.now(),
              );

              final errorMessages = conversation.messages.map((m) {
                if (m.id == assistantMessageId) return assistantMessage;
                return m;
              }).toList();

              conversation = conversation.copyWith(
                messages: errorMessages,
                updatedAt: DateTime.now(),
              );
              await updateConversation(conversation);

              if (!streamController.isClosed) {
                streamController.add(conversation);
              }

              _cleanupStream(conversationId);
              await streamController.close();
            },
            onDone: () async {
              if (streamController.isClosed) return;

              // Mark streaming as complete
              assistantMessage = assistantMessage.copyWith(isStreaming: false);

              // Log the final assistant message state
              print('[DEBUG] onDone - Final assistant message: text="${assistantMessage.text.substring(0, min(assistantMessage.text.length, 100))}"');
              print('[DEBUG] onDone - Text length: ${assistantMessage.text.length}');
              print('[DEBUG] onDone - Full response text: ${assistantMessage.text}');

              // Finalize the message
              final finalMessages = conversation.messages.map((m) {
                if (m.id == assistantMessageId) return assistantMessage;
                return m;
              }).toList();

              conversation = conversation.copyWith(
                messages: finalMessages,
                updatedAt: DateTime.now(),
              );
              await updateConversation(conversation);

              if (!streamController.isClosed) {
                streamController.add(conversation);
              }

              _cleanupStream(conversationId);
              await streamController.close();
            },
            cancelOnError: true,
          );

      _activeSubscriptions[conversationId] = subscription;
    } catch (e) {
      if (streamController.isClosed) return;

      // Update the assistant message to show error
      assistantMessage = Message.error(
        id: assistantMessageId,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );

      final errorMessages = conversation.messages.map((m) {
        if (m.id == assistantMessageId) return assistantMessage;
        return m;
      }).toList();

      conversation = conversation.copyWith(
        messages: errorMessages,
        updatedAt: DateTime.now(),
      );
      await updateConversation(conversation);

      if (!streamController.isClosed) {
        streamController.add(conversation);
      }

      _cleanupStream(conversationId);
      await streamController.close();
    }
  }

  /// Executes tool calls and continues the conversation
  /// Cleanup stream resources
  void _cleanupStream(String conversationId) {
    _activeSubscriptions.remove(conversationId)?.cancel();
    _activeStreams.remove(conversationId);
  }

  /// Check if a message is currently being generated for a conversation
  bool isGenerating(String conversationId) {
    return _activeStreams.containsKey(conversationId);
  }

  /// Cancel ongoing message generation for a conversation
  Future<void> cancelMessageGeneration(String conversationId) async {
    final subscription = _activeSubscriptions.remove(conversationId);
    await subscription?.cancel();

    // Also cancel model2 subscription if it exists (for comparison mode)
    final subscription2 = _activeSubscriptions.remove('${conversationId}_model2');
    await subscription2?.cancel();

    final controller = _activeStreams.remove(conversationId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }

    // Mark any streaming messages as incomplete/cancelled
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

  /// Get active stream for a conversation (allows reconnecting)
  Stream<Conversation>? getActiveStream(String conversationId) {
    return _activeStreams[conversationId]?.stream;
  }

  /// Dispose of all resources
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
  }

  /// Sends a message and gets a non-streaming response from Ollama.
  Future<Conversation> sendMessageSync(
    String conversationId,
    String text,
  ) async {
    final initialConversation = getConversation(conversationId);
    if (initialConversation == null) {
      throw Exception('Conversation not found');
    }

    // Create and add user message
    final userMessage = Message.user(
      id: const Uuid().v4(),
      text: text,
      timestamp: DateTime.now(),
    );
    var conversation = await addMessage(conversationId, userMessage);

    try {
      // Prepare messages for Ollama API
      final ollamaMessages = <Map<String, dynamic>>[];

      if (conversation.systemPrompt != null) {
        ollamaMessages.add({
          'role': 'system',
          'content': conversation.systemPrompt,
        });
      }

      for (final msg in conversation.messages) {
        if (!msg.isError) {
          ollamaMessages.add(msg.toOllamaMessage());
        }
      }

      // Get response
      final response = await _ollama.sendChat(
        model: conversation.modelName,
        messages: ollamaMessages,
      );

      // Add assistant message
      final assistantMessage = Message.assistant(
        id: const Uuid().v4(),
        text: response,
        timestamp: DateTime.now(),
      );
      conversation = await addMessage(conversationId, assistantMessage);
    } catch (e) {
      // Add error message
      final errorMessage = Message.error(
        id: const Uuid().v4(),
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
      conversation = await addMessage(conversationId, errorMessage);
    }

    return conversation;
  }

  /// Deletes all conversations.
  Future<void> deleteAllConversations() async {
    await _storage.remove(_conversationsKey);
    await _storage.remove(_currentConversationKey);
  }

  /// Streams a response for the current conversation context.
  ///
  /// This is used when messages (with attachments) have already been added
  /// and we just need to get the AI response.
  Stream<Conversation> sendMessageWithContext(String conversationId) async* {
    // Cancel any existing stream for this conversation
    await cancelMessageGeneration(conversationId);

    final initialConversation = getConversation(conversationId);
    if (initialConversation == null) {
      throw Exception('Conversation not found');
    }

    var conversation = initialConversation;

    // Create a broadcast stream controller for this conversation
    final streamController = StreamController<Conversation>.broadcast();
    _activeStreams[conversationId] = streamController;

    // Create a placeholder for the assistant response
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

    // Start the background generation process
    _generateMessageInBackground(
      conversationId,
      conversation,
      assistantMessageId,
      streamController,
    );

    // Listen to the broadcast stream and yield updates
    await for (final updatedConversation in streamController.stream) {
      yield updatedConversation;
    }
  }
}
