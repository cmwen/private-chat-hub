import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/project.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/services/project_service.dart';

/// Screen showing project details and its conversations.
class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final ProjectService projectService;
  final ChatService chatService;
  final ConnectionService connectionService;
  final OllamaConnectionManager ollamaManager;
  final Function(Conversation) onConversationSelected;
  final VoidCallback onProjectUpdated;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.projectService,
    required this.chatService,
    required this.connectionService,
    required this.ollamaManager,
    required this.onConversationSelected,
    required this.onProjectUpdated,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;
  List<Conversation> _conversations = [];
  List<OllamaModelInfo> _models = [];
  String? _selectedModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _conversations = widget.chatService.getProjectConversations(_project.id);
    _selectedModel = widget.connectionService.getSelectedModel();

    // Load models
    final connection = widget.connectionService.getDefaultConnection();
    if (connection != null) {
      try {
        widget.ollamaManager.setConnection(connection);
        _models = await widget.ollamaManager.listModels();
      } catch (_) {
        _models = [];
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _createConversation() async {
    if (_selectedModel == null && _models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a model first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If no model selected but models are available, use the first one
    final modelToUse = _selectedModel ?? _models.first.name;

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => _NewProjectConversationDialog(
        projectName: _project.name,
        modelName: modelToUse,
        hasProjectContext: _project.fullContext != null,
      ),
    );

    if (result == null) return;

    // Combine project context with conversation-specific prompt
    String? combinedPrompt;
    if (_project.fullContext != null || result['systemPrompt'] != null) {
      final parts = <String>[];
      if (_project.fullContext != null) {
        parts.add(_project.fullContext!);
      }
      if (result['systemPrompt'] != null &&
          result['systemPrompt']!.isNotEmpty) {
        parts.add('\n\nAdditional Instructions:\n${result['systemPrompt']}');
      }
      combinedPrompt = parts.join('\n');
    }

    final conversation = await widget.chatService.createConversation(
      modelName: modelToUse,
      title: result['title'],
      systemPrompt: combinedPrompt,
      projectId: _project.id,
    );

    if (!mounted) return;
    Navigator.pop(context); // Go back to main screen
    widget.onConversationSelected(conversation);
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete "${conversation.title}"?',
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

  void _showEditProjectDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditProjectDialog(project: _project),
    );

    if (result != null) {
      final updatedProject = _project.copyWith(
        name: result['name'] as String,
        description: result['description'] as String?,
        systemPrompt: result['systemPrompt'] as String?,
        instructions: result['instructions'] as String?,
        colorValue: result['colorValue'] as int,
        iconName: result['iconName'] as String,
      );

      await widget.projectService.updateProject(updatedProject);
      setState(() {
        _project = updatedProject;
      });
      widget.onProjectUpdated();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Project updated')));
      }
    }
  }

  void _showProjectInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _project.color,
                    child: Icon(_project.icon, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _project.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_project.description != null)
                          Text(
                            _project.description!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditProjectDialog();
                    },
                  ),
                ],
              ),
              const Divider(height: 32),
              _InfoRow('Conversations', '${_conversations.length}'),
              _InfoRow(
                'Created',
                DateFormat('MMM d, y').format(_project.createdAt),
              ),
              _InfoRow(
                'Last Updated',
                DateFormat('MMM d, y').format(_project.updatedAt),
              ),
              const SizedBox(height: 16),
              if (_project.systemPrompt != null ||
                  _project.instructions != null) ...[
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Project Context',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This context is automatically applied to all conversations in this project:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (_project.systemPrompt != null) ...[
                  const Text(
                    'System Prompt:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _project.systemPrompt!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_project.instructions != null) ...[
                  const Text(
                    'Instructions:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _project.instructions!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ] else ...[
                const Divider(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No context set',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add a system prompt or instructions to share context across all conversations in this project.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditProjectDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Context'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _project.color.withAlpha(60),
        title: Row(
          children: [
            Icon(_project.icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_project.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showProjectInfo,
            tooltip: 'Project Info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Context indicator
                if (_project.fullContext != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: _project.color.withAlpha(30),
                    child: Row(
                      children: [
                        Icon(Icons.psychology, size: 16, color: _project.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shared context active',
                            style: TextStyle(
                              fontSize: 12,
                              color: _project.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _showProjectInfo,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View',
                            style: TextStyle(
                              fontSize: 12,
                              color: _project.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Conversations list
                Expanded(
                  child: _conversations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            return _ConversationTile(
                              conversation: conversation,
                              projectColor: _project.color,
                              onTap: () {
                                Navigator.pop(context);
                                widget.onConversationSelected(conversation);
                              },
                              onDelete: () => _deleteConversation(conversation),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'project_detail_fab',
        onPressed: _createConversation,
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
        backgroundColor: _project.color,
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
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new chat in this project\nto use the shared context',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final Color projectColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.projectColor,
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
          backgroundColor: projectColor.withAlpha(60),
          child: Text(
            conversation.title.isNotEmpty
                ? conversation.title[0].toUpperCase()
                : 'C',
            style: TextStyle(color: projectColor),
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
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
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

class _NewProjectConversationDialog extends StatefulWidget {
  final String projectName;
  final String modelName;
  final bool hasProjectContext;

  const _NewProjectConversationDialog({
    required this.projectName,
    required this.modelName,
    required this.hasProjectContext,
  });

  @override
  State<_NewProjectConversationDialog> createState() =>
      _NewProjectConversationDialogState();
}

class _NewProjectConversationDialogState
    extends State<_NewProjectConversationDialog> {
  final _titleController = TextEditingController();
  final _systemPromptController = TextEditingController();
  bool _showAdvanced = false;

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
              'Project: ${widget.projectName}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Model: ${widget.modelName}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (widget.hasProjectContext)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Project context will be applied',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                    'Additional Instructions',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_showAdvanced) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _systemPromptController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add conversation-specific instructions...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'These will be added to the project context',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                  : _titleController.text.trim(),
              'systemPrompt': _systemPromptController.text.isEmpty
                  ? null
                  : _systemPromptController.text.trim(),
            });
          },
          child: const Text('Start Chat'),
        ),
      ],
    );
  }
}

class _EditProjectDialog extends StatefulWidget {
  final Project project;

  const _EditProjectDialog({required this.project});

  @override
  State<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<_EditProjectDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _systemPromptController;
  late final TextEditingController _instructionsController;
  late int _selectedColor;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(
      text: widget.project.description ?? '',
    );
    _systemPromptController = TextEditingController(
      text: widget.project.systemPrompt ?? '',
    );
    _instructionsController = TextEditingController(
      text: widget.project.instructions ?? '',
    );
    _selectedColor = widget.project.colorValue;
    _selectedIcon = widget.project.iconName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(_selectedColor),
                  child: Icon(
                    _getIconData(_selectedIcon),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 6,
                        children: Project.availableColors.map((color) {
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: color == _selectedColor
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: Project.availableIcons.map((iconName) {
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedIcon = iconName),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: iconName == _selectedIcon
                                    ? Colors.grey[300]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(_getIconData(iconName), size: 16),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Project Context',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Shared with all conversations in this project',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _systemPromptController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'System Prompt',
                hintText: 'Instructions for AI behavior',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Project Instructions',
                hintText: 'Context and background info',
                border: OutlineInputBorder(),
              ),
            ),
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
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a project name')),
              );
              return;
            }
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              'systemPrompt': _systemPromptController.text.trim().isEmpty
                  ? null
                  : _systemPromptController.text.trim(),
              'instructions': _instructionsController.text.trim().isEmpty
                  ? null
                  : _instructionsController.text.trim(),
              'colorValue': _selectedColor,
              'iconName': _selectedIcon,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'folder':
        return Icons.folder;
      case 'code':
        return Icons.code;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'science':
        return Icons.science;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'chat':
        return Icons.chat;
      case 'article':
        return Icons.article;
      case 'build':
        return Icons.build;
      case 'explore':
        return Icons.explore;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      default:
        return Icons.folder;
    }
  }
}
