import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';

/// Service for downloading LiteRT-LM model files
///
/// Handles downloading models from Hugging Face with progress tracking,
/// resume support, and caching.
class ModelDownloadService {
  final StorageService _storage;
  final http.Client _client;

  // Download progress streams
  final Map<String, StreamController<ModelDownloadProgress>>
  _progressControllers = {};

  // Active downloads
  final Map<String, CancelableDownload> _activeDownloads = {};

  /// Available LiteRT-LM models with their download URLs
  static const Map<String, LiteRTModel> availableModels = {
    'gemma3-1b': LiteRTModel(
      id: 'gemma3-1b',
      name: 'Gemma 3 1B',
      description: 'Google Gemma 3 1B parameter model. Great for general chat.',
      sizeBytes: 584056320, // ~557 MB
      downloadUrl:
          'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm',
      capabilities: ['text', 'tools'],
      contextSize: 4096,
      quantization: '4-bit',
    ),
    'gemma-3n-e2b': LiteRTModel(
      id: 'gemma-3n-e2b',
      name: 'Gemma 3n E2B',
      description: 'Google Gemma 3n E2B with vision support.',
      sizeBytes: 3109634048, // ~2.9 GB
      downloadUrl:
          'https://huggingface.co/google/gemma-3n-E2B-it-litert-lm-preview/resolve/main/gemma-3n-E2B-it.litertlm',
      capabilities: ['text', 'vision', 'audio', 'tools'],
      contextSize: 4096,
      quantization: '4-bit',
    ),
    'gemma-3n-e4b': LiteRTModel(
      id: 'gemma-3n-e4b',
      name: 'Gemma 3n E4B',
      description: 'Google Gemma 3n E4B - largest on-device model with vision.',
      sizeBytes: 4440891392, // ~4.1 GB
      downloadUrl:
          'https://huggingface.co/google/gemma-3n-E4B-it-litert-lm-preview/resolve/main/gemma-3n-E4B-it.litertlm',
      capabilities: ['text', 'vision', 'audio', 'tools'],
      contextSize: 4096,
      quantization: '4-bit',
    ),
    'phi-4-mini': LiteRTModel(
      id: 'phi-4-mini',
      name: 'Phi-4 Mini',
      description: 'Microsoft Phi-4 Mini - efficient reasoning model.',
      sizeBytes: 3909091328, // ~3.6 GB
      downloadUrl:
          'https://huggingface.co/litert-community/Phi-4-mini-instruct/resolve/main/Phi-4-mini-instruct_multi-prefill-seq_q8_ekv4096.litertlm',
      capabilities: ['text', 'tools'],
      contextSize: 4096,
      quantization: '8-bit',
    ),
    'qwen2.5-1.5b': LiteRTModel(
      id: 'qwen2.5-1.5b',
      name: 'Qwen 2.5 1.5B',
      description: 'Alibaba Qwen 2.5 1.5B - great for multilingual tasks.',
      sizeBytes: 1598029824, // ~1.5 GB
      downloadUrl:
          'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm',
      capabilities: ['text', 'tools'],
      contextSize: 4096,
      quantization: '8-bit',
    ),
  };

  ModelDownloadService(this._storage, {http.Client? client})
    : _client = client ?? http.Client();

