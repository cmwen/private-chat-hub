import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/screens/search_screen.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/widgets/dual_model_selector.dart';
import 'package:intl/intl.dart';

/// Screen showing the list of conversations.
class ConversationListScreen extends StatefulWidget {
  final ChatService chatService;
  final ConnectionService connectionService;
  final OllamaConnectionManager ollamaManager;
  final Function(Conversation) onConversationSelected;
  final VoidCallback onNewConversation;

  const ConversationListScreen({
    super.key,
    required this.chatService,
    required this.connectionService,
    required this.ollamaManager,
    required this.onConversationSelected,
    required this.onNewConversation,
  });

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<Conversation> _conversations = [];
  List<OllamaModelInfo> _models = [];
  String? _selectedModel;
  bool _isLoading = true;
  bool _isLoadingModels = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Only show standalone conversations (not in projects) in the main list
    _conversations = widget.chatService.getConversations(
      excludeProjectConversations: true,
    );
    _selectedModel = widget.connectionService.getSelectedModel();

    // Try to load models from Ollama
    await _loadModels();

    setState(() => _isLoading = false);
  }

  Future<void> _loadModels() async {
    final connection = widget.connectionService.getDefaultConnection();
    if (connection == null) return;

    setState(() => _isLoadingModels = true);

    try {
      widget.ollamaManager.setConnection(connection);

      _models = await widget.ollamaManager.listModels();

      // If no model selected, select the first one
      if (_selectedModel == null && _models.isNotEmpty) {
        _selectedModel = _models.first.name;
        await widget.connectionService.setSelectedModel(_selectedModel!);
      }
    } catch (e) {
      // Failed to load models
      _models = [];
    }

    setState(() => _isLoadingModels = false);
  }

  Future<void> _createNewConversation() async {
    if (_selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a model first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dialog to optionally customize the conversation
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (dialogContext) =>
          _NewConversationDialog(modelName: _selectedModel!),
    );

    if (result == null) return; // User cancelled

    final conversation = await widget.chatService.createConversation(
      modelName: _selectedModel!,
      title: result['title'],
      systemPrompt: result['systemPrompt'],
    );

    widget.onConversationSelected(conversation);
  }

  Future<void> _createComparisonConversation() async {
    if (_models.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least 2 models to compare'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dual model selector
    await showDialog(
      context: context,
      builder: (dialogContext) => DualModelSelector(
        models: _models,
        initialModel1: _selectedModel,
        onModelsSelected: (model1, model2) async {
          // Create comparison conversation using the service method
          final conversation = await widget.chatService
              .createComparisonConversation(
                model1Name: model1,
                model2Name: model2,
              );

          if (!mounted) return;
          widget.onConversationSelected(conversation);
        },
      ),
    );
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete "${conversation.title}"?\n\n'
          'This will permanently remove all ${conversation.messageCount} messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.chatService.deleteConversation(conversation.id);
      _loadData();
    }
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          chatService: widget.chatService,
          onResultSelected: (conversation, messageId) {
            Navigator.pop(context); // Close search
            widget.onConversationSelected(conversation);
          },
        ),
      ),
    );
  }

  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => _ModelSelectorSheet(
        models: _models,
        selectedModel: _selectedModel,
        onModelSelected: (model) async {
          await widget.connectionService.setSelectedModel(model.name);
          if (!mounted) return;
          setState(() => _selectedModel = model.name);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
        isLoading: _isLoadingModels,
        onRefresh: () async {
          await _loadModels();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Model selector
                InkWell(
                  onTap: _showModelSelector,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Active Model',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _selectedModel ?? 'No model selected',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                // Conversation list
                Expanded(
                  child: _conversations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            return _ConversationTile(
                              conversation: conversation,
                              onTap: () =>
                                  widget.onConversationSelected(conversation),
                              onDelete: () => _deleteConversation(conversation),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_models.length >= 2)
            FloatingActionButton.extended(
              heroTag: 'compare_models_fab',
              onPressed: _createComparisonConversation,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Compare'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.onTertiary,
            ),
          if (_models.length >= 2) const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'conversation_list_fab',
            onPressed: _createNewConversation,
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new chat with your AI assistant',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_models.isEmpty && !_isLoadingModels)
              Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color: Colors.orange[400],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No Ollama connection configured',
                    style: TextStyle(color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Go to Settings to add a connection',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            conversation.title.isNotEmpty
                ? conversation.title[0].toUpperCase()
                : 'C',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.lastMessagePreview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.psychology, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  conversation.modelName,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const Spacer(),
                Text(
                  _formatDate(conversation.updatedAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
        trailing: Text(
          '${conversation.messageCount}',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat('MMM d').format(date);
  }
}

class _ModelSelectorSheet extends StatelessWidget {
  final List<OllamaModelInfo> models;
  final String? selectedModel;
  final Function(OllamaModelInfo) onModelSelected;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _ModelSelectorSheet({
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Select Model',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                  ),
              ],
            ),
          ),
          const Divider(),
          if (models.isEmpty && !isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.warning_amber, size: 48, color: Colors.orange),
                  SizedBox(height: 16),
                  Text('No models found', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    'Make sure Ollama is running and has models downloaded',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: models.length,
                itemBuilder: (context, index) {
                  final model = models[index];
                  final isSelected = model.name == selectedModel;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      child: Icon(
                        Icons.psychology,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    title: Text(model.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${model.sizeFormatted}${model.parameterCount != null ? ' • ${model.parameterCount}' : ''}',
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            if (model.capabilities.supportsVision)
                              _CapabilityBadge(
                                icon: Icons.visibility,
                                label: 'Vision',
                                color: Colors.purple,
                              ),
                            if (model.capabilities.supportsTools)
                              _CapabilityBadge(
                                icon: Icons.build,
                                label: 'Tools',
                                color: Colors.blue,
                              ),
                            if (model.capabilities.supportsCode)
                              _CapabilityBadge(
                                icon: Icons.code,
                                label: 'Code',
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () => onModelSelected(model),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Dialog for creating a new conversation with optional customization.
class _NewConversationDialog extends StatefulWidget {
  final String modelName;

  const _NewConversationDialog({required this.modelName});

  @override
  State<_NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<_NewConversationDialog> {
  final _titleController = TextEditingController();
  final _systemPromptController = TextEditingController();
  bool _showAdvanced = false;

  static const List<Map<String, String>> _presetPrompts = [
    {
      'name': 'Default Assistant',
      'prompt': 'You are a helpful, harmless, and honest AI assistant.',
    },
    {
      'name': 'Code Expert',
      'prompt':
          'You are an expert programmer. Provide clear, well-documented code examples. '
          'Explain your reasoning and suggest best practices.',
    },
    {
      'name': 'Creative Writer',
      'prompt':
          'You are a creative writing assistant. Help users craft compelling stories, '
          'poems, and other creative content. Be imaginative and expressive.',
    },
    {
      'name': 'Tutor',
      'prompt':
          'You are a patient and encouraging tutor. Break down complex topics into '
          'simple steps. Ask questions to check understanding and provide examples.',
    },
    {
      'name': 'Concise Mode',
      'prompt':
          'Be concise. Answer directly and briefly. Avoid unnecessary explanations.',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Conversation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model: ${widget.modelName}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'Auto-generated from first message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Advanced options toggle
            InkWell(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Row(
                children: [
                  Icon(
                    _showAdvanced ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Advanced Options',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              const Text(
                'System Prompt',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              // Preset prompts
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetPrompts.map((preset) {
                  return ActionChip(
                    label: Text(preset['name']!),
                    onPressed: () {
                      _systemPromptController.text = preset['prompt']!;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _systemPromptController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter custom instructions for the AI...',
                  border: OutlineInputBorder(),
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
          onPressed: () {
            Navigator.pop(context, {
              'title': _titleController.text.isEmpty
                  ? null
                  : _titleController.text,
              'systemPrompt': _systemPromptController.text.isEmpty
                  ? null
                  : _systemPromptController.text,
            });
          },
          child: const Text('Start Chat'),
        ),
      ],
    );
  }
}

/// Small badge for displaying model capabilities.
class _CapabilityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CapabilityBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
