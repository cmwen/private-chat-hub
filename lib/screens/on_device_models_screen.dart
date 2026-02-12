import 'dart:async';
import 'package:flutter/material.dart';
import 'package:private_chat_hub/services/inference_config_service.dart';
import 'package:private_chat_hub/services/litert_platform_channel.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/model_download_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:private_chat_hub/widgets/inference_settings_widget.dart';

/// Screen for managing on-device LiteRT-LM models
///
/// Features:
/// - View available models with download status
/// - Download/delete models
/// - Select active model for inference
/// - View device resources (memory, storage)
/// - Configure backend (CPU/GPU/NPU)
class OnDeviceModelsScreen extends StatefulWidget {
  final StorageService storageService;
  final InferenceConfigService inferenceConfigService;

  const OnDeviceModelsScreen({
    super.key,
    required this.storageService,
    required this.inferenceConfigService,
  });

  @override
  State<OnDeviceModelsScreen> createState() => _OnDeviceModelsScreenState();
}

class _OnDeviceModelsScreenState extends State<OnDeviceModelsScreen> {
  late ModelDownloadService _downloadService;
  late LiteRTPlatformChannel _platformChannel;

  List<ModelInfo> _models = [];
  final Map<String, ModelDownloadProgress> _downloadProgress = {};
  final Map<String, StreamSubscription> _downloadSubscriptions = {};
  Map<String, bool> _deviceCapabilities = {
    'cpu': true,
    'gpu': false,
    'npu': false,
  };
  Map<String, int> _memoryInfo = {};
  int _storageUsed = 0;
  String? _selectedModelId;
  bool _isLoading = true;
  String _currentBackend = 'gpu';

  @override
  void initState() {
    super.initState();
    _downloadService = ModelDownloadService(
      widget.storageService,
      huggingFaceToken: widget.inferenceConfigService.huggingFaceToken,
    );
    _platformChannel = LiteRTPlatformChannel();
    _selectedModelId = widget.inferenceConfigService.lastOnDeviceModel;
    _currentBackend = widget.inferenceConfigService.preferredBackend;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load models
      final models = await _downloadService.getAvailableModels();

      // Load device capabilities
      final capabilities = await _platformChannel.getDeviceCapabilities();

      // Load memory info
      final memoryInfo = await _platformChannel.getMemoryInfo();

      // Load storage usage
      final storageUsed = await _downloadService.getStorageUsed();

      setState(() {
        _models = models;
        _deviceCapabilities = {
          'cpu': capabilities['cpu'] ?? true,
          'gpu': capabilities['gpu'] ?? false,
          'npu': capabilities['npu'] ?? false,
        };
        _memoryInfo = {
          'totalMemory': memoryInfo['totalMemory'] ?? 0,
          'availableMemory': memoryInfo['availableMemory'] ?? 0,
        };
        _storageUsed = storageUsed;
        _isLoading = false;
      });
    } catch (e) {
      _log('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startDownload(String modelId) {
    // Cancel any existing subscription for this model
    _downloadSubscriptions[modelId]?.cancel();

    final stream = _downloadService.downloadModel(modelId);
    final subscription = stream.listen(
      (progress) {
        setState(() {
          _downloadProgress[modelId] = progress;

          // Update models list when download completes
          if (progress.status == DownloadStatus.completed) {
            _loadData();
          }
        });
      },
      onError: (e) {
        _log('Download error: $e');
        
        // Show user-friendly error message
        String errorMessage = 'Download failed';
        if (e is HuggingFaceAuthException) {
          errorMessage = e.message;
        } else {
          errorMessage = 'Download failed: $e';
        }
        
        _showErrorDialog('Download Error', errorMessage);
        
        // Remove progress on error
        setState(() {
          _downloadProgress.remove(modelId);
        });
      },
      onDone: () {
        setState(() {
          _downloadProgress.remove(modelId);
        });
        _downloadSubscriptions.remove(modelId);
      },
    );

    _downloadSubscriptions[modelId] = subscription;
  }

  void _cancelDownload(String modelId) {
    _downloadService.cancelDownload(modelId);
    _downloadSubscriptions[modelId]?.cancel();
    _downloadSubscriptions.remove(modelId);
    setState(() {
      _downloadProgress.remove(modelId);
    });
  }

  Future<void> _deleteModel(String modelId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: const Text(
          'Are you sure you want to delete this model? '
          'You will need to download it again to use it.',
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
      final success = await _downloadService.deleteModel(modelId);
      if (success) {
        // Clear selection if this was the selected model
        if (_selectedModelId == modelId) {
          setState(() => _selectedModelId = null);
          await widget.inferenceConfigService.setLastOnDeviceModel('');
        }
        _showSnackBar('Model deleted');
        await _loadData();
      } else {
        _showSnackBar('Failed to delete model');
      }
    }
  }

  Future<void> _selectModel(String modelId) async {
    setState(() => _selectedModelId = modelId);
    await widget.inferenceConfigService.setLastOnDeviceModel(modelId);
    _showSnackBar('Selected ${_getModelName(modelId)} for on-device inference');
  }

  String _getModelName(String modelId) {
    final model = _models.firstWhere(
      (m) => m.id == modelId,
      orElse: () => ModelInfo(
        id: modelId,
        name: modelId,
        description: '',
        sizeBytes: 0,
        isDownloaded: false,
        capabilities: [],
      ),
    );
    return model.name;
  }

  Future<void> _changeBackend(String backend) async {
    setState(() => _currentBackend = backend);
    await widget.inferenceConfigService.setPreferredBackend(backend);
    _showSnackBar('Backend changed to ${backend.toUpperCase()}');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            message,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          if (message.contains('Hugging Face token'))
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to settings
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[OnDeviceModelsScreen] $message');
  }

  @override
  void dispose() {
    for (final subscription in _downloadSubscriptions.values) {
      subscription.cancel();
    }
    _downloadService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('On-Device Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                children: [
                  // Device resources card
                  DeviceResourceInfo(
                    memoryInfo: _memoryInfo,
                    storageUsed: _storageUsed,
                  ),

                  // Backend selector
                  BackendSelector(
                    currentBackend: _currentBackend,
                    onBackendChanged: _changeBackend,
                    capabilities: _deviceCapabilities,
                  ),

                  const Divider(),

                  // Models section header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Available Models',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '${_models.where((m) => m.isDownloaded).length} downloaded',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Models list
                  ..._models.map(
                    (model) => ModelDownloadTile(
                      model: model,
                      downloadProgress: _downloadProgress[model.id],
                      onDownload: () => _startDownload(model.id),
                      onCancel: () => _cancelDownload(model.id),
                      onDelete: model.isDownloaded
                          ? () => _deleteModel(model.id)
                          : null,
                      onSelect: model.isDownloaded
                          ? () => _selectModel(model.id)
                          : null,
                      isSelected: _selectedModelId == model.id,
                    ),
                  ),

                  // Info card about LiteRT-LM
                  _buildInfoCard(context),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'About On-Device Models',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'On-device models run entirely on your phone using Google\'s LiteRT-LM framework. '
              'This means:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              context,
              Icons.lock,
              'Complete privacy - no data leaves your device',
            ),
            _buildInfoItem(
              context,
              Icons.wifi_off,
              'Works offline without internet',
            ),
            _buildInfoItem(
              context,
              Icons.speed,
              'Fast responses with hardware acceleration',
            ),
            _buildInfoItem(
              context,
              Icons.storage,
              'Models stored locally (requires storage space)',
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: Start with Gemma 3 1B for basic conversations, or Gemma 3n E2B for vision capabilities.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