  /// Get the models directory path
  Future<Directory> getModelsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/litert_models');

    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    return modelsDir;
  }

  /// Get the path to a downloaded model
  Future<String?> getModelPath(String modelId) async {
    final modelsDir = await getModelsDirectory();
    final modelFile = File('${modelsDir.path}/$modelId.litertlm');

    if (await modelFile.exists()) {
      return modelFile.path;
    }

    return null;
  }

  /// Check if a model is downloaded
  Future<bool> isModelDownloaded(String modelId) async {
    final path = await getModelPath(modelId);
    return path != null;
  }

  /// Get list of all available models with download status
  Future<List<ModelInfo>> getAvailableModels() async {
    final models = <ModelInfo>[];

    for (final entry in availableModels.entries) {
      final isDownloaded = await isModelDownloaded(entry.key);
      models.add(
        ModelInfo(
          id: entry.value.id,
          name: entry.value.name,
          description: entry.value.description,
          sizeBytes: entry.value.sizeBytes,
          isDownloaded: isDownloaded,
          capabilities: entry.value.capabilities,
          downloadUrl: entry.value.downloadUrl,
        ),
      );
    }

    return models;
  }

  /// Get list of downloaded models
  Future<List<ModelInfo>> getDownloadedModels() async {
    final allModels = await getAvailableModels();
    return allModels.where((m) => m.isDownloaded).toList();
  }

  /// Start downloading a model
  ///
  /// Returns a stream of download progress updates.
  /// Cancel the download by calling [cancelDownload].
  Stream<ModelDownloadProgress> downloadModel(String modelId) {
    final model = availableModels[modelId];
    if (model == null) {
      throw ArgumentError('Unknown model: $modelId');
    }

    // Check if already downloading
    if (_activeDownloads.containsKey(modelId)) {
      final controller = _progressControllers[modelId];
      if (controller != null) {
        return controller.stream;
      }
    }

    // Create progress controller
    final controller = StreamController<ModelDownloadProgress>.broadcast();
    _progressControllers[modelId] = controller;

    // Start download
    _startDownload(modelId, model, controller);

    return controller.stream;
  }

  Future<void> _startDownload(
    String modelId,
    LiteRTModel model,
    StreamController<ModelDownloadProgress> controller,
  ) async {
    try {
      controller.add(
        ModelDownloadProgress(
          modelId: modelId,
          status: DownloadStatus.starting,
          bytesDownloaded: 0,
          totalBytes: model.sizeBytes,
          progress: 0,
        ),
      );

      final modelsDir = await getModelsDirectory();
      final modelFile = File('${modelsDir.path}/$modelId.litertlm');
      final tempFile = File('${modelsDir.path}/$modelId.litertlm.download');

      // Check for partial download (resume support)
      int resumeFrom = 0;
      if (await tempFile.exists()) {
        resumeFrom = await tempFile.length();
        _log('Resuming download from byte $resumeFrom');
      }

      // Create HTTP request with range header for resume
      final request = http.Request('GET', Uri.parse(model.downloadUrl));
      if (resumeFrom > 0) {
        request.headers['Range'] = 'bytes=$resumeFrom-';
      }

      // Add authorization header for Hugging Face (optional)
      // request.headers['Authorization'] = 'Bearer $hfToken';

      final response = await _client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to download model',
        );
      }

      final totalBytes = resumeFrom + (response.contentLength ?? 0);
      var downloadedBytes = resumeFrom;

      controller.add(
        ModelDownloadProgress(
          modelId: modelId,
          status: DownloadStatus.downloading,
          bytesDownloaded: downloadedBytes,
          totalBytes: totalBytes,
          progress: downloadedBytes / totalBytes,
        ),
      );

      // Open file for writing (append mode for resume)
      final sink = tempFile.openWrite(
        mode: resumeFrom > 0 ? FileMode.append : FileMode.write,
      );

      // Track download for cancellation
      final cancelableDownload = CancelableDownload();
      _activeDownloads[modelId] = cancelableDownload;

      await for (final chunk in response.stream) {
        // Check for cancellation
        if (cancelableDownload.isCancelled) {
          await sink.close();
          throw DownloadCancelledException();
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;

        // Emit progress (throttled to avoid too many updates)
        final progress = downloadedBytes / totalBytes;
        controller.add(
          ModelDownloadProgress(
            modelId: modelId,
            status: DownloadStatus.downloading,
            bytesDownloaded: downloadedBytes,
            totalBytes: totalBytes,
            progress: progress,
          ),
        );
      }

      await sink.close();

      // Rename temp file to final name
      await tempFile.rename(modelFile.path);

      // Save metadata
      await _saveModelMetadata(modelId, modelFile.path, totalBytes);

      controller.add(
        ModelDownloadProgress(
          modelId: modelId,
          status: DownloadStatus.completed,
          bytesDownloaded: totalBytes,
          totalBytes: totalBytes,
          progress: 1.0,
        ),
      );

      _log('Model $modelId downloaded successfully');
    } on DownloadCancelledException {
      controller.add(
        ModelDownloadProgress(
          modelId: modelId,
          status: DownloadStatus.cancelled,
          bytesDownloaded: 0,
          totalBytes: model.sizeBytes,
          progress: 0,
        ),
      );
      _log('Download cancelled: $modelId');
    } catch (e) {
      _log('Download error for $modelId: $e');
      controller.add(
        ModelDownloadProgress(
          modelId: modelId,
          status: DownloadStatus.failed,
          bytesDownloaded: 0,
          totalBytes: model.sizeBytes,
          progress: 0,
          error: e.toString(),
        ),
      );
    } finally {
      _activeDownloads.remove(modelId);
      await controller.close();
      _progressControllers.remove(modelId);
    }
  }

  /// Cancel an active download
  void cancelDownload(String modelId) {
    final download = _activeDownloads[modelId];
    if (download != null) {
      download.cancel();
    }
  }

  /// Delete a downloaded model
  Future<bool> deleteModel(String modelId) async {
    try {
      final modelsDir = await getModelsDirectory();
      final modelFile = File('${modelsDir.path}/$modelId.litertlm');
      final tempFile = File('${modelsDir.path}/$modelId.litertlm.download');

      if (await modelFile.exists()) {
        await modelFile.delete();
      }
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Remove metadata
      await _removeModelMetadata(modelId);

      _log('Model $modelId deleted');
      return true;
    } catch (e) {
      _log('Error deleting model $modelId: $e');
      return false;
    }
  }

  /// Get total storage used by downloaded models
  Future<int> getStorageUsed() async {
    final modelsDir = await getModelsDirectory();
    int totalSize = 0;

    if (await modelsDir.exists()) {
      await for (final entity in modelsDir.list()) {
        if (entity is File && entity.path.endsWith('.litertlm')) {
          totalSize += await entity.length();
        }
      }
    }

    return totalSize;
  }

  /// Clear all downloaded models
  Future<void> clearAllModels() async {
    final modelsDir = await getModelsDirectory();

    if (await modelsDir.exists()) {
      await for (final entity in modelsDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }

    // Clear all metadata
    for (final modelId in availableModels.keys) {
      await _removeModelMetadata(modelId);
    }

    _log('All models cleared');
  }

  Future<void> _saveModelMetadata(String modelId, String path, int size) async {
    final metadata = {
      'path': path,
      'size': size,
      'downloadedAt': DateTime.now().toIso8601String(),
    };
    await _storage.setString('litert_model_$modelId', jsonEncode(metadata));
  }

  Future<void> _removeModelMetadata(String modelId) async {
    await _storage.remove('litert_model_$modelId');
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[ModelDownloadService] $message');
  }

  /// Dispose of resources
  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    _activeDownloads.clear();
    _client.close();
  }
}

