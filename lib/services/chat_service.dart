import 'dart:async';
import 'dart:convert';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/tool.dart';
import 'package:private_chat_hub/services/ollama_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:private_chat_hub/services/web_search_service.dart';
import 'package:uuid/uuid.dart';

/// Service for managing chat conversations and sending messages to Ollama.
class ChatService {
  final OllamaService _ollama;
  final StorageService _storage;
  final WebSearchService _webSearch;
  static const String _conversationsKey = 'conversations';
  static const String _currentConversationKey = 'current_conversation_id';
  static const String _webSearchEnabledKey = 'web_search_enabled';
  
  // Track active message generation streams
  final Map<String, StreamController<Conversation>> _activeStreams = {};
  final Map<String, StreamSubscription> _activeSubscriptions = {};

  ChatService(this._ollama, this._storage, this._webSearch);

  /// Gets whether web search is enabled.
  bool getWebSearchEnabled() {
    return _storage.getBool(_webSearchEnabledKey) ?? true; // Enabled by default
  }

  /// Sets whether web search is enabled.
  Future<void> setWebSearchEnabled(bool enabled) async {
    await _storage.setBool(_webSearchEnabledKey, enabled);
  }

  /// Gets all saved conversations.
  List<Conversation> getConversations({String? projectId, bool excludeProjectConversations = false}) {
    final jsonString = _storage.getString(_conversationsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      var conversations = jsonList
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Filter by project if specified
      if (projectId != null) {
        conversations = conversations.where((c) => c.projectId == projectId).toList();
      } else if (excludeProjectConversations) {
        // Only show standalone conversations (not in any project)
        conversations = conversations.where((c) => c.projectId == null).toList();
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
    final jsonString =
        jsonEncode(conversations.map((c) => c.toJson()).toList());
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

  /// Deletes all conversations in a project.
  Future<void> deleteProjectConversations(String projectId) async {
    final conversations = getConversations();
    final updatedConversations = conversations.where((c) => c.projectId != projectId).toList();
    await _saveConversations(updatedConversations);
  }

  /// Moves a conversation to a project.
  Future<void> moveConversationToProject(String conversationId, String? projectId) async {
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
    final updatedConversations =
        conversations.where((c) => c.id != id).toList();
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
  Future<Conversation> addMessage(String conversationId, Message message) async {
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
  Future<Conversation?> deleteMessage(String conversationId, String messageId) async {
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
  Stream<Conversation> sendMessage(
    String conversationId,
    String text,
  ) async* {
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
    _generateMessageInBackground(conversationId, conversation, assistantMessageId, streamController);
    
    // Listen to the broadcast stream and yield updates
    await for (final updatedConversation in streamController.stream) {
      yield updatedConversation;
    }
  }

  /// Internal method to generate message in background
  Future<void> _generateMessageInBackground(
    String conversationId,
    Conversation conversation,
    String assistantMessageId,
    StreamController<Conversation> streamController,
  ) async {
    var assistantMessage = conversation.messages.firstWhere((m) => m.id == assistantMessageId);
    
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
          ollamaMessages.add(msg.toOllamaMessage());
        }
      }

      // Prepare tools if web search is enabled
      final tools = getWebSearchEnabled() ? [WebSearchTool().toOllamaFormat()] : null;

      // Stream the response with model parameters and tools
      final buffer = StringBuffer();
      final toolCallsBuffer = <ToolCall>[];
      
      final subscription = _ollama.sendChatStream(
        model: conversation.modelName,
        messages: ollamaMessages,
        options: conversation.parameters.toOllamaOptions(),
        tools: tools,
      ).listen(
        (data) async {
          if (streamController.isClosed) return;
          
          final message = data['message'] as Map<String, dynamic>?;
          if (message == null) return;
          
          // Handle regular content
          final content = message['content'] as String?;
          if (content != null && content.isNotEmpty) {
            buffer.write(content);
          }
          
          // Handle tool calls
          final toolCallsData = message['tool_calls'] as List<dynamic>?;
          if (toolCallsData != null) {
            for (final tcData in toolCallsData) {
              if (tcData is Map<String, dynamic>) {
                final id = tcData['id'] as String? ?? '';
                final function = tcData['function'] as Map<String, dynamic>?;
                if (function != null) {
                  final name = function['name'] as String? ?? '';
                  final args = function['arguments'] as Map<String, dynamic>? ?? {};
                  
                  if (id.isNotEmpty && name.isNotEmpty) {
                    toolCallsBuffer.add(ToolCall(id: id, name: name, arguments: args));
                  }
                }
              }
            }
          }
          
          // Update the assistant message with accumulated text
          assistantMessage = assistantMessage.copyWith(
            text: buffer.toString(),
            toolCalls: toolCallsBuffer.isNotEmpty ? toolCallsBuffer : null,
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
          
          // Check if we have tool calls to execute
          if (assistantMessage.hasToolCalls) {
            // Execute tool calls
            await _executeToolCalls(
              conversationId,
              conversation,
              assistantMessage,
              streamController,
            );
          } else {
            // No tool calls, just finalize the message
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
          }
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
  Future<void> _executeToolCalls(
    String conversationId,
    Conversation conversation,
    Message assistantMessage,
    StreamController<Conversation> streamController,
  ) async {
    if (!assistantMessage.hasToolCalls) return;
    
    try {
      // Update conversation with the assistant message containing tool calls
      var updatedMessages = conversation.messages.map((m) {
        if (m.id == assistantMessage.id) return assistantMessage;
        return m;
      }).toList();
      
      conversation = conversation.copyWith(
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      );
      await updateConversation(conversation);
      
      if (!streamController.isClosed) {
        streamController.add(conversation);
      }
      
      // Execute each tool call
      for (final toolCall in assistantMessage.toolCalls!) {
        if (toolCall.name == 'web_search') {
          final query = toolCall.arguments['query'] as String?;
          if (query != null && query.isNotEmpty) {
            // Perform web search
            try {
              final searchResults = await _webSearch.search(query);
              
              // Add tool result message
              final toolResultMessage = Message.toolResult(
                id: const Uuid().v4(),
                toolCallId: toolCall.id,
                content: searchResults,
                timestamp: DateTime.now(),
              );
              
              conversation = await addMessage(conversationId, toolResultMessage);
              
              if (!streamController.isClosed) {
                streamController.add(conversation);
              }
            } catch (e) {
              // Add error result
              final errorResult = Message.toolResult(
                id: const Uuid().v4(),
                toolCallId: toolCall.id,
                content: 'Error performing web search: $e',
                timestamp: DateTime.now(),
              );
              
              conversation = await addMessage(conversationId, errorResult);
              
              if (!streamController.isClosed) {
                streamController.add(conversation);
              }
            }
          }
        }
      }
      
      // Continue the conversation with tool results
      final newAssistantMessageId = const Uuid().v4();
      final newAssistantMessage = Message.assistant(
        id: newAssistantMessageId,
        text: '',
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      
      conversation = await addMessage(conversationId, newAssistantMessage);
      
      if (!streamController.isClosed) {
        streamController.add(conversation);
      }
      
      // Recursively generate the next response with tool results
      await _generateMessageInBackground(
        conversationId,
        conversation,
        newAssistantMessageId,
        streamController,
      );
      
    } catch (e) {
      if (streamController.isClosed) return;
      
      final errorMessage = Message.error(
        id: const Uuid().v4(),
        errorMessage: 'Error executing tools: $e',
        timestamp: DateTime.now(),
      );
      
      conversation = await addMessage(conversationId, errorMessage);
      await updateConversation(conversation);
      
      if (!streamController.isClosed) {
        streamController.add(conversation);
      }
      
      _cleanupStream(conversationId);
      await streamController.close();
    }
  }

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
    
    final controller = _activeStreams.remove(conversationId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
    
    // Mark any streaming messages as incomplete/cancelled
    final conversation = getConversation(conversationId);
    if (conversation != null) {
      final hasStreamingMessage = conversation.messages.any((m) => m.isStreaming);
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
    _generateMessageInBackground(conversationId, conversation, assistantMessageId, streamController);
    
    // Listen to the broadcast stream and yield updates
    await for (final updatedConversation in streamController.stream) {
      yield updatedConversation;
    }
  }
}
