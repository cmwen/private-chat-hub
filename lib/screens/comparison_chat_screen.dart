import 'dart:async';
import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/comparison_conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/widgets/comparison_message_pair.dart';
import 'package:private_chat_hub/widgets/message_bubble.dart';
import 'package:private_chat_hub/widgets/message_input.dart';

/// Chat screen for comparing two models side-by-side.
class ComparisonChatScreen extends StatefulWidget {
  final ChatService? chatService;
  final ComparisonConversation? conversation;
  final VoidCallback? onBack;

  const ComparisonChatScreen({
    super.key,
    this.chatService,
    this.conversation,
    this.onBack,
  });

  @override
  State<ComparisonChatScreen> createState() => _ComparisonChatScreenState();
}

class _ComparisonChatScreenState extends State<ComparisonChatScreen> {
  List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  ComparisonConversation? _conversation;
  bool _isLoading = false;
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _loadMessages();
  }

  @override
  void didUpdateWidget(ComparisonChatScreen oldWidget) {
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animate: false);
      });
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _handleSendMessage(String text) async {
    await _handleSendMessageWithAttachments(text, []);
  }

  Future<void> _handleSendMessageWithAttachments(
    String text,
    List<Attachment> attachments,
  ) async {
    if (text.trim().isEmpty && attachments.isEmpty ||
        widget.chatService == null ||
        _conversation == null) {
      return;
    }

    setState(() => _isLoading = true);

    // Cancel existing stream subscription
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    try {
      final stream = widget.chatService!.sendDualModelMessage(
        _conversation!.id,
        text.isNotEmpty ? text : '[Attached ${attachments.length} file(s)]',
        attachments: attachments,
      );

      _streamSubscription = stream.listen(
        (updatedConversation) {
          _handleComparisonStreamUpdate(updatedConversation);
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
      if (!mounted) return;
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleStopGeneration() async {
    if (widget.chatService != null && _conversation != null) {
      await widget.chatService!.cancelMessageGeneration(_conversation!.id);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleComparisonStreamUpdate(
    ComparisonConversation updatedConversation,
  ) {
    if (!mounted) return;

    try {
      setState(() {
        _conversation = updatedConversation;
        _messages = List.from(updatedConversation.messages);
      });
      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint('[ComparisonChatScreen] Stream update handling failed: $e');
      debugPrint('$stackTrace');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Runtime update error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _conversation?.title ?? 'Model Comparison',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_conversation != null)
              Text(
                '${_conversation!.model1Name} vs ${_conversation!.model2Name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (_isLoading)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Stop generation',
              onPressed: _handleStopGeneration,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(theme)
                : _buildMessageList(theme),
          ),
          MessageInput(
            onSendMessage: _handleSendMessage,
            onSendMessageWithAttachments: _handleSendMessageWithAttachments,
            supportsVision:
                _conversation?.model1Capabilities.supportsVision == true ||
                _conversation?.model2Capabilities.supportsVision == true,
            supportsTools:
                _conversation?.model1Capabilities.supportsTools == true ||
                _conversation?.model2Capabilities.supportsTools == true,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Compare Two Models',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Send a message to compare responses from both models',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          if (_conversation != null) ...[
            _buildModelBadge(
              theme,
              'A',
              _conversation!.model1Name,
              theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _buildModelBadge(
              theme,
              'B',
              _conversation!.model2Name,
              theme.colorScheme.secondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelBadge(
    ThemeData theme,
    String label,
    String modelName,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            modelName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme) {
    if (_conversation == null) return const SizedBox.shrink();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _getDisplayItemCount(),
      itemBuilder: (context, index) => _buildMessageItem(context, index, theme),
    );
  }

  int _getDisplayItemCount() {
    // Group messages: user message followed by both model responses
    // Count user messages to determine number of display items
    final userMessages = _messages
        .where((m) => m.modelSource == ModelSource.user)
        .toList();

    return userMessages.length;
  }

  Widget _buildMessageItem(BuildContext context, int index, ThemeData theme) {
    // Get the nth user message and its corresponding model responses
    final userMessages = _messages
        .where((m) => m.modelSource == ModelSource.user)
        .toList();

    if (index >= userMessages.length) {
      return const SizedBox.shrink();
    }

    final userMessage = userMessages[index];

    // Find the corresponding model responses after this user message
    final userMessageIndex = _messages.indexOf(userMessage);
    Message? model1Response;
    Message? model2Response;

    // Look for model responses after this user message
    for (int i = userMessageIndex + 1; i < _messages.length; i++) {
      final msg = _messages[i];
      if (msg.modelSource == ModelSource.user) {
        break; // Stop at next user message
      }

      if (msg.modelSource == ModelSource.model1 && model1Response == null) {
        model1Response = msg;
      } else if (msg.modelSource == ModelSource.model2 &&
          model2Response == null) {
        model2Response = msg;
      }
    }

    return Column(
      children: [
        // User message
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: MessageBubble(message: userMessage),
          ),
        ),
        const SizedBox(height: 16),

        // Model responses comparison
        ComparisonMessagePair(
          model1Message: model1Response,
          model2Message: model2Response,
          model1Name: _conversation!.model1Name,
          model2Name: _conversation!.model2Name,
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
