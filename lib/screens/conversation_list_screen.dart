import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/screens/search_screen.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/services/unified_model_service.dart';
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
  List<OllamaModelInfo> _ollamaModels = [];
  List<ModelInfo> _allModels = []; // Combined list
  String? _selectedModel;
  bool _isLoading = true;
  bool _isLoadingModels = false;
  bool _localModelRefreshScheduled = false;
  bool _isOllamaOnline = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ConversationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.chatService.onDeviceLLMService != null &&
        !_localModelRefreshScheduled) {
      _localModelRefreshScheduled = true;
      Future.microtask(_loadModels);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Only show standalone conversations (not in projects) in the main list
    _conversations = widget.chatService.getConversations(
      excludeProjectConversations: true,
    );
    _selectedModel = widget.connectionService.getSelectedModel();

    // Show conversations immediately - don't wait for model loading
    setState(() => _isLoading = false);

    // Load models in background (non-blocking)
    _loadModels();
  }

  Future<void> _loadModels() async {
    if (mounted) setState(() => _isLoadingModels = true);

    final unifiedModelService = UnifiedModelService(
      onDeviceLLMService: widget.chatService.onDeviceLLMService,
    );

    try {
      final connection = widget.connectionService.getDefaultConnection();

      if (connection != null) {
        widget.ollamaManager.setConnection(connection);

        // Add a reasonable timeout for initial model loading (5 seconds)
        // This prevents long waits when Ollama is offline
        _ollamaModels = await widget.ollamaManager.listModels().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Connection timeout - Ollama may be offline');
          },
        );
      } else {
        _ollamaModels = [];
      }

      _isOllamaOnline = true;

      // Get unified model list (Ollama + local models)
      _allModels = await unifiedModelService.getUnifiedModelList(_ollamaModels);

      // Cache the remote models for offline fallback
      await UnifiedModelService.cacheRemoteModels(_allModels);

      // If selected model is missing or not set, select first available
      final selectedStillExists =
          _selectedModel != null &&
          _allModels.any((model) => model.id == _selectedModel);

      if ((!selectedStillExists || _selectedModel == null) &&
          _allModels.isNotEmpty) {
        _selectedModel = _allModels.first.id;
        await widget.connectionService.setSelectedModel(_selectedModel!);
      }
    } catch (e) {
      // Ollama is unreachable — use cached remote models so the user can
      // still select a remote model (messages will be queued).
      _ollamaModels = [];
      _isOllamaOnline = false;

      try {
        final cachedRemote = await UnifiedModelService.getCachedRemoteModels();
        final localModels = await unifiedModelService.getUnifiedModelList([]);
        _allModels = [...cachedRemote, ...localModels];

        // Preserve the selected model if it exists in the combined list
        // (including cached remote models). Only change selection when the
        // current selection doesn't appear at all.
        final selectedStillExists =
            _selectedModel != null &&
            _allModels.any((model) => model.id == _selectedModel);

        if ((!selectedStillExists || _selectedModel == null) &&
            _allModels.isNotEmpty) {
          _selectedModel = _allModels.first.id;
          await widget.connectionService.setSelectedModel(_selectedModel!);
        }
      } catch (localError) {
        _allModels = [];
      }
    }

    if (mounted) setState(() => _isLoadingModels = false);
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

    // Create conversation directly — title and system prompt can be adjusted
    // in the chat screen via the info/parameters buttons.
    final conversation = await widget.chatService.createConversation(
      modelName: _selectedModel!,
    );

    widget.onConversationSelected(conversation);
  }

  String _selectedModelLabel() {
    if (_selectedModel == null) return 'No model selected';

    final selected = _allModels.where((model) => model.id == _selectedModel);
    if (selected.isNotEmpty) {
      return selected.first.name;
    }

    return UnifiedModelService.getDisplayName(_selectedModel!);
  }

  Future<void> _createComparisonConversation() async {
    if (_ollamaModels.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least 2 Ollama models to compare'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dual model selector (only Ollama models for comparison)
    await showDialog(
      context: context,
      builder: (dialogContext) => DualModelSelector(
        models: _ollamaModels,
        initialModel1:
            _selectedModel != null &&
                !UnifiedModelService.isLocalModel(_selectedModel!)
            ? _selectedModel
            : null,
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
        models: _allModels,
        selectedModel: _selectedModel,
        isOllamaOnline: _isOllamaOnline,
        onModelSelected: (model) async {
          await widget.connectionService.setSelectedModel(model.id);
          if (!mounted) return;
          setState(() => _selectedModel = model.id);
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
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Model',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _selectedModelLabel(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!_isOllamaOnline &&
                                  _selectedModel != null &&
                                  !UnifiedModelService.isLocalModel(
                                    _selectedModel!,
                                  ))
                                Text(
                                  'Server offline — messages will be queued',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
          if (_ollamaModels.length >= 2)
            FloatingActionButton.extended(
              heroTag: 'compare_models_fab',
              onPressed: _createComparisonConversation,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Compare'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.onTertiary,
            ),
          if (_ollamaModels.length >= 2) const SizedBox(height: 12),
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
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new chat with your AI assistant',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_allModels.isEmpty && !_isLoadingModels)
              Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No models available',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download a local model or configure an Ollama connection in Settings',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  conversation.modelName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(conversation.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
        trailing: Text(
          '${conversation.messageCount}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
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
  final List<ModelInfo> models;
  final String? selectedModel;
  final bool isOllamaOnline;
  final Function(ModelInfo) onModelSelected;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _ModelSelectorSheet({
    required this.models,
    required this.selectedModel,
    required this.isOllamaOnline,
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
                    'Make sure local models are downloaded or Ollama is running with models available',
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
                  final isSelected = model.id == selectedModel;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        model.isLocal ? Icons.phone_android : Icons.cloud,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(model.name)),
                        if (model.isLocal) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.offline_bolt,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'LOCAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!model.isLocal && !isOllamaOnline) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_off,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'OFFLINE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!model.isLocal && !isOllamaOnline)
                          Text(
                            'Messages will be queued until server is back',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          )
                        else
                          Text(model.sizeString),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            if (model.capabilities.contains('vision'))
                              _CapabilityBadge(
                                icon: Icons.visibility,
                                label: 'Vision',
                                color: Colors.purple,
                              ),
                            if (model.capabilities.contains('tools'))
                              _CapabilityBadge(
                                icon: Icons.build,
                                label: 'Tools',
                                color: Colors.blue,
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
