import 'dart:async';
import 'package:flutter/material.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/ollama_service.dart';

/// Screen for managing Ollama models.
class ModelsScreen extends StatefulWidget {
  final OllamaService ollamaService;
  final ConnectionService connectionService;

  const ModelsScreen({
    super.key,
    required this.ollamaService,
    required this.connectionService,
  });

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  List<OllamaModel> _models = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedModel;
  final Map<String, _DownloadProgress> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _loadModels();
    _selectedModel = widget.connectionService.getSelectedModel();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final connection = widget.connectionService.getDefaultConnection();
      if (connection == null) {
        setState(() {
          _error = 'No Ollama connection configured. Go to Settings to add one.';
          _isLoading = false;
        });
        return;
      }

      widget.ollamaService.setConnection(OllamaConnection(
        host: connection.host,
        port: connection.port,
        useHttps: connection.useHttps,
      ));

      final models = await widget.ollamaService.listModels();
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

  Future<void> _deleteModel(OllamaModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text(
          'Are you sure you want to delete "${model.name}"?\n\n'
          'This will free up ${model.sizeFormatted} of space.',
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
      try {
        await widget.ollamaService.deleteModel(model.name);
        await _loadModels();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${model.name} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _selectModel(OllamaModel model) async {
    await widget.connectionService.setSelectedModel(model.name);
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
      builder: (context) => _PullModelDialog(
        onPull: _pullModel,
      ),
    );
  }

  Future<void> _pullModel(String modelName) async {
    Navigator.pop(context);

    setState(() {
      _downloadProgress[modelName] = _DownloadProgress(
        status: 'Starting download...',
        progress: 0,
      );
    });

    try {
      await for (final progress in widget.ollamaService.pullModel(modelName)) {
        final status = progress['status'] as String? ?? '';
        final total = progress['total'] as int?;
        final completed = progress['completed'] as int?;

        double? progressPercent;
        if (total != null && completed != null && total > 0) {
          progressPercent = completed / total;
        }

        setState(() {
          _downloadProgress[modelName] = _DownloadProgress(
            status: status,
            progress: progressPercent,
          );
        });

        if (status == 'success') {
          setState(() {
            _downloadProgress.remove(modelName);
          });
          await _loadModels();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$modelName downloaded successfully')),
            );
          }
          return;
        }
      }

      // Download complete
      setState(() {
        _downloadProgress.remove(modelName);
      });
      await _loadModels();
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

  void _showModelDetails(OllamaModel model) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _ModelDetailsSheet(
          model: model,
          ollamaService: widget.ollamaService,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPullModelDialog,
        icon: const Icon(Icons.download),
        label: const Text('Pull Model'),
      ),
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
                color: Colors.red[300],
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
                style: TextStyle(color: Colors.grey[600]),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'No models installed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull a model to get started chatting with AI',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
        ..._downloadProgress.entries.map((entry) => Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
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
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
            )),
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

                return _ModelCard(
                  model: model,
                  isSelected: isSelected,
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
  final OllamaModel model;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _ModelCard({
    required this.model,
    required this.isSelected,
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
                    : Colors.grey[200],
                child: Icon(
                  Icons.psychology,
                  color: isSelected ? Colors.white : Colors.grey[600],
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
                        _InfoChip(
                          icon: Icons.storage,
                          label: model.sizeFormatted,
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
                      onDelete();
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
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
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
                  subtitle: Text(model.$2, style: const TextStyle(fontSize: 12)),
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
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

class _ModelDetailsSheet extends StatefulWidget {
  final OllamaModel model;
  final OllamaService ollamaService;
  final ScrollController scrollController;

  const _ModelDetailsSheet({
    required this.model,
    required this.ollamaService,
    required this.scrollController,
  });

  @override
  State<_ModelDetailsSheet> createState() => _ModelDetailsSheetState();
}

class _ModelDetailsSheetState extends State<_ModelDetailsSheet> {
  Map<String, dynamic>? _details;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final details = await widget.ollamaService.showModel(widget.model.name);
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.psychology, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.model.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.model.sizeFormatted,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_details != null) ...[
            _DetailSection(
              title: 'Model Information',
              children: [
                if (_details!['modelfile'] != null)
                  _DetailRow('Family', widget.model.family),
                if (widget.model.parameterCount != null)
                  _DetailRow('Parameters', widget.model.parameterCount!),
                if (_details!['details']?['quantization_level'] != null)
                  _DetailRow(
                    'Quantization',
                    _details!['details']['quantization_level'] as String,
                  ),
                if (_details!['details']?['format'] != null)
                  _DetailRow(
                    'Format',
                    _details!['details']['format'] as String,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_details!['template'] != null)
              _DetailSection(
                title: 'Prompt Template',
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _details!['template'] as String,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
          ] else
            const Text('Failed to load model details'),
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
