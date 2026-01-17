import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/tool_models.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/connectivity_service.dart';
import 'package:private_chat_hub/services/tts_service.dart';
import 'package:private_chat_hub/widgets/capability_widgets.dart';
import 'package:private_chat_hub/widgets/message_bubble.dart';
import 'package:private_chat_hub/widgets/message_input.dart';
import 'package:private_chat_hub/widgets/queue_status_banner.dart';

/// Main chat screen displaying messages and input field.
class ChatScreen extends StatefulWidget {
  final ChatService? chatService;
  final Conversation? conversation;
  final VoidCallback? onBack;
  final ToolConfig? toolConfig;

  const ChatScreen({
    super.key,
    this.chatService,
    this.conversation,
    this.onBack,
    this.toolConfig,
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
  final TtsService _ttsService = TtsService();
  bool _ttsStreamingEnabled = false;
  String? _lastSpokenText;

  // Offline mode state
  OllamaConnectivityStatus _connectivityStatus =
      OllamaConnectivityStatus.checking;
  int _queuedMessageCount = 0;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _queueSubscription;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _ttsService.initialize();
    // Register callback to rebuild UI when TTS state changes
    _ttsService.setOnStateChanged(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadMessages();
    _setupConnectivityListener();
    _setupQueueListener();
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
    _ttsService.dispose();
    // Don't cancel the stream - let it continue in the background
    _streamSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _queueSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if there's an active stream we can reconnect to
    if (widget.chatService != null && _conversation != null) {
      final activeStream = widget.chatService!.getActiveStream(
        _conversation!.id,
      );
      if (activeStream != null && _streamSubscription == null) {
        // Reconnect to the active stream
        _reconnectToActiveStream();
      }
    }
  }

  void _reconnectToActiveStream() {
    if (widget.chatService == null || _conversation == null) return;

    final activeStream = widget.chatService!.getActiveStream(_conversation!.id);
    if (activeStream != null) {
      setState(() => _isLoading = true);
      _streamSubscription = activeStream.listen(
        (updatedConversation) {
          if (!mounted) return;
          setState(() {
            _conversation = updatedConversation;
            _messages = List.from(updatedConversation.messages);
          });
          _scrollToBottom();
          _handleTtsStreaming(updatedConversation);
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _isLoading = false);
        },
      );
    }
  }

  void _loadMessages() {
    if (_conversation != null) {
      setState(() {
        _messages = List.from(_conversation!.messages);
        // Check if there's an active generation
        if (widget.chatService != null) {
          _isLoading = widget.chatService!.isGenerating(_conversation!.id);
        }
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

  void _setupConnectivityListener() {
    if (widget.chatService == null) return;

    // Get initial status
    _connectivityStatus = widget.chatService!.connectivityService.currentStatus;

    // Listen for changes
    _connectivitySubscription = widget
        .chatService!
        .connectivityService
        .statusStream
        .listen((status) {
          if (!mounted) return;
          setState(() {
            _connectivityStatus = status;
          });

          // Show snackbar when status changes
          if (status == OllamaConnectivityStatus.connected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connected. Sending queued messages...'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          } else if (status == OllamaConnectivityStatus.offline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection lost. Messages will be queued.'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
  }

  void _setupQueueListener() {
    if (widget.chatService == null || _conversation == null) return;

    // Get initial count
    _queuedMessageCount = widget.chatService!.getQueuedMessageCount(
      _conversation!.id,
    );

    // Listen for queue updates
    _queueSubscription = widget.chatService!.queueService.queueUpdates.listen((
      queue,
    ) {
      if (!mounted || _conversation == null) return;

      final newCount = queue
          .where((item) => item.conversationId == _conversation!.id)
          .length;
      setState(() {
        _queuedMessageCount = newCount;
      });
    });
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
      // Cancel existing subscription (but not the underlying stream)
      await _streamSubscription?.cancel();
      _streamSubscription = null;

      // Start streaming response
      _streamSubscription = widget.chatService!
          .sendMessage(_conversation!.id, text)
          .listen(
            (updatedConversation) {
              if (!mounted) return;
              setState(() {
                _conversation = updatedConversation;
                _messages = List.from(updatedConversation.messages);
              });
              _scrollToBottom();
              _handleTtsStreaming(updatedConversation);
            },
            onError: (error) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            onDone: () {
              if (!mounted) return;
              setState(() => _isLoading = false);
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRetryMessage(Message message) async {
    if (widget.chatService == null || _conversation == null) return;

    try {
      await widget.chatService!.retryFailedMessage(message.id);

      // Reload messages
      final updatedConversation = widget.chatService!.getConversation(
        _conversation!.id,
      );
      if (updatedConversation != null && mounted) {
        setState(() {
          _conversation = updatedConversation;
          _messages = List.from(updatedConversation.messages);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message retry initiated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCancelMessage(Message message) async {
    if (widget.chatService == null || _conversation == null) return;

    try {
      await widget.chatService!.cancelQueuedMessage(message.id);

      // Reload messages
      final updatedConversation = widget.chatService!.getConversation(
        _conversation!.id,
      );
      if (updatedConversation != null && mounted) {
        setState(() {
          _conversation = updatedConversation;
          _messages = List.from(updatedConversation.messages);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Queued message cancelled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancel failed: $e'),
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

    if (!mounted) return;
    setState(() {
      _messages.add(userMessage);
    });
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
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

  void _handleSendMessageWithAttachments(
    String text,
    List<Attachment> attachments,
  ) {
    if (text.isEmpty && attachments.isEmpty) return;

    // If no chat service or conversation, use demo mode
    if (widget.chatService == null || _conversation == null) {
      _handleDemoMessageWithAttachments(text, attachments);
      return;
    }

    // For now, send as regular message with attachments
    _sendMessageWithAttachments(text, attachments);
  }

  void _handleDemoMessageWithAttachments(
    String text,
    List<Attachment> attachments,
  ) {
    final displayText = attachments.isNotEmpty
        ? (text.isNotEmpty ? text : '[Image attached]')
        : text;

    final userMessage = Message.user(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: displayText,
      timestamp: DateTime.now(),
      attachments: attachments,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(userMessage);
    });
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      String response;
      if (attachments.any((a) => a.isImage)) {
        response =
            'I can see you\'ve attached ${attachments.length} image(s). '
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

  Future<void> _sendMessageWithAttachments(
    String text,
    List<Attachment> attachments,
  ) async {
    setState(() => _isLoading = true);

    try {
      // Cancel existing subscription (but not the underlying stream)
      await _streamSubscription?.cancel();
      _streamSubscription = null;

      // Create user message with attachments
      final userMessage = Message.user(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text.isNotEmpty
            ? text
            : '[Attached ${attachments.length} image(s)]',
        timestamp: DateTime.now(),
        attachments: attachments,
      );

      // Add user message to conversation
      var conversation = await widget.chatService!.addMessage(
        _conversation!.id,
        userMessage,
      );
      if (!mounted) return;
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
              if (!mounted) return;
              setState(() {
                _conversation = updatedConversation;
                _messages = List.from(updatedConversation.messages);
              });
              _scrollToBottom();
              _handleTtsStreaming(updatedConversation);
            },
            onError: (error) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            onDone: () {
              if (!mounted) return;
              setState(() => _isLoading = false);
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stopGeneration() async {
    if (widget.chatService == null || _conversation == null) return;

    try {
      await widget.chatService!.cancelMessageGeneration(_conversation!.id);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping generation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle TTS streaming mode - speak text as it arrives.
  void _handleTtsStreaming(Conversation conversation) {
    if (!_ttsStreamingEnabled) return;

    // Find the last assistant message
    final lastMessage = conversation.messages.lastWhere(
      (m) => m.role == MessageRole.assistant,
      orElse: () =>
          Message.assistant(id: '', text: '', timestamp: DateTime.now()),
    );

    if (lastMessage.id.isEmpty) return;

    // Only speak if the text has changed significantly
    if (_lastSpokenText != null &&
        lastMessage.text.startsWith(_lastSpokenText!)) {
      // Text is still being appended, check if we have enough new content
      final newContent = lastMessage.text
          .substring(_lastSpokenText!.length)
          .trim();

      // Speak when we have a sentence or significant chunk
      if (newContent.length > 50 ||
          newContent.endsWith('.') ||
          newContent.endsWith('!') ||
          newContent.endsWith('?')) {
        _lastSpokenText = lastMessage.text;
        _ttsService.speak(newContent, messageId: lastMessage.id);
      }
    } else if (_lastSpokenText == null || _lastSpokenText!.isEmpty) {
      // First chunk of text
      _lastSpokenText = lastMessage.text;
      if (lastMessage.text.isNotEmpty) {
        _ttsService.speak(lastMessage.text, messageId: lastMessage.id);
      }
    }

    // Reset when message is no longer streaming
    if (!lastMessage.isStreaming && _lastSpokenText != null) {
      _lastSpokenText = null;
    }
  }

  /// Speak a complete message.
  Future<void> _speakMessage(Message message) async {
    final success = await _ttsService.speak(
      message.text,
      messageId: message.id,
      speed: widget.toolConfig?.ttsSpeed,
    );

    if (mounted) {
      setState(() {});

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize text-to-speech'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Stop TTS playback.
  void _stopTts() {
    _ttsService.stop();
    setState(() {});
  }

  /// Toggle TTS streaming mode.
  void _toggleTtsStreaming(bool enabled) {
    setState(() {
      _ttsStreamingEnabled = enabled;
      if (!enabled) {
        _ttsService.stop();
        _lastSpokenText = null;
      }
    });

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'TTS streaming enabled - AI responses will be read aloud'
              : 'TTS streaming disabled',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleToolCalling(bool enabled) {
    if (widget.chatService == null || _conversation == null) return;

    setState(() {
      _conversation = _conversation!.copyWith(
        toolCallingEnabled: enabled,
        updatedAt: DateTime.now(),
      );
    });

    widget.chatService!.updateConversation(_conversation!);

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'Tool calling enabled' : 'Tool calling disabled',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showCapabilityInfo() {
    if (_conversation == null) return;

    showCapabilityInfo(
      context,
      modelName: _conversation!.modelName,
      capabilities: _conversation!.modelCapabilities,
      toolCallingEnabled: _conversation!.toolCallingEnabled,
      onToggleToolCalling: (enabled) {
        Navigator.pop(context);
        _toggleToolCalling(enabled);
      },
      onConfigureTools: () {
        Navigator.pop(context);
        // TODO: Navigate to tool settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tool configuration coming soon')),
        );
      },
    );
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              _InfoRow(
                'Last Updated',
                _formatDateTime(_conversation!.updatedAt),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'System Prompt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _conversation!.systemPrompt ?? 'No system prompt set',
                  style: TextStyle(
                    color: _conversation!.systemPrompt != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: _conversation!.systemPrompt != null
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Model Parameters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Adjust'),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showModelParameters();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ParameterDisplay(
                label: 'Temperature',
                value: _conversation!.parameters.temperature.toStringAsFixed(1),
                description: 'Creativity (0=focused, 2=random)',
              ),
              _ParameterDisplay(
                label: 'Top-K',
                value: '${_conversation!.parameters.topK}',
                description: 'Token diversity',
              ),
              _ParameterDisplay(
                label: 'Top-P',
                value: _conversation!.parameters.topP.toStringAsFixed(2),
                description: 'Nucleus sampling',
              ),
              _ParameterDisplay(
                label: 'Max Tokens',
                value: '${_conversation!.parameters.maxTokens}',
                description: 'Response length limit',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showModelParameters() {
    if (_conversation == null) return;

    var params = _conversation!.parameters;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => Container(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune),
                    const SizedBox(width: 12),
                    const Text(
                      'Model Parameters',
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
                // Presets
                const Text(
                  'Quick Presets',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _PresetChip(
                      label: '⚖️ Balanced',
                      isSelected: params.temperature == 0.7,
                      onTap: () {
                        setSheetState(() => params = ModelParameters.balanced);
                      },
                    ),
                    _PresetChip(
                      label: '🎨 Creative',
                      isSelected: params.temperature == 1.2,
                      onTap: () {
                        setSheetState(() => params = ModelParameters.creative);
                      },
                    ),
                    _PresetChip(
                      label: '🎯 Precise',
                      isSelected: params.temperature == 0.3,
                      onTap: () {
                        setSheetState(() => params = ModelParameters.precise);
                      },
                    ),
                    _PresetChip(
                      label: '💻 Code',
                      isSelected: params.temperature == 0.2,
                      onTap: () {
                        setSheetState(() => params = ModelParameters.code);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Temperature
                _ParameterSlider(
                  label: 'Temperature',
                  value: params.temperature,
                  min: 0.0,
                  max: 2.0,
                  divisions: 20,
                  description:
                      'Controls randomness. Lower = more focused, Higher = more creative.',
                  onChanged: (v) {
                    setSheetState(
                      () => params = params.copyWith(temperature: v),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Top-K
                _ParameterSlider(
                  label: 'Top-K',
                  value: params.topK.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  description: 'Limits vocabulary to top K tokens per step.',
                  isInteger: true,
                  onChanged: (v) {
                    setSheetState(
                      () => params = params.copyWith(topK: v.round()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Top-P
                _ParameterSlider(
                  label: 'Top-P',
                  value: params.topP,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  description: 'Nucleus sampling. Lower = more focused.',
                  onChanged: (v) {
                    setSheetState(() => params = params.copyWith(topP: v));
                  },
                ),
                const SizedBox(height: 16),
                // Max Tokens
                _ParameterSlider(
                  label: 'Max Tokens',
                  value: params.maxTokens.toDouble(),
                  min: 100,
                  max: 8000,
                  divisions: 79,
                  description:
                      'Maximum response length. ~750 words per 1000 tokens.',
                  isInteger: true,
                  onChanged: (v) {
                    setSheetState(
                      () => params = params.copyWith(maxTokens: v.round()),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setSheetState(
                            () => params = ModelParameters.balanced,
                          );
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          if (widget.chatService != null &&
                              _conversation != null) {
                            final updatedConversation = _conversation!.copyWith(
                              parameters: params,
                              updatedAt: DateTime.now(),
                            );
                            final messenger = ScaffoldMessenger.of(context);
                            await widget.chatService!.updateConversation(
                              updatedConversation,
                            );
                            if (!mounted) return;
                            setState(() {
                              _conversation = updatedConversation;
                            });
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Parameters updated'),
                              ),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
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
                await widget.chatService!.updateConversation(
                  updatedConversation,
                );
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _conversation?.modelName ?? 'Demo Mode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_conversation != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: CapabilityBadges(
                              capabilities: _conversation!.modelCapabilities,
                              onInfoTap: () => _showCapabilityInfo(),
                            ),
                          ),
                        ),
                      ],
                    ],
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
          IconButton(
            icon: Icon(
              _ttsStreamingEnabled
                  ? Icons.record_voice_over
                  : Icons.voice_over_off,
            ),
            onPressed: () => _toggleTtsStreaming(!_ttsStreamingEnabled),
            tooltip: _ttsStreamingEnabled
                ? 'Disable TTS streaming'
                : 'Enable TTS streaming',
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
          // Queue status banner (offline mode)
          if (widget.chatService != null && _conversation != null)
            QueueStatusBanner(
              queuedCount: _queuedMessageCount,
              isProcessing:
                  widget.chatService!.queueService.getQueueCount() > 0 &&
                  _connectivityStatus == OllamaConnectivityStatus.connected,
              onRetryNow: () {
                widget.chatService!.connectivityService.refresh();
              },
            ),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final showTimestamp =
                          index == 0 ||
                          _messages[index - 1].timestamp
                                  .difference(message.timestamp)
                                  .inMinutes
                                  .abs() >
                              5;

                      return _MessageItem(
                        message: message,
                        showTimestamp: showTimestamp,
                        onLongPress: () => _showMessageActions(message),
                        onCopy: () => _copyMessage(message),
                        onSpeak: () => _speakMessage(message),
                        onStopTts: _stopTts,
                        isSpeaking: _ttsService.isSpeakingMessage(message.id),
                        onRetry:
                            message.status == MessageStatus.failed &&
                                widget.chatService != null
                            ? () => _handleRetryMessage(message)
                            : null,
                        onCancel:
                            message.status == MessageStatus.queued &&
                                widget.chatService != null
                            ? () => _handleCancelMessage(message)
                            : null,
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
                    _conversation?.modelCapabilities.supportsTools == true
                        ? 'AI is thinking with tools...'
                        : 'AI is thinking...',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  if (_conversation?.modelCapabilities.supportsTools ==
                      true) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.build_circle,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          MessageInput(
            onSendMessage: _handleSendMessage,
            onSendMessageWithAttachments: _handleSendMessageWithAttachments,
            supportsVision:
                _conversation?.modelCapabilities.supportsVision ?? false,
            supportsTools:
                _conversation?.modelCapabilities.supportsTools ?? false,
            toolCallingEnabled: _conversation?.toolCallingEnabled ?? true,
            isLoading: _isLoading,
            onStopGeneration: _isLoading ? _stopGeneration : null,
            onToggleToolCalling: _conversation != null
                ? (enabled) => _toggleToolCalling(enabled)
                : null,
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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              if (!mounted) return;
              if (_conversation != null && widget.chatService != null) {
                await widget.chatService!.clearConversation(_conversation!.id);
                if (!mounted) return;
                _conversation = widget.chatService!.getConversation(
                  _conversation!.id,
                );
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
              if (!mounted) return;
              setState(() {
                _messages.removeWhere((m) => m.id == message.id);
              });
              if (_conversation != null && widget.chatService != null) {
                widget.chatService!.deleteMessage(
                  _conversation!.id,
                  message.id,
                );
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

  void _editMessage(Message message) {
    // Show dialog with the message text for editing
    final controller = TextEditingController(text: message.text);

    showDialog(
      context: context,
      builder: (dialogContext) => _EditMessageDialog(
        controller: controller,
        message: message,
        onSend: (newText) {
          if (newText.isNotEmpty && newText != message.text) {
            // Send as a new message (preserving history)
            _handleSendMessage(newText);
          }
        },
      ),
    );
  }

  void _showMessageActions(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.copy,
                color: Theme.of(sheetContext).colorScheme.onSurface,
              ),
              title: Text(
                'Copy',
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _copyMessage(message);
              },
            ),
            if (message.role == MessageRole.assistant)
              ListTile(
                leading: Icon(
                  _ttsService.isSpeakingMessage(message.id)
                      ? Icons.stop
                      : Icons.volume_up,
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
                title: Text(
                  _ttsService.isSpeakingMessage(message.id)
                      ? 'Stop Speaking'
                      : 'Speak Message',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (_ttsService.isSpeakingMessage(message.id)) {
                    _stopTts();
                  } else {
                    _speakMessage(message);
                  }
                },
              ),
            if (message.role == MessageRole.user)
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
                title: Text(
                  'Edit & Resend',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Creates a new message',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _editMessage(message);
                },
              ),
            if (message.role == MessageRole.user && message.isError)
              ListTile(
                leading: Icon(
                  Icons.refresh,
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
                title: Text(
                  'Retry',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _retryMessage(message);
                },
              ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
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
  final VoidCallback? onSpeak;
  final VoidCallback? onStopTts;
  final bool isSpeaking;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const _MessageItem({
    required this.message,
    required this.showTimestamp,
    this.onLongPress,
    this.onCopy,
    this.onSpeak,
    this.onStopTts,
    this.isSpeaking = false,
    this.onRetry,
    this.onCancel,
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
          onSpeak: onSpeak,
          onStopTts: onStopTts,
          isSpeaking: isSpeaking,
        ),
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: MessageBubble(
        message: message,
        showTimestamp: showTimestamp,
        onRetry: onRetry,
        onCancel: onCancel,
      ),
    );
  }
}

class _MarkdownMessageBubble extends StatelessWidget {
  final Message message;
  final bool showTimestamp;
  final VoidCallback? onCopy;
  final VoidCallback? onSpeak;
  final VoidCallback? onStopTts;
  final bool isSpeaking;

  const _MarkdownMessageBubble({
    required this.message,
    required this.showTimestamp,
    this.onCopy,
    this.onSpeak,
    this.onStopTts,
    this.isSpeaking = false,
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
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
              child: const Icon(
                Icons.psychology,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                        p: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        code: TextStyle(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainer,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
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
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!message.isStreaming && onCopy != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: onCopy,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (onSpeak != null && onStopTts != null) ...[
                              const SizedBox(width: 16),
                              InkWell(
                                onTap: isSpeaking ? onStopTts : onSpeak,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSpeaking ? Icons.stop : Icons.volume_up,
                                      size: 14,
                                      color: isSpeaking
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSpeaking ? 'Stop' : 'Speak',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSpeaking
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ParameterDisplay extends StatelessWidget {
  final String label;
  final String value;
  final String description;

  const _ParameterDisplay({
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      onPressed: onTap,
    );
  }
}

class _ParameterSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String description;
  final bool isInteger;
  final ValueChanged<double> onChanged;

  const _ParameterSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.description,
    this.isInteger = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              isInteger ? value.round().toString() : value.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Dialog for editing a message before resending.
class _EditMessageDialog extends StatefulWidget {
  final TextEditingController controller;
  final Message message;
  final Function(String) onSend;

  const _EditMessageDialog({
    required this.controller,
    required this.message,
    required this.onSend,
  });

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  @override
  void dispose() {
    // Properly dispose the controller when dialog is disposed
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Message'),
      content: TextField(
        controller: widget.controller,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Edit your message...',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final newText = widget.controller.text.trim();
            Navigator.pop(context);
            widget.onSend(newText);
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}
