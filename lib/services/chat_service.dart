import 'dart:async';
import 'dart:convert';
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

  ChatService(this._ollama, this._storage);

  /// Gets all saved conversations.
  List<Conversation> getConversations() {
    final jsonString = _storage.getString(_conversationsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final conversations = jsonList
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Sort by updated date, most recent first
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    } catch (e) {
      return [];
    }
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
  }) async {
    final conversation = Conversation(
      id: const Uuid().v4(),
      title: title ?? 'New Conversation',
      modelName: modelName,
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
  Stream<Conversation> sendMessage(
    String conversationId,
    String text,
  ) async* {
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
    yield conversation;

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

      // Stream the response
      final buffer = StringBuffer();
      await for (final chunk in _ollama.sendChatStream(
        model: conversation.modelName,
        messages: ollamaMessages,
      )) {
        buffer.write(chunk);
        
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
        yield conversation;
      }

      // Mark streaming as complete
      assistantMessage = assistantMessage.copyWith(isStreaming: false);
      final finalMessages = conversation.messages.map((m) {
        if (m.id == assistantMessageId) return assistantMessage;
        return m;
      }).toList();

      conversation = conversation.copyWith(
        messages: finalMessages,
        updatedAt: DateTime.now(),
      );
      await updateConversation(conversation);
      yield conversation;

    } catch (e) {
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
      yield conversation;
    }
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
    final initialConversation = getConversation(conversationId);
    if (initialConversation == null) {
      throw Exception('Conversation not found');
    }

    var conversation = initialConversation;

    // Create a placeholder for the assistant response
    final assistantMessageId = const Uuid().v4();
    var assistantMessage = Message.assistant(
      id: assistantMessageId,
      text: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    conversation = await addMessage(conversationId, assistantMessage);
    yield conversation;

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

      // Add conversation history (excluding the streaming placeholder)
      for (final msg in conversation.messages) {
        if (msg.id != assistantMessageId && !msg.isError) {
          ollamaMessages.add(msg.toOllamaMessage());
        }
      }

      // Stream the response
      final buffer = StringBuffer();
      await for (final chunk in _ollama.sendChatStream(
        model: conversation.modelName,
        messages: ollamaMessages,
      )) {
        buffer.write(chunk);
        
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
        yield conversation;
      }

      // Mark streaming as complete
      assistantMessage = assistantMessage.copyWith(isStreaming: false);
      final finalMessages = conversation.messages.map((m) {
        if (m.id == assistantMessageId) return assistantMessage;
        return m;
      }).toList();

      conversation = conversation.copyWith(
        messages: finalMessages,
        updatedAt: DateTime.now(),
      );
      await updateConversation(conversation);
      yield conversation;

    } catch (e) {
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
      yield conversation;
    }
  }
}
