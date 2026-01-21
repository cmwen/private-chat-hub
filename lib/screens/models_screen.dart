import 'dart:async';
import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/models/provider_models.dart';
import 'package:private_chat_hub/services/ai_connection_service.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/services/provider_client_factory.dart';
import 'package:private_chat_hub/services/provider_model_storage.dart';

/// Screen for managing models.
class ModelsScreen extends StatefulWidget {
  final ConnectionService connectionService;
  final AiConnectionService aiConnectionService;
  final ProviderModelStorage providerModelStorage;
  final ProviderClientFactory providerClientFactory;

  const ModelsScreen({
    super.key,
    required this.connectionService,
    required this.aiConnectionService,
    required this.providerModelStorage,
    required this.providerClientFactory,
  });

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  List<ProviderModelInfo> _models = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedModel;
  final Map<String, _DownloadProgress> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _loadModels();
    _selectedModel = widget.providerModelStorage.getSelectedModel(
      widget.aiConnectionService.getSelectedProvider(),
    );
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final providerType = widget.aiConnectionService.getSelectedProvider();
      final connection = widget.aiConnectionService.getConnectionForProvider(
        providerType,
      );
      final client = await widget.providerClientFactory.createClient(
        connection,
      );
      if (client == null) {
        setState(() {
          _error =
              'No ${providerType.label} connection configured. Go to Settings to add one.';
          _isLoading = false;
        });
        return;
      }

      final models = await client.listModels();
      setState(() {
        _models = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteModel(ProviderModelInfo model) async {
    if (widget.aiConnectionService.getSelectedProvider() !=
        AiProviderType.ollama) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Model'),
          content: const Text('Deleting models is only supported for Ollama.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Are you sure you want to delete "${model.name}"?'),
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
      final defaultConnection = widget.connectionService.getDefaultConnection();
      if (defaultConnection == null) return;
      final ollamaManager = OllamaConnectionManager();
      ollamaManager.setConnection(defaultConnection);
      await ollamaManager.deleteModel(model.name);
      await _loadModels();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${model.name} deleted')));
      }
    }
  }