/// Information about a LiteRT-LM model
class LiteRTModel {
  final String id;
  final String name;
  final String description;
  final int sizeBytes;
  final String downloadUrl;
  final List<String> capabilities;
  final int contextSize;
  final String quantization;

  const LiteRTModel({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.capabilities,
    required this.contextSize,
    required this.quantization,
  });
}

/// Download progress information
class ModelDownloadProgress {
  final String modelId;
  final DownloadStatus status;
  final int bytesDownloaded;
  final int totalBytes;
  final double progress; // 0.0 to 1.0
  final String? error;

  const ModelDownloadProgress({
    required this.modelId,
    required this.status,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.progress,
    this.error,
  });

  /// Human-readable progress string (e.g., "234 MB / 557 MB")
  String get progressString {
    String formatBytes(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
      }
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }

    return '${formatBytes(bytesDownloaded)} / ${formatBytes(totalBytes)}';
  }

  /// Percentage string (e.g., "42%")
  String get percentString => '${(progress * 100).toStringAsFixed(0)}%';
}

/// Download status enum
enum DownloadStatus { starting, downloading, completed, failed, cancelled }

/// Helper class for cancellable downloads
class CancelableDownload {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

/// Exception thrown when download is cancelled
class DownloadCancelledException implements Exception {
  @override
  String toString() => 'Download was cancelled';
}
