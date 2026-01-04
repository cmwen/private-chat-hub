import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/project.dart';
import 'package:private_chat_hub/screens/project_detail_screen.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/services/project_service.dart';
import 'package:private_chat_hub/models/conversation.dart';

/// Screen for managing projects.
class ProjectsScreen extends StatefulWidget {
  final ProjectService projectService;
  final ChatService chatService;
  final ConnectionService connectionService;
  final OllamaConnectionManager ollamaManager;
  final Function(Conversation) onConversationSelected;

  const ProjectsScreen({
    super.key,
    required this.projectService,
    required this.chatService,
    required this.connectionService,
    required this.ollamaManager,
    required this.onConversationSelected,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    setState(() {
      _projects = widget.projectService.getProjects();
      _isLoading = false;
    });
  }

  Future<void> _createProject() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateProjectDialog(),
    );

    if (result != null) {
      await widget.projectService.createProject(
        name: result['name'] as String,
        description: result['description'] as String?,
        systemPrompt: result['systemPrompt'] as String?,
        instructions: result['instructions'] as String?,
        colorValue: result['colorValue'] as int?,
        iconName: result['iconName'] as String?,
      );
      _loadProjects();
    }
  }

  Future<void> _deleteProject(Project project) async {
    final conversationCount = widget.chatService.getProjectConversationCount(
      project.id,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.name}"?\n\n'
          '${conversationCount > 0 ? 'This will also delete $conversationCount conversation${conversationCount > 1 ? 's' : ''}.' : 'This project has no conversations.'}',
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
      await widget.chatService.deleteProjectConversations(project.id);
      await widget.projectService.deleteProject(project.id);
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${project.name} deleted')));
      }
    }
  }

  void _openProject(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(
          project: project,
          projectService: widget.projectService,
          chatService: widget.chatService,
          connectionService: widget.connectionService,
          ollamaManager: widget.ollamaManager,
          onConversationSelected: widget.onConversationSelected,
          onProjectUpdated: _loadProjects,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
          ? _buildEmptyState()
          : _buildProjectList(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'projects_fab',
        onPressed: _createProject,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
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
            Icon(Icons.folder_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No projects yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a project to organize your conversations\nand share context across chats',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    return RefreshIndicator(
      onRefresh: () async => _loadProjects(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          final conversationCount = widget.chatService
              .getProjectConversationCount(project.id);

          return _ProjectCard(
            project: project,
            conversationCount: conversationCount,
            onTap: () => _openProject(project),
            onPin: () async {
              await widget.projectService.togglePinned(project.id);
              _loadProjects();
            },
            onDelete: () => _deleteProject(project),
          );
        },
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final int conversationCount;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.conversationCount,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: project.color,
                child: Icon(project.icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (project.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        Expanded(
                          child: Text(
                            project.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (project.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        project.description!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$conversationCount conversation${conversationCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (project.systemPrompt != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.psychology,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Context set',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'pin':
                      onPin();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: ListTile(
                      leading: Icon(
                        project.isPinned
                            ? Icons.push_pin_outlined
                            : Icons.push_pin,
                      ),
                      title: Text(project.isPinned ? 'Unpin' : 'Pin'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateProjectDialog extends StatefulWidget {
  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();
  final _instructionsController = TextEditingController();
  int _selectedColor = Project.availableColors[0];
  String _selectedIcon = 'folder';
  bool _showAdvanced = false;

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
      title: const Text('Create Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name *',
                hintText: 'e.g., Work Tasks, Research, Learning',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description of this project',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Icon and color selection
            const Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Selected preview
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(_selectedColor),
                  child: Icon(
                    Project.availableIcons.contains(_selectedIcon)
                        ? _getIconData(_selectedIcon)
                        : Icons.folder,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Color selection
                      Wrap(
                        spacing: 8,
                        children: Project.availableColors.map((color) {
                          final isSelected = color == _selectedColor;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      // Icon selection
                      Wrap(
                        spacing: 8,
                        children: Project.availableIcons.map((iconName) {
                          final isSelected = iconName == _selectedIcon;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedIcon = iconName),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.grey[300]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                _getIconData(iconName),
                                size: 18,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
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
                    'Project Context (Shared with all conversations)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _systemPromptController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'System Prompt',
                  hintText: 'Instructions for AI behavior in this project',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Project Instructions',
                  hintText:
                      'Context and background info (e.g., "This is a Flutter project using BLoC...")',
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
          child: const Text('Create'),
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