  Future<void> _selectModel(ProviderModelInfo model) async {
    final providerType = widget.aiConnectionService.getSelectedProvider();
    await widget.providerModelStorage.setSelectedModel(
      providerType,
      model.name,
    );
    setState(() => _selectedModel = model.name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${model.name} selected as active model')),
      );
    }
  }

  void _showPullModelDialog() {
    showDialog(
      context: context,
      builder: (context) => _PullModelDialog(onPull: _pullModel),
    );
  }

  Future<void> _pullModel(String modelName) async {
    final providerType = widget.aiConnectionService.getSelectedProvider();
    if (providerType != AiProviderType.ollama) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pulling models is only supported for Ollama.'),
          ),
        );
      }
      return;
    }

    Navigator.pop(context);

    setState(() {
      _downloadProgress[modelName] = _DownloadProgress(
        status: 'Starting download...',
        progress: 0,
      );
    });

    try {
      final defaultConnection = widget.connectionService.getDefaultConnection();
      if (defaultConnection == null) return;
      final ollamaManager = OllamaConnectionManager();
      ollamaManager.setConnection(defaultConnection);

      await ollamaManager.pullModel(
        modelName,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[modelName] = _DownloadProgress(
              status: 'Downloading...',
              progress: progress,
            );
          });
        },
      );

      setState(() {
        _downloadProgress.remove(modelName);
      });
      await _loadModels();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$modelName downloaded successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _downloadProgress.remove(modelName);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showModelDetails(ProviderModelInfo model) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _ProviderModelDetailsSheet(
          model: model,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModels,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton:
          widget.aiConnectionService.getSelectedProvider() ==
              AiProviderType.ollama
          ? FloatingActionButton.extended(
              heroTag: 'models_fab',
              onPressed: _showPullModelDialog,
              icon: const Icon(Icons.download),
              label: const Text('Pull Model'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load models',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadModels,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_models.isEmpty) {
      final providerType = widget.aiConnectionService.getSelectedProvider();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              const Text(
                'No models available',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                providerType == AiProviderType.ollama
                    ? 'Pull a model to get started chatting with AI'
                    : 'No models returned from ${providerType.label}.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (providerType == AiProviderType.ollama)
                ElevatedButton.icon(
                  onPressed: _showPullModelDialog,
                  icon: const Icon(Icons.download),
                  label: const Text('Pull Model'),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Download progress indicators
        ..._downloadProgress.entries.map(
          (entry) => Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Downloading ${entry.key}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        entry.value.status,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      if (entry.value.progress != null) ...[
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: entry.value.progress),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Models list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadModels,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _models.length,
              itemBuilder: (context, index) {
                final model = _models[index];
                final isSelected = model.name == _selectedModel;
                final canDelete =
                    widget.aiConnectionService.getSelectedProvider() ==
                    AiProviderType.ollama;

                return _ModelCard(
                  model: model,
                  isSelected: isSelected,
                  canDelete: canDelete,
                  onTap: () => _showModelDetails(model),
                  onSelect: () => _selectModel(model),
                  onDelete: () => _deleteModel(model),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DownloadProgress {
  final String status;
  final double? progress;

  _DownloadProgress({required this.status, this.progress});
}

class _ModelCard extends StatelessWidget {
  final ProviderModelInfo model;
  final bool isSelected;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _ModelCard({
    required this.model,
    required this.isSelected,
    required this.canDelete,
    required this.onTap,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                backgroundColor: isSelected
                    ? colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.psychology,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            model.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (model.sizeFormatted != null)
                          _InfoChip(
                            icon: Icons.storage,
                            label: model.sizeFormatted!,
                          ),

                        if (model.parameterCount != null) ...[
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.memory,
                            label: model.parameterCount!,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (model.capabilities?.supportsVision == true)
                          _SmallCapabilityChip(
                            icon: Icons.visibility,
                            label: 'Vision',
                            color: Colors.purple,
                          ),
                        if (model.capabilities?.supportsTools == true)
                          _SmallCapabilityChip(
                            icon: Icons.build,
                            label: 'Tools',
                            color: Colors.blue,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'select':
                      onSelect();
                      break;
                    case 'delete':
                      if (canDelete) {
                        onDelete();
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!isSelected)
                    const PopupMenuItem(
                      value: 'select',
                      child: ListTile(
                        leading: Icon(Icons.check_circle),
                        title: Text('Set as Active'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (canDelete)
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CapabilityChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallCapabilityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SmallCapabilityChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
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

class _PullModelDialog extends StatefulWidget {
  final Function(String) onPull;

  const _PullModelDialog({required this.onPull});

  @override
  State<_PullModelDialog> createState() => _PullModelDialogState();
}

class _PullModelDialogState extends State<_PullModelDialog> {
  final _controller = TextEditingController();
  bool _isCustom = false;

  static const _popularModels = [
    ('llama3.2:latest', 'Llama 3.2 - Meta\'s latest model'),
    ('mistral:latest', 'Mistral 7B - Fast and efficient'),
    ('phi3:latest', 'Phi-3 - Microsoft\'s small model'),
    ('gemma2:2b', 'Gemma 2 2B - Google\'s compact model'),
    ('qwen2.5:0.5b', 'Qwen 2.5 0.5B - Very fast'),
    ('llava:latest', 'LLaVA - Vision model'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pull Model'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isCustom) ...[
              const Text(
                'Popular Models',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._popularModels.map(
                (model) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.psychology),
                  title: Text(model.$1),
                  subtitle: Text(
                    model.$2,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => widget.onPull(model.$1),
                ),
              ),
              const Divider(),
              TextButton.icon(
                onPressed: () => setState(() => _isCustom = true),
                icon: const Icon(Icons.edit),
                label: const Text('Enter custom model name'),
              ),
            ] else ...[
              TextButton.icon(
                onPressed: () => setState(() => _isCustom = false),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to popular models'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Model name',
                  hintText: 'e.g., llama3.2:latest',
                  prefixIcon: Icon(Icons.psychology),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the model name from ollama.com/library',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
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
        if (_isCustom)
          ElevatedButton(
            onPressed: () {
              final name = _controller.text.trim();
              if (name.isNotEmpty) {
                widget.onPull(name);
              }
            },
            child: const Text('Pull'),
          ),
      ],
    );
  }
}

class _ProviderModelDetailsSheet extends StatelessWidget {
  final ProviderModelInfo model;
  final ScrollController scrollController;

  const _ProviderModelDetailsSheet({
    required this.model,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (model.sizeFormatted != null)
                      Text(
                        model.sizeFormatted!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'Capabilities',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (model.capabilities?.supportsVision == true)
                    _CapabilityChip(
                      icon: Icons.visibility,
                      label: 'Vision',
                      color: Colors.purple,
                    ),
                  if (model.capabilities?.supportsTools == true)
                    _CapabilityChip(
                      icon: Icons.build,
                      label: 'Tools',
                      color: Colors.blue,
                    ),
                  if (model.capabilities?.contextLength != null)
                    _CapabilityChip(
                      icon: Icons.storage,
                      label:
                          '${((model.capabilities?.contextLength ?? 4096) / 1024).toStringAsFixed(0)}K context',
                      color: Colors.orange,
                    ),
                ],
              ),
              if (model.capabilities?.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  model.capabilities!.description!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          if (model.parameterCount != null) ...[
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Model Information',
              children: [_DetailRow('Parameters', model.parameterCount!)],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
