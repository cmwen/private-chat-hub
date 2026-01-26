import 'package:flutter/material.dart';
import '../../data/datasources/remote/ollama_api_client.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/ollama_model.dart';
import '../../core/utils/logger.dart';

class ModelsScreen extends StatefulWidget {
  final SettingsRepository settingsRepo;

  const ModelsScreen({super.key, required this.settingsRepo});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  List<OllamaModel> _models = [];
  bool _loading = true;
  OllamaApiClient? _client;
  Map<String, double?> _pullProgress = {};

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }

  @override
  void dispose() {
    _client?.dispose();
    super.dispose();
  }

  Future<void> _initializeClient() async {
    try {
      final host = await widget.settingsRepo.getLastConnectionHost();
      final port = await widget.settingsRepo.getLastConnectionPort();

      final baseUrl = host != null
          ? 'http://$host:${port ?? 11434}'
          : 'http://localhost:11434';

      setState(() {
        _client = OllamaApiClient(baseUrl: baseUrl);
      });

      _loadModels();
    } catch (e) {
      AppLogger.error('Failed to initialize Ollama client', e);
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _loadModels() async {
    if (_client == null) return;

    setState(() => _loading = true);
    try {
      final models = await _client!.getTags();
      setState(() {
        _models = models;
        _loading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load models', e);
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading models: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showPullDialog() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pull Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Model Name',
                hintText: 'llama3.2 or gemma2:2b',
                border: OutlineInputBorder(),
                helperText: 'Specify model name and optional tag',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pull'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final modelName = controller.text.trim();
      if (modelName.isEmpty) return;

      _pullModel(modelName);
    }
  }

  Future<void> _pullModel(String modelName) async {
    if (_client == null) return;

    setState(() => _pullProgress[modelName] = 0.0);

    try {
      await for (final progress in _client!.pullModel(modelName)) {
        setState(() {
          if (progress.progress != null) {
            _pullProgress[modelName] = progress.progress;
          }
        });

        if (progress.isDone) {
          setState(() => _pullProgress.remove(modelName));
          _loadModels();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Model "$modelName" pulled successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
        }
      }
    } catch (e) {
      AppLogger.error('Failed to pull model', e);
      setState(() => _pullProgress.remove(modelName));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Failed to pull model: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteModel(OllamaModel model) async {
    if (_client == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text(
          'Delete "${model.name}"?\n\nSize: ${_formatSize(model.size)}',
        ),
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

    if (confirmed == true && mounted) {
      try {
        await _client!.deleteModel(model.name);
        _loadModels();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Model deleted')));
        }
      } catch (e) {
        AppLogger.error('Failed to delete model', e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ollama Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadModels,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _models.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No models installed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to pull your first model',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _models.length,
              itemBuilder: (context, index) {
                final model = _models[index];
                final isPulling = _pullProgress.containsKey(model.name);
                final progress = _pullProgress[model.name];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            isPulling ? Icons.downloading : Icons.layers,
                          ),
                        ),
                        title: Text(model.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatSize(model.size)),
                            Text(
                              'Modified ${_formatDate(model.modifiedAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: isPulling
                              ? null
                              : () => _deleteModel(model),
                        ),
                      ),
                      if (isPulling && progress != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: LinearProgressIndicator(value: progress),
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPullDialog,
        child: const Icon(Icons.download),
      ),
    );
  }
}
