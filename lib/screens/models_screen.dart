import 'dart:async';
import 'package:flutter/material.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/on_device_llm_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/services/opencode_llm_service.dart';
import 'package:private_chat_hub/services/opencode_model_visibility_service.dart';

/// Screen for managing model availability and selection across all sources.
class ModelsScreen extends StatefulWidget {
  final OllamaConnectionManager ollamaManager;
  final ConnectionService connectionService;
  final OnDeviceLLMService? onDeviceLLMService;
  final OpenCodeLLMService? openCodeLLMService;
  final OpenCodeModelVisibilityService? openCodeVisibilityService;

  const ModelsScreen({
    super.key,
    required this.ollamaManager,
    required this.connectionService,
    this.onDeviceLLMService,
    this.openCodeLLMService,
    this.openCodeVisibilityService,
  });

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  List<OllamaModelInfo> _models = [];
  List<ModelInfo> _localModels = [];
  List<ModelInfo> _openCodeModels = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedModel;
  Set<String>? _visibleModelIds;
  String _openCodeSearch = '';
  String? _openCodeProviderFilter;
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

    String? remoteError;
    var remoteModels = <OllamaModelInfo>[];
    var localModels = <ModelInfo>[];
    var openCodeModels = <ModelInfo>[];

    final connection = widget.connectionService.getDefaultConnection();
    if (connection != null) {
      try {
        widget.ollamaManager.setConnection(connection);
        remoteModels = await widget.ollamaManager.listModels();
      } catch (e) {
        remoteError = e.toString();
      }
    }

    // Models view is a management surface, so it must show all available
    // models, not only currently-visible ones.
    if (widget.onDeviceLLMService != null) {
      try {
        final downloaded = await widget.onDeviceLLMService!.modelManager
            .getDownloadedModels();
        localModels = downloaded
            .map(
              (model) => model.copyWith(
                id: 'local:${model.id}',
                isLocal: true,
              ),
            )
            .toList();
      } catch (_) {
        localModels = [];
      }
    }

    if (widget.openCodeLLMService != null) {
      try {
        openCodeModels = await widget.openCodeLLMService!
            .getAvailableModelsForSelection(applyProviderFilter: false);
      } catch (_) {
        openCodeModels = [];
      }
    }

    final hasAnyModel = remoteModels.isNotEmpty ||
        localModels.isNotEmpty ||
        openCodeModels.isNotEmpty;
    final selectedStillExists =
        _selectedModel != null &&
        (remoteModels.any((model) => model.name == _selectedModel) ||
            localModels.any((model) => model.id == _selectedModel) ||
            openCodeModels.any((model) => model.id == _selectedModel));

    if ((!selectedStillExists || _selectedModel == null) && hasAnyModel) {
      _selectedModel = remoteModels.isNotEmpty
          ? remoteModels.first.name
          : localModels.isNotEmpty
              ? localModels.first.id
              : openCodeModels.first.id;
      await widget.connectionService.setSelectedModel(_selectedModel!);
    }

