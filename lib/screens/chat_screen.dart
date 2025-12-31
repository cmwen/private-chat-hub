import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/widgets/message_bubble.dart';
import 'package:private_chat_hub/widgets/message_input.dart';

/// Main chat screen displaying messages and input field.
class ChatScreen extends StatefulWidget {
  final ChatService? chatService;
  final Conversation? conversation;
  final VoidCallback? onBack;

  const ChatScreen({
    super.key,
    this.chatService,
    this.conversation,
    this.onBack,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  Conversation? _conversation;
  bool _isLoading = false;
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _loadMessages();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversation?.id != oldWidget.conversation?.id) {
      _conversation = widget.conversation;
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _loadMessages() {
    if (_conversation != null) {
      setState(() {
        _messages = List.from(_conversation!.messages);
      });
      _scrollToBottom();
    } else {
      // Demo mode - load sample messages
      setState(() {
        _messages = [
          Message(
            id: '1',
            text: 'Hello! I\'m your AI assistant. How can I help you today?',
            isMe: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            role: MessageRole.assistant,
          ),
        ];
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // If no chat service or conversation, use demo mode
    if (widget.chatService == null || _conversation == null) {
      _handleDemoMessage(text);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Cancel any existing stream
      await _streamSubscription?.cancel();

      // Start streaming response
      _streamSubscription = widget.chatService!
          .sendMessage(_conversation!.id, text)
          .listen(
        (updatedConversation) {
          setState(() {
            _conversation = updatedConversation;
            _messages = List.from(updatedConversation.messages);
          });
          _scrollToBottom();
        },
        onError: (error) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onDone: () {
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDemoMessage(String text) {
    final userMessage = Message.user(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
    });
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 500), () {
      final aiMessage = Message.assistant(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: _getDemoResponse(text),
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
      });
      _scrollToBottom();
    });
  }

  String _getDemoResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi')) {
      return 'Hello! Great to hear from you. What would you like to discuss?';
    } else if (lower.contains('help')) {
      return 'I\'m here to help! You can ask me questions, have a conversation, or explore topics together. '
          'To get started with real AI responses, configure your Ollama connection in Settings.';
    } else if (lower.contains('ollama')) {
      return 'Ollama is a great way to run large language models locally. '
          'Make sure you have Ollama installed and running, then add your connection in Settings. '
          'Once connected, you can chat with models like Llama, Mistral, and more!';
    } else {
      return 'This is a demo response. To get real AI responses, please:\n\n'
          '1. Install and run Ollama on your computer or server\n'
          '2. Go to Settings and add your Ollama connection\n'
          '3. Select a model and start a new conversation\n\n'
          'Your message was: "$userMessage"';
    }
  }

  void _handleSendMessageWithAttachments(String text, List<Attachment> attachments) {
    if (text.isEmpty && attachments.isEmpty) return;

    // If no chat service or conversation, use demo mode
    if (widget.chatService == null || _conversation == null) {
      _handleDemoMessageWithAttachments(text, attachments);
      return;
    }

    // For now, send as regular message with attachments
    _sendMessageWithAttachments(text, attachments);
  }

  void _handleDemoMessageWithAttachments(String text, List<Attachment> attachments) {
    final displayText = attachments.isNotEmpty
        ? (text.isNotEmpty ? text : '[Image attached]')
        : text;

    final userMessage = Message.user(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: displayText,
      timestamp: DateTime.now(),
      attachments: attachments,
    );

    setState(() {
      _messages.add(userMessage);
    });
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 500), () {
      String response;
      if (attachments.any((a) => a.isImage)) {
        response = 'I can see you\'ve attached ${attachments.length} image(s). '
            'In demo mode, I can\'t analyze images. To use vision capabilities, '
            'please connect to an Ollama instance with a vision model like LLaVA.';
      } else {
        response = _getDemoResponse(text);
      }

      final aiMessage = Message.assistant(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: response,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
      });
      _scrollToBottom();
    });
  }

