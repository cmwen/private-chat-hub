import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:private_chat_hub/data/datasources/local/database_helper.dart';
import 'package:private_chat_hub/data/factories/provider_factory.dart';
import 'package:private_chat_hub/data/repositories/settings_repository.dart';
import 'package:private_chat_hub/domain/entities/connection.dart';
import 'package:private_chat_hub/domain/entities/conversation.dart';
import 'package:private_chat_hub/domain/entities/message.dart';
import 'package:private_chat_hub/domain/repositories/i_chat_provider.dart';
import 'package:private_chat_hub/core/utils/logger.dart';
import 'package:private_chat_hub/core/extensions/datetime_extensions.dart';
import 'package:private_chat_hub/presentation/screens/connection_profiles_screen.dart';
import 'package:private_chat_hub/presentation/screens/models_screen.dart';
import 'package:private_chat_hub/presentation/screens/settings_screen.dart';
import 'package:private_chat_hub/presentation/screens/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  final settingsRepo = await SettingsRepository.create();

  runApp(PrivateChatHub(dbHelper: dbHelper, settingsRepo: settingsRepo));
}

class PrivateChatHub extends StatelessWidget {
  final DatabaseHelper dbHelper;
  final SettingsRepository settingsRepo;

  const PrivateChatHub({
    super.key,
    required this.dbHelper,
    required this.settingsRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Private Chat Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: ConversationsScreen(dbHelper: dbHelper, settingsRepo: settingsRepo),
    );
  }
}

class ConversationsScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final SettingsRepository settingsRepo;

  const ConversationsScreen({
    super.key,
    required this.dbHelper,
    required this.settingsRepo,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await widget.dbHelper.getAllConversations();
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load conversations', e);
      setState(() => _loading = false);
    }
  }

  Future<void> _createConversation() async {
    final titleController = TextEditingController(text: 'New Conversation');
    final systemPromptController = TextEditingController();

    // Provider selection state
    ProviderType selectedProvider = ProviderType.ollama;

    // Ollama fields
    final ollamaModelController = TextEditingController();

    // OpenAI fields
    final openaiApiKeyController = TextEditingController();
    final openaiBaseUrlController = TextEditingController(
      text: 'https://api.openai.com/v1',
    );
    final openaiModelController = TextEditingController(text: 'gpt-3.5-turbo');

    // LiteRT fields
    final litertModelPathController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Conversation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: systemPromptController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'System Prompt (Optional)',
                    hintText: 'e.g., You are a helpful assistant...',
                    border: OutlineInputBorder(),
                    helperText: 'Customize how the AI should behave',
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                DropdownButtonFormField<ProviderType>(
                  value: selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'Provider',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ProviderType.ollama,
                      child: Text('Ollama (Local)'),
                    ),
                    DropdownMenuItem(
                      value: ProviderType.openai,
                      child: Text('OpenAI / LiteLLM'),
                    ),
                    DropdownMenuItem(
                      value: ProviderType.litert,
                      child: Text('LiteRT (On-Device)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedProvider = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Provider-specific fields
                if (selectedProvider == ProviderType.ollama) ...[
                  TextField(
                    controller: ollamaModelController,
                    decoration: const InputDecoration(
                      labelText: 'Model Name',
                      hintText: 'llama3.2',
                      border: OutlineInputBorder(),
                      helperText: 'Leave empty to use default',
                    ),
                  ),
                ],
                if (selectedProvider == ProviderType.openai) ...[
                  TextField(
                    controller: openaiBaseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://api.openai.com/v1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: openaiApiKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'sk-...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: openaiModelController,
                    decoration: const InputDecoration(
                      labelText: 'Model Name',
                      hintText: 'gpt-3.5-turbo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (selectedProvider == ProviderType.litert) ...[
                  TextField(
                    controller: litertModelPathController,
                    decoration: const InputDecoration(
                      labelText: 'Model Path',
                      hintText: '/path/to/model.bin',
                      border: OutlineInputBorder(),
                      helperText: 'Path to LiteRT model file',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Get saved default model for Ollama
        final defaultModel = await widget.settingsRepo.getDefaultModel();

        final systemPrompt = systemPromptController.text.trim().isEmpty
            ? null
            : systemPromptController.text.trim();

        // Create provider config based on selected provider
        String? providerConfig;
        String modelName = defaultModel ?? 'llama3.2';

        switch (selectedProvider) {
          case ProviderType.ollama:
            final host =
                await widget.settingsRepo.getLastConnectionHost() ??
                'localhost';
            final port =
                await widget.settingsRepo.getLastConnectionPort() ?? 11434;
            final baseUrl = 'http://$host:$port';
            providerConfig = ProviderFactory.createOllamaConfig(
              baseUrl: baseUrl,
            );
            if (ollamaModelController.text.trim().isNotEmpty) {
              modelName = ollamaModelController.text.trim();
            }
            break;

          case ProviderType.openai:
            final apiKey = openaiApiKeyController.text.trim();
            final baseUrl = openaiBaseUrlController.text.trim();
            final model = openaiModelController.text.trim();

            if (apiKey.isEmpty) {
              throw Exception('API Key is required for OpenAI provider');
            }

            providerConfig = ProviderFactory.createOpenAIConfig(
              baseUrl: baseUrl,
              apiKey: apiKey,
              model: model,
            );
            modelName = model;
            break;

          case ProviderType.litert:
            final modelPath = litertModelPathController.text.trim();

            if (modelPath.isEmpty) {
              throw Exception('Model path is required for LiteRT provider');
            }

            providerConfig = ProviderFactory.createLiteRTConfig(
              modelPath: modelPath,
            );
            modelName = modelPath.split('/').last;
            break;
        }

        final conversation = Conversation(
          id: 0,
          title: titleController.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          modelName: modelName,
          systemPrompt: systemPrompt,
          isArchived: false,
          providerType: selectedProvider,
          providerConfig: providerConfig,
        );

        final id = await widget.dbHelper.insertConversation(conversation);
        _loadConversations();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                dbHelper: widget.dbHelper,
                settingsRepo: widget.settingsRepo,
                conversationId: id,
                conversationTitle: titleController.text,
              ),
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Failed to create conversation', e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Chat Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(dbHelper: widget.dbHelper),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            tooltip: 'Models',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ModelsScreen(settingsRepo: widget.settingsRepo),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.dns),
            tooltip: 'Connection Profiles',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ConnectionProfilesScreen(dbHelper: widget.dbHelper),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    settingsRepo: widget.settingsRepo,
                    dbHelper: widget.dbHelper,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to start a new chat',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return Dismissible(
                  key: Key('conversation_${conversation.id}'),
                  background: Container(
                    color: Colors.blue,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.archive, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      // Delete
                      return await _confirmDelete(conversation);
                    } else {
                      // Archive
                      await _archiveConversation(conversation);
                      return false;
                    }
                  },
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.chat)),
                    title: Text(conversation.title),
                    subtitle: Text(
                      _formatDate(conversation.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'archive':
                            await _archiveConversation(conversation);
                            break;
                          case 'delete':
                            final confirmed = await _confirmDelete(
                              conversation,
                            );
                            if (confirmed) {
                              await _deleteConversation(conversation);
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive),
                              SizedBox(width: 8),
                              Text('Archive'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            dbHelper: widget.dbHelper,
                            settingsRepo: widget.settingsRepo,
                            conversationId: conversation.id,
                            conversationTitle: conversation.title,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createConversation,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _archiveConversation(Conversation conversation) async {
    try {
      final updated = conversation.copyWith(isArchived: true);
      await widget.dbHelper.updateConversation(updated);
      _loadConversations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Conversation archived'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                final restored = conversation.copyWith(isArchived: false);
                await widget.dbHelper.updateConversation(restored);
                _loadConversations();
              },
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to archive conversation', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<bool> _confirmDelete(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Delete "${conversation.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    try {
      await widget.dbHelper.deleteConversation(conversation.id);
      _loadConversations();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Conversation deleted')));
      }
    } catch (e) {
      AppLogger.error('Failed to delete conversation', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}

class ChatScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final SettingsRepository settingsRepo;
  final int conversationId;
  final String conversationTitle;

  const ChatScreen({
    super.key,
    required this.dbHelper,
    required this.settingsRepo,
    required this.conversationId,
    required this.conversationTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _sending = false;
  String _ollamaHost = 'http://localhost:11434';
  String _selectedModel = 'llama3.2';
  ChatProvider? _activeClient;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadMessages();
  }

  Future<void> _loadSettings() async {
    try {
      final savedHost = await widget.settingsRepo.getLastConnectionHost();
      final savedPort = await widget.settingsRepo.getLastConnectionPort();
      final savedModel = await widget.settingsRepo.getDefaultModel();

      setState(() {
        if (savedHost != null) {
          final port = savedPort ?? 11434;
          _ollamaHost = 'http://$savedHost:$port';
        }
        if (savedModel != null) {
          _selectedModel = savedModel;
        }
      });
    } catch (e) {
      AppLogger.error('Failed to load settings', e);
    }
  }

  @override
  void dispose() {
    _activeClient?.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await widget.dbHelper.getMessages(widget.conversationId);
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      AppLogger.error('Failed to load messages', e);
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _sending) return;

    final text = _controller.text.trim();
    _controller.clear();

    setState(() => _sending = true);

    try {
      final userMessage = Message(
        id: 0,
        conversationId: widget.conversationId,
        role: MessageRole.user,
        content: text,
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
      );

      final userMsgId = await widget.dbHelper.insertMessage(
        userMessage,
        widget.conversationId,
      );
      final savedUserMsg = userMessage.copyWith(id: userMsgId);

      setState(() {
        _messages.add(savedUserMsg);
      });
      _scrollToBottom();

      final assistantMessage = Message(
        id: 0,
        conversationId: widget.conversationId,
        role: MessageRole.assistant,
        content: '',
        modelName: _selectedModel,
        createdAt: DateTime.now(),
        status: MessageStatus.pending,
      );

      final assistantMsgId = await widget.dbHelper.insertMessage(
        assistantMessage,
        widget.conversationId,
      );
      final savedAssistantMsg = assistantMessage.copyWith(id: assistantMsgId);

      setState(() {
        _messages.add(savedAssistantMsg);
      });
      _scrollToBottom();

      // Load conversation and create provider using factory
      final conversation = await widget.dbHelper.getConversation(
        widget.conversationId,
      );

      if (conversation == null) {
        throw Exception('Conversation not found');
      }

      _activeClient = await ProviderFactory.createFromConversation(
        conversation,
        _ollamaHost,
      );

      final apiMessages = _messages
          .where((m) => m.id != assistantMsgId)
          .map((m) => {'role': m.role.name, 'content': m.content})
          .toList();

      final buffer = StringBuffer();

      await for (final chunk in _activeClient!.streamChat(
        model: _selectedModel,
        messages: apiMessages,
      )) {
        buffer.write(chunk);
        setState(() {
          _messages[_messages.length - 1] = savedAssistantMsg.copyWith(
            content: buffer.toString(),
            status: MessageStatus.sent,
          );
        });
        _scrollToBottom();
      }

      await widget.dbHelper.updateMessage(_messages.last);

      await _activeClient?.dispose();
      _activeClient = null;
    } catch (e) {
      AppLogger.error('Failed to send message', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            action: SnackBarAction(label: 'Retry', onPressed: _sendMessage),
          ),
        );
      }

      if (_messages.isNotEmpty &&
          _messages.last.role == MessageRole.assistant &&
          _messages.last.content.isEmpty) {
        setState(() {
          _messages.removeLast();
        });
      }
    } finally {
      setState(() => _sending = false);
      await _activeClient?.dispose();
      _activeClient = null;
    }
  }

  void _cancelStreaming() {
    if (_activeClient != null) {
      _activeClient?.dispose();
      _activeClient = null;
      setState(() => _sending = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Response cancelled')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversationTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                _showSettings();
              } else if (value == 'system_prompt') {
                _showSystemPromptDialog();
              } else if (value == 'export') {
                _showExportDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Connection Settings'),
              ),
              const PopupMenuItem(
                value: 'system_prompt',
                child: Text('System Prompt'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Conversation'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'Start the conversation...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.role == MessageRole.user;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.content.isNotEmpty)
                                Text(message.content)
                              else
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_sending,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? _cancelStreaming : _sendMessage,
                  style: FilledButton.styleFrom(
                    backgroundColor: _sending
                        ? Theme.of(context).colorScheme.error
                        : null,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _sending
                      ? const Icon(Icons.stop)
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettings() async {
    // Load current conversation to get provider type
    final conversation = await widget.dbHelper.getConversation(
      widget.conversationId,
    );

    if (conversation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load conversation')),
        );
      }
      return;
    }

    final currentProvider = conversation.providerType;
    final profiles = await widget.dbHelper.getAllConnectionProfiles();
    ConnectionProfile? selectedProfile;

    // Controllers for Ollama
    final hostController = TextEditingController(text: _ollamaHost);
    final modelController = TextEditingController(text: _selectedModel);

    // Controllers for OpenAI
    final openaiApiKeyController = TextEditingController();
    final openaiBaseUrlController = TextEditingController();
    final openaiModelController = TextEditingController();

    // Controllers for LiteRT
    final litertModelPathController = TextEditingController();

    // Pre-populate from existing config
    if (conversation.providerConfig != null) {
      try {
        final config =
            jsonDecode(conversation.providerConfig!) as Map<String, dynamic>;

        switch (currentProvider) {
          case ProviderType.ollama:
            if (config.containsKey('baseUrl')) {
              hostController.text = config['baseUrl'] as String;
            }
            break;
          case ProviderType.openai:
            openaiBaseUrlController.text = config['baseUrl'] as String? ?? '';
            openaiApiKeyController.text = config['apiKey'] as String? ?? '';
            openaiModelController.text = config['model'] as String? ?? '';
            break;
          case ProviderType.litert:
            litertModelPathController.text =
                config['modelPath'] as String? ?? '';
            break;
        }
      } catch (e) {
        AppLogger.error('Failed to parse provider config', e);
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Text('Connection Settings'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  currentProvider.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Provider-specific settings
                if (currentProvider == ProviderType.ollama) ...[
                  if (profiles.isNotEmpty) ...[
                    DropdownButtonFormField<ConnectionProfile>(
                      value: selectedProfile,
                      decoration: const InputDecoration(
                        labelText: 'Connection Profile',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select a profile'),
                      items: profiles.map((profile) {
                        return DropdownMenuItem(
                          value: profile,
                          child: Row(
                            children: [
                              if (profile.isDefault)
                                const Icon(Icons.star, size: 16),
                              if (profile.isDefault) const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  profile.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (profile) {
                        setDialogState(() {
                          selectedProfile = profile;
                          if (profile != null) {
                            hostController.text = profile.baseUrl;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConnectionProfilesScreen(
                              dbHelper: widget.dbHelper,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Manage Profiles'),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: hostController,
                    decoration: const InputDecoration(
                      labelText: 'Ollama Host',
                      hintText: 'http://localhost:11434',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model Name',
                      hintText: 'llama3.2',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (currentProvider == ProviderType.openai) ...[
                  TextField(
                    controller: openaiBaseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://api.openai.com/v1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: openaiApiKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'sk-...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: openaiModelController,
                    decoration: const InputDecoration(
                      labelText: 'Model Name',
                      hintText: 'gpt-3.5-turbo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (currentProvider == ProviderType.litert) ...[
                  TextField(
                    controller: litertModelPathController,
                    decoration: const InputDecoration(
                      labelText: 'Model Path',
                      hintText: '/path/to/model.bin',
                      border: OutlineInputBorder(),
                      helperText: 'Path to LiteRT model file',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  String? newProviderConfig;
                  String newModelName = _selectedModel;

                  // Build provider config based on current provider
                  switch (currentProvider) {
                    case ProviderType.ollama:
                      final host = hostController.text.trim();
                      final model = modelController.text.trim();

                      if (host.isEmpty) {
                        throw Exception('Ollama host is required');
                      }

                      setState(() {
                        _ollamaHost = host;
                        _selectedModel = model;
                      });

                      newProviderConfig = ProviderFactory.createOllamaConfig(
                        baseUrl: host,
                      );
                      newModelName = model;

                      // Also save to global settings
                      final uri = Uri.parse(host);
                      final hostOnly = uri.host.isNotEmpty
                          ? uri.host
                          : 'localhost';
                      final port = uri.port != 0 ? uri.port : 11434;
                      await widget.settingsRepo.setLastConnectionHost(hostOnly);
                      await widget.settingsRepo.setLastConnectionPort(port);
                      await widget.settingsRepo.setDefaultModel(model);
                      break;

                    case ProviderType.openai:
                      final baseUrl = openaiBaseUrlController.text.trim();
                      final apiKey = openaiApiKeyController.text.trim();
                      final model = openaiModelController.text.trim();

                      if (baseUrl.isEmpty) {
                        throw Exception('Base URL is required');
                      }
                      if (apiKey.isEmpty) {
                        throw Exception('API Key is required');
                      }
                      if (model.isEmpty) {
                        throw Exception('Model name is required');
                      }

                      newProviderConfig = ProviderFactory.createOpenAIConfig(
                        baseUrl: baseUrl,
                        apiKey: apiKey,
                        model: model,
                      );
                      newModelName = model;
                      break;

                    case ProviderType.litert:
                      final modelPath = litertModelPathController.text.trim();

                      if (modelPath.isEmpty) {
                        throw Exception('Model path is required');
                      }

                      newProviderConfig = ProviderFactory.createLiteRTConfig(
                        modelPath: modelPath,
                      );
                      newModelName = modelPath.split('/').last;
                      break;
                  }

                  // Update conversation with new config
                  final updatedConversation = conversation.copyWith(
                    providerConfig: newProviderConfig,
                    modelName: newModelName,
                    updatedAt: DateTime.now(),
                  );

                  await widget.dbHelper.updateConversation(updatedConversation);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  AppLogger.error('Failed to save settings', e);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to save settings: ${e.toString()}',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSystemPromptDialog() async {
    // Load current conversation to get system prompt
    final conversation = await widget.dbHelper.getConversation(
      widget.conversationId,
    );

    if (conversation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load conversation')),
        );
      }
      return;
    }

    final controller = TextEditingController(
      text: conversation.systemPrompt ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Prompt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'System Prompt',
                  hintText: 'You are a helpful assistant...',
                  border: OutlineInputBorder(),
                  helperText: 'Customize how the AI should behave',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The system prompt will be sent with every message in this conversation.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          if (controller.text.trim().isNotEmpty)
            TextButton(
              onPressed: () {
                controller.clear();
                Navigator.pop(context, true);
              },
              child: const Text('Clear'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final systemPrompt = controller.text.trim().isEmpty
            ? null
            : controller.text.trim();

        final updatedConversation = conversation.copyWith(
          systemPrompt: systemPrompt,
          updatedAt: DateTime.now(),
        );

        await widget.dbHelper.updateConversation(updatedConversation);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                systemPrompt == null
                    ? 'System prompt cleared'
                    : 'System prompt updated',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Failed to update system prompt', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: ${e.toString()}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _showExportDialog() async {
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              subtitle: const Text('Machine-readable format'),
              onTap: () => Navigator.pop(context, 'json'),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Markdown'),
              subtitle: const Text('Human-readable format'),
              onTap: () => Navigator.pop(context, 'markdown'),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Plain Text'),
              subtitle: const Text('Simple text format'),
              onTap: () => Navigator.pop(context, 'text'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (format != null && mounted) {
      await _exportConversation(format);
    }
  }

  Future<void> _exportConversation(String format) async {
    try {
      // Load conversation and messages
      final conversation = await widget.dbHelper.getConversation(
        widget.conversationId,
      );
      final messages = await widget.dbHelper.getMessages(widget.conversationId);

      if (conversation == null) {
        throw Exception('Conversation not found');
      }

      String content;

      switch (format) {
        case 'json':
          content = _exportAsJson(conversation, messages);
          break;
        case 'markdown':
          content = _exportAsMarkdown(conversation, messages);
          break;
        case 'text':
          content = _exportAsText(conversation, messages);
          break;
        default:
          throw Exception('Unknown format: $format');
      }

      // For now, just show the content in a dialog with copy option
      // In a full implementation, you'd use share or file_picker to save
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Export as ${format.toUpperCase()}'),
            content: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Copy to clipboard
                  // Clipboard.setData(ClipboardData(text: content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Content ready - implement clipboard/share for full export',
                      ),
                    ),
                  );
                },
                child: const Text('Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to export conversation', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  String _exportAsJson(Conversation conversation, List<Message> messages) {
    final data = {
      'conversation': {
        'id': conversation.id,
        'title': conversation.title,
        'created_at': conversation.createdAt.toIso8601String(),
        'updated_at': conversation.updatedAt.toIso8601String(),
        'model_name': conversation.modelName,
        'system_prompt': conversation.systemPrompt,
      },
      'messages': messages.map((msg) {
        return {
          'role': msg.role.name,
          'content': msg.content,
          'model_name': msg.modelName,
          'created_at': msg.createdAt.toIso8601String(),
          'token_count': msg.tokenCount,
        };
      }).toList(),
    };

    // Pretty print JSON
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  String _exportAsMarkdown(Conversation conversation, List<Message> messages) {
    final buffer = StringBuffer();

    buffer.writeln('# ${conversation.title}');
    buffer.writeln();
    buffer.writeln(
      '**Created:** ${conversation.createdAt.toFormattedString()}',
    );
    buffer.writeln('**Model:** ${conversation.modelName ?? 'N/A'}');
    if (conversation.systemPrompt != null) {
      buffer.writeln('**System Prompt:** ${conversation.systemPrompt}');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (final message in messages) {
      final roleIcon = message.role == MessageRole.user ? '👤' : '🤖';
      final roleName = message.role == MessageRole.user ? 'User' : 'Assistant';

      buffer.writeln('## $roleIcon $roleName');
      buffer.writeln();
      buffer.writeln(message.content);
      buffer.writeln();
      buffer.writeln('_${message.createdAt.toFormattedString()}_');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _exportAsText(Conversation conversation, List<Message> messages) {
    final buffer = StringBuffer();

    buffer.writeln('${conversation.title}');
    buffer.writeln('${'=' * conversation.title.length}');
    buffer.writeln();
    buffer.writeln('Created: ${conversation.createdAt.toFormattedString()}');
    buffer.writeln('Model: ${conversation.modelName ?? 'N/A'}');
    if (conversation.systemPrompt != null) {
      buffer.writeln('System Prompt: ${conversation.systemPrompt}');
    }
    buffer.writeln();
    buffer.writeln('-' * 80);
    buffer.writeln();

    for (final message in messages) {
      final roleName = message.role == MessageRole.user ? 'YOU' : 'ASSISTANT';

      buffer.writeln('[$roleName - ${message.createdAt.toFormattedString()}]');
      buffer.writeln();
      buffer.writeln(message.content);
      buffer.writeln();
      buffer.writeln('-' * 80);
      buffer.writeln();
    }

    return buffer.toString();
  }
}