    setState(() {
      _models = remoteModels;
      _localModels = localModels;
      _openCodeModels = openCodeModels;
      _visibleModelIds = widget.openCodeVisibilityService?.getVisibleModelIds();
      _error = !hasAnyModel && remoteError != null ? remoteError : null;
      _isLoading = false;
    });
  }

  Set<String> _allModelIds() {
    return {
      ..._models.map((m) => m.name),
      ..._localModels.map((m) => m.id),
      ..._openCodeModels.map((m) => m.id),
    };
  }

  bool _isModelVisibleInApp(String modelId) {
    final visible = _visibleModelIds;
    if (visible == null) return true;
    return visible.contains(modelId);
  }

  String _openCodeProviderForModel(String modelId) {
    final providerModel = modelId.startsWith('opencode:')
        ? modelId.substring('opencode:'.length)
        : modelId;
    final slashIndex = providerModel.indexOf('/');
    if (slashIndex <= 0) return 'unknown';
    return providerModel.substring(0, slashIndex);
  }

  List<String> _availableOpenCodeProviders() {
    final providers = _openCodeModels
        .map((model) => _openCodeProviderForModel(model.id))
        .toSet()
        .toList()
      ..sort();
    return providers;
  }

  List<ModelInfo> _filteredOpenCodeModels() {
    final query = _openCodeSearch.trim().toLowerCase();
    return _openCodeModels.where((model) {
      final provider = _openCodeProviderForModel(model.id);
      if (_openCodeProviderFilter != null && provider != _openCodeProviderFilter) {
        return false;
      }

      if (query.isEmpty) return true;

      final text = '${model.name} ${model.description} ${model.id}'
          .toLowerCase();
      return text.contains(query);
    }).toList();
  }

  Future<void> _setModelVisibility(String modelId, bool visible) async {
    final service = widget.openCodeVisibilityService;
    if (service == null) return;

    if (!visible && modelId == _selectedModel) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot hide the active model. Select another first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final allIds = _allModelIds();
    final nextVisible = (_visibleModelIds ?? allIds).toSet();

    if (visible) {
      nextVisible.add(modelId);
    } else {
      nextVisible.remove(modelId);
    }

    await service.setVisibleModelIds(nextVisible);
    if (!mounted) return;
    setState(() => _visibleModelIds = nextVisible);
  }

  Future<void> _deleteModel(OllamaModelInfo model) async {
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
        await widget.ollamaManager.deleteModel(model.name);
        await _loadModels();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${model.name} deleted')));
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

  Future<void> _selectModel(OllamaModelInfo model) async {
    await _setActiveModel(model.name, model.name);
  }

  Future<void> _selectLocalModel(ModelInfo model) async {
    await _setActiveModel(model.id, model.name);
  }

  Future<void> _selectOpenCodeModel(ModelInfo model) async {
    await _setActiveModel(model.id, model.name);
  }

  Future<void> _setActiveModel(String modelId, String displayName) async {
    await widget.connectionService.setSelectedModel(modelId);
    if (!mounted) return;

    setState(() => _selectedModel = modelId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$displayName selected as active model')),
    );
  }

  void _showPullModelDialog() {
    showDialog(
      context: context,
      builder: (context) => _PullModelDialog(onPull: _pullModel),
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
      await widget.ollamaManager.pullModel(
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

      // Download complete
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

  void _showModelDetails(OllamaModelInfo model) async {
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
          ollamaManager: widget.ollamaManager,
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
        heroTag: 'models_fab',
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

    if (_models.isEmpty && _localModels.isEmpty && _openCodeModels.isEmpty) {
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
                'No models installed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull a model to get started chatting with AI',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (_localModels.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'On-Device Models',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._localModels.map((model) {
                    final isSelected = model.id == _selectedModel;
                    final isVisible = _isModelVisibleInApp(model.id);
                    return _LocalModelCard(
                      model: model,
                      isSelected: isSelected,
                      isVisibleInApp: isVisible,
                      onSelect: () => _selectLocalModel(model),
                      onToggleVisibility: (value) =>
                          _setModelVisibility(model.id, value),
                    );
                  }),
                ],
                if (_models.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Ollama Models',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._models.map((model) {
                    final isSelected = model.name == _selectedModel;
                    final isVisible = _isModelVisibleInApp(model.name);
                    return _ModelCard(
                      model: model,
                      isSelected: isSelected,
                      isVisibleInApp: isVisible,
                      onTap: () => _showModelDetails(model),
                      onSelect: () => _selectModel(model),
                      onDelete: () => _deleteModel(model),
                      onToggleVisibility: (value) =>
                          _setModelVisibility(model.name, value),
                    );
                  }),
                ],
                if (_openCodeModels.isNotEmpty) ...[
                  Builder(builder: (context) {
                    final providers = _availableOpenCodeProviders();
                    final filtered = _filteredOpenCodeModels();
                    final visibleCount = _openCodeModels
                        .where((model) => _isModelVisibleInApp(model.id))
                        .length;

                    if (_openCodeProviderFilter != null &&
                        !providers.contains(_openCodeProviderFilter)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _openCodeProviderFilter = null);
                        }
                      });
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Icon(Icons.hub, size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'OpenCode Models',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$visibleCount/${_openCodeModels.length} enabled',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'Filter OpenCode models',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                  onChanged: (value) => setState(
                                    () => _openCodeSearch = value,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<String?>(
                                value: _openCodeProviderFilter,
                                hint: const Text('Provider'),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('All providers'),
                                  ),
                                  ...providers.map(
                                    (provider) => DropdownMenuItem<String?>(
                                      value: provider,
                                      child: Text(provider),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(
                                    () => _openCodeProviderFilter = value,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                  ...filtered.map((model) {
                    final isSelected = model.id == _selectedModel;
                    final isVisible = _isModelVisibleInApp(model.id);
                    return _OpenCodeModelCard(
                      model: model,
                      isSelected: isSelected,
                      isVisibleInApp: isVisible,
                      onSelect: () => _selectOpenCodeModel(model),
                      onToggleVisibility: (value) =>
                          _setModelVisibility(model.id, value),
                    );
                  }),
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              'No OpenCode models match this filter.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    );
                  }),
                ],
              ],
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

class _LocalModelCard extends StatelessWidget {
  final ModelInfo model;
  final bool isSelected;
  final bool isVisibleInApp;
  final VoidCallback onSelect;
  final ValueChanged<bool> onToggleVisibility;

  const _LocalModelCard({
    required this.model,
    required this.isSelected,
    required this.isVisibleInApp,
    required this.onSelect,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.phone_android,
            color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(model.name)),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ],
        ),
        subtitle: Text(
          isVisibleInApp ? model.sizeString : '${model.sizeString} • Hidden',
        ),
        trailing: Switch.adaptive(
          value: isVisibleInApp,
          onChanged: onToggleVisibility,
        ),
        onTap: onSelect,
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final OllamaModelInfo model;
  final bool isSelected;
  final bool isVisibleInApp;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleVisibility;

  const _ModelCard({
    required this.model,
    required this.isSelected,
    required this.isVisibleInApp,
    required this.onTap,
    required this.onSelect,
    required this.onDelete,
    required this.onToggleVisibility,
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
                        if (!isVisibleInApp)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Hidden',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch.adaptive(
                    value: isVisibleInApp,
                    onChanged: onToggleVisibility,
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

class _ModelDetailsSheet extends StatefulWidget {
  final OllamaModelInfo model;
  final OllamaConnectionManager ollamaManager;
  final ScrollController scrollController;

  const _ModelDetailsSheet({
    required this.model,
    required this.ollamaManager,
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
      final details = await widget.ollamaManager.showModel(widget.model.name);
      setState(() {
        _details = details.details ?? {};
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
                      widget.model.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.model.sizeFormatted,
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_details != null) ...[
            // Capabilities badges
            _DetailSection(
              title: 'Capabilities',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.model.capabilities?.supportsVision == true)
                      _CapabilityChip(
                        icon: Icons.visibility,
                        label: 'Vision',
                        color: Colors.purple,
                      ),
                    if (widget.model.capabilities?.supportsTools == true)
                      _CapabilityChip(
                        icon: Icons.build,
                        label: 'Tools',
                        color: Colors.blue,
                      ),
                    _CapabilityChip(
                      icon: Icons.storage,
                      label:
                          '${((widget.model.capabilities?.contextLength ?? 4096) / 1024).toStringAsFixed(0)}K context',
                      color: Colors.orange,
                    ),
                  ],
                ),
                if (widget.model.capabilities?.description?.isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.model.capabilities!.description!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
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
                      color: Theme.of(context).colorScheme.surfaceContainer,
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

/// Card widget for OpenCode models in the models list.
class _OpenCodeModelCard extends StatelessWidget {
  final ModelInfo model;
  final bool isSelected;
  final bool isVisibleInApp;
  final VoidCallback onSelect;
  final ValueChanged<bool> onToggleVisibility;

  const _OpenCodeModelCard({
    required this.model,
    required this.isSelected,
    required this.isVisibleInApp,
    required this.onSelect,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Extract provider from model ID: opencode:provider/model
    final parts = model.id.split(':');
    final providerModel = parts.length > 1 ? parts[1] : model.id;
    final providerParts = providerModel.split('/');
    final providerName =
        providerParts.isNotEmpty ? providerParts[0] : 'unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Provider badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getProviderColor(providerName).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getProviderAbbrev(providerName),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getProviderColor(providerName),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isVisibleInApp)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Hidden in app selectors',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (model.capabilities.length > 1) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: model.capabilities
                            .where((c) => c != 'text')
                            .map((cap) {
                          final capInfo = _capabilityInfo(cap);
                          return _SmallCapabilityChip(
                            icon: capInfo.$1,
                            label: cap,
                            color: capInfo.$2,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  Switch.adaptive(
                    value: isVisibleInApp,
                    onChanged: onToggleVisibility,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'anthropic':
        return const Color(0xFFD97706);
      case 'openai':
        return const Color(0xFF10A37F);
      case 'google':
        return const Color(0xFF4285F4);
      case 'mistral':
        return const Color(0xFFFF7000);
      case 'xai':
        return const Color(0xFF1DA1F2);
      case 'deepseek':
        return const Color(0xFF6366F1);
      case 'groq':
        return const Color(0xFFE53E3E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getProviderAbbrev(String provider) {
    switch (provider.toLowerCase()) {
      case 'anthropic':
        return 'A';
      case 'openai':
        return 'AI';
      case 'google':
        return 'G';
      case 'mistral':
        return 'M';
      case 'xai':
        return 'X';
      case 'deepseek':
        return 'DS';
      case 'groq':
        return 'GQ';
      default:
        return provider.substring(0, 1).toUpperCase();
    }
  }
}

(IconData, Color) _capabilityInfo(String capability) {
  switch (capability) {
    case 'vision':
      return (Icons.image, const Color(0xFF4285F4));
    case 'tools':
      return (Icons.build, const Color(0xFF10A37F));
    case 'reasoning':
      return (Icons.psychology, const Color(0xFFD97706));
    case 'attachment':
      return (Icons.attach_file, const Color(0xFF6366F1));
    default:
      return (Icons.star, const Color(0xFF6B7280));
  }
}