  Future<void> _sendMessageWithAttachments(String text, List<Attachment> attachments) async {
    setState(() => _isLoading = true);

    try {
      await _streamSubscription?.cancel();

      // Create user message with attachments
      final userMessage = Message.user(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text.isNotEmpty ? text : '[Attached ${attachments.length} image(s)]',
        timestamp: DateTime.now(),
        attachments: attachments,
      );

      // Add user message to conversation
      var conversation = await widget.chatService!.addMessage(_conversation!.id, userMessage);
      setState(() {
        _conversation = conversation;
        _messages = List.from(conversation.messages);
      });
      _scrollToBottom();

      // Now stream the AI response using the service's internal logic
      _streamSubscription = widget.chatService!
          .sendMessageWithContext(_conversation!.id)
          .listen(
        (updatedConversation) {
          setState(() {
            _conversation = updatedConversation;
            _messages = List.from(updatedConversation.messages);
          });
          _scrollToBottom();
        },
        onError: (error) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onDone: () {
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConversationInfo() {
    if (_conversation == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  const Text(
                    'Conversation Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const Divider(height: 24),
              _InfoRow('Title', _conversation!.title),
              _InfoRow('Model', _conversation!.modelName),
              _InfoRow('Messages', '${_conversation!.messageCount}'),
              _InfoRow('Created', _formatDateTime(_conversation!.createdAt)),
              _InfoRow('Last Updated', _formatDateTime(_conversation!.updatedAt)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'System Prompt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showEditSystemPrompt();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _conversation!.systemPrompt ?? 'No system prompt set',
                  style: TextStyle(
                    color: _conversation!.systemPrompt != null
                        ? Colors.black87
                        : Colors.grey,
                    fontStyle: _conversation!.systemPrompt != null
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSystemPrompt() {
    if (_conversation == null) return;

    final controller = TextEditingController(
      text: _conversation!.systemPrompt ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit System Prompt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The system prompt provides instructions for how the AI should behave.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter system prompt...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (widget.chatService != null && _conversation != null) {
                final updatedConversation = _conversation!.copyWith(
                  systemPrompt: controller.text.isEmpty 
                      ? null 
                      : controller.text,
                  updatedAt: DateTime.now(),
                );
                await widget.chatService!.updateConversation(updatedConversation);
                setState(() {
                  _conversation = updatedConversation;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('System prompt updated')),
                  );
                }
              }
              controller.dispose();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(
                Icons.psychology,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conversation?.title ?? 'Chat',
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _conversation?.modelName ?? 'Demo Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_conversation != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showConversationInfo,
              tooltip: 'Conversation info',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Clear chat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final showTimestamp = index == 0 ||
                          _messages[index - 1]
                                  .timestamp
                                  .difference(message.timestamp)
                                  .inMinutes
                                  .abs() >
                              5;

                      return _MessageItem(
                        message: message,
                        showTimestamp: showTimestamp,
                        onLongPress: () => _showMessageActions(message),
                        onCopy: () => _copyMessage(message),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          MessageInput(
            onSendMessage: _handleSendMessage,
            onSendMessageWithAttachments: _handleSendMessageWithAttachments,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (_conversation != null && widget.chatService != null) {
                await widget.chatService!.clearConversation(_conversation!.id);
                _conversation = widget.chatService!.getConversation(_conversation!.id);
                _loadMessages();
              } else {
                setState(() {
                  _messages.clear();
                });
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _copyMessage(Message message) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteMessage(Message message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _messages.removeWhere((m) => m.id == message.id);
              });
              if (_conversation != null && widget.chatService != null) {
                widget.chatService!.deleteMessage(_conversation!.id, message.id);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _retryMessage(Message message) {
    if (message.role == MessageRole.user) {
      // Retry sending the user message
      _handleSendMessage(message.text);
    }
  }

  void _showMessageActions(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(sheetContext);
                _copyMessage(message);
              },
            ),
            if (message.role == MessageRole.user && message.isError)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _retryMessage(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                _deleteMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final Message message;
  final bool showTimestamp;
  final VoidCallback? onLongPress;
  final VoidCallback? onCopy;

  const _MessageItem({
    required this.message,
    required this.showTimestamp,
    this.onLongPress,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    // Use markdown rendering for AI responses
    if (message.role == MessageRole.assistant && !message.isError) {
      return GestureDetector(
        onLongPress: onLongPress,
        child: _MarkdownMessageBubble(
          message: message,
          showTimestamp: showTimestamp,
          onCopy: onCopy,
        ),
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: MessageBubble(
        message: message,
        showTimestamp: showTimestamp,
      ),
    );
  }
}

class _MarkdownMessageBubble extends StatelessWidget {
  final Message message;
  final bool showTimestamp;
  final VoidCallback? onCopy;

  const _MarkdownMessageBubble({
    required this.message,
    required this.showTimestamp,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.secondary,
              child: const Icon(Icons.psychology, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: message.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 15, color: Colors.black87),
                        code: TextStyle(
                          backgroundColor: Colors.grey[300],
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (message.isStreaming)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Generating...',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!message.isStreaming && onCopy != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: InkWell(
                          onTap: onCopy,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
