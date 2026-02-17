import 'dart:async';
import 'package:private_chat_hub/services/litert_platform_channel.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/model_download_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages on-device model lifecycle for LiteRT-LM
///
/// Handles:
/// - Loading and unloading models
/// - Memory management with auto-unload
/// - Backend selection (CPU/GPU/NPU)
/// - Model switching
class ModelManager {
  final ModelDownloadService _downloadService;
  final LiteRTPlatformChannel _platformChannel;

  // Configuration
  static const Duration _defaultUnloadTimeout = Duration(minutes: 5);
  static const String _preferredBackendKey = 'litert_preferred_backend';
  static const String _autoUnloadKey = 'litert_auto_unload';
  static const String _lastModelKey = 'litert_last_model';

  // State
  String? _loadedModelId;
  String _preferredBackend = 'gpu';
  bool _autoUnloadEnabled = true;
  Timer? _unloadTimer;

  // State stream
  final StreamController<ModelManagerState> _stateController =
      StreamController<ModelManagerState>.broadcast();

  ModelManager(
    StorageService storage, {
    ModelDownloadService? downloadService,
    String? huggingFaceToken,
  }) : _downloadService =
           downloadService ??
           ModelDownloadService(storage, huggingFaceToken: huggingFaceToken),
       _platformChannel = LiteRTPlatformChannel() {
    _loadPreferences();
  }

  /// Stream of manager state changes
  Stream<ModelManagerState> get stateStream => _stateController.stream;

  /// Currently loaded model ID
  String? get loadedModelId => _loadedModelId;

  /// Check if any model is loaded
  bool get isModelLoaded => _loadedModelId != null;

  /// Preferred backend for inference
  String get preferredBackend => _preferredBackend;

  /// Whether auto-unload is enabled
  bool get autoUnloadEnabled => _autoUnloadEnabled;

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _preferredBackend = prefs.getString(_preferredBackendKey) ?? 'gpu';
    _autoUnloadEnabled = prefs.getBool(_autoUnloadKey) ?? true;
  }

  /// Set preferred backend for inference
  Future<void> setPreferredBackend(String backend) async {
    if (!['cpu', 'gpu', 'npu'].contains(backend)) {
      throw ArgumentError('Invalid backend: $backend');
    }

    _preferredBackend = backend;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredBackendKey, backend);

    _log('Preferred backend set to: $backend');

    // If a model is loaded, reload it with the new backend
    if (_loadedModelId != null) {
      final modelId = _loadedModelId!;
      await unloadModel();
      await loadModel(modelId);
    }
  }

  /// Set auto-unload preference
  Future<void> setAutoUnload(bool enabled) async {
    _autoUnloadEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoUnloadKey, enabled);

    if (!enabled) {
      _cancelUnloadTimer();
    }

    _log('Auto-unload set to: $enabled');
  }

  /// Update Hugging Face token for downloads
  void updateHuggingFaceToken(String? token) {
    _downloadService.updateHuggingFaceToken(token);
    _log('Hugging Face token updated in ModelManager');
  }

  /// Get available models with download status
  Future<List<ModelInfo>> getAvailableModels() async {
    return _downloadService.getAvailableModels();
  }

  /// Get downloaded models
  Future<List<ModelInfo>> getDownloadedModels() async {
    return _downloadService.getDownloadedModels();
  }

  /// Load a model for inference
  ///
  /// If the model is not downloaded, throws an exception.
  /// If another model is loaded, it will be unloaded first.
  Future<bool> loadModel(String modelId, {String? backend}) async {
    _emitState(ModelManagerState.loading(modelId));

    try {
      // Check if model is downloaded
      final modelPath = await _downloadService.getModelPath(modelId);
      if (modelPath == null) {
        throw Exception('Model $modelId is not downloaded');
      }

      // Unload current model if different
      if (_loadedModelId != null && _loadedModelId != modelId) {
        await unloadModel();
      }

      // Load model
      final effectiveBackend = backend ?? _preferredBackend;
      final success = await _platformChannel.loadModel(
        modelPath: modelPath,
        backend: effectiveBackend,
      );

      if (success) {
        _loadedModelId = modelId;
        _saveLastModel(modelId);
        _emitState(ModelManagerState.loaded(modelId));
        _log('Model $modelId loaded with $effectiveBackend backend');
        return true;
      } else {
        _emitState(ModelManagerState.error('Failed to load model $modelId'));
        return false;
      }
    } catch (e) {
      _log('Error loading model $modelId: $e');
      _emitState(ModelManagerState.error(e.toString()));
      return false;
    }
  }

  /// Unload the currently loaded model
  Future<void> unloadModel() async {
    if (_loadedModelId == null) return;

    final modelId = _loadedModelId!;
    _emitState(ModelManagerState.unloading(modelId));

    try {
      await _platformChannel.unloadModel();
      _loadedModelId = null;
      _cancelUnloadTimer();
      _emitState(ModelManagerState.idle());
      _log('Model $modelId unloaded');
    } catch (e) {
      _log('Error unloading model: $e');
      _emitState(ModelManagerState.error(e.toString()));
    }
  }

  /// Call this after each inference to reset the auto-unload timer
  void resetUnloadTimer() {
    if (!_autoUnloadEnabled || _loadedModelId == null) return;

    _cancelUnloadTimer();
    _unloadTimer = Timer(_defaultUnloadTimeout, () {
      _log('Auto-unloading model due to inactivity');
      unloadModel();
    });
  }

  void _cancelUnloadTimer() {
    _unloadTimer?.cancel();
    _unloadTimer = null;
  }

  /// Download a model
  Stream<ModelDownloadProgress> downloadModel(String modelId) {
    return _downloadService.downloadModel(modelId);
  }

  /// Cancel a model download
  void cancelDownload(String modelId) {
    _downloadService.cancelDownload(modelId);
  }

  /// Delete a downloaded model
  Future<bool> deleteModel(String modelId) async {
    // Unload if currently loaded
    if (_loadedModelId == modelId) {
      await unloadModel();
    }

    return _downloadService.deleteModel(modelId);
  }

  /// Get device capabilities
  Future<Map<String, bool>> getDeviceCapabilities() async {
    return _platformChannel.getDeviceCapabilities();
  }

  /// Get memory information
  Future<Map<String, int>> getMemoryInfo() async {
    return _platformChannel.getMemoryInfo();
  }

  /// Get benchmark results
  Future<Map<String, double>> getBenchmark() async {
    return _platformChannel.getBenchmark();
  }

  /// Get total storage used by models
  Future<int> getStorageUsed() async {
    return _downloadService.getStorageUsed();
  }

  /// Load the last used model
  Future<void> loadLastModel() async {
    final prefs = await SharedPreferences.getInstance();
    final lastModelId = prefs.getString(_lastModelKey);

    if (lastModelId != null) {
      final isDownloaded = await _downloadService.isModelDownloaded(
        lastModelId,
      );
      if (isDownloaded) {
        await loadModel(lastModelId);
      }
    }
  }

  Future<void> _saveLastModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastModelKey, modelId);
  }

  void _emitState(ModelManagerState state) {
    _stateController.add(state);
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[ModelManager] $message');
  }

  /// Dispose of resources
  void dispose() {
    _cancelUnloadTimer();
    _stateController.close();
    _downloadService.dispose();
  }
}

/// Model manager state
class ModelManagerState {
  final ModelManagerStatus status;
  final String? modelId;
  final String? error;

  const ModelManagerState._({required this.status, this.modelId, this.error});

  factory ModelManagerState.idle() =>
      const ModelManagerState._(status: ModelManagerStatus.idle);

  factory ModelManagerState.loading(String modelId) =>
      ModelManagerState._(status: ModelManagerStatus.loading, modelId: modelId);

  factory ModelManagerState.loaded(String modelId) =>
      ModelManagerState._(status: ModelManagerStatus.loaded, modelId: modelId);

  factory ModelManagerState.unloading(String modelId) => ModelManagerState._(
    status: ModelManagerStatus.unloading,
    modelId: modelId,
  );

  factory ModelManagerState.error(String error) =>
      ModelManagerState._(status: ModelManagerStatus.error, error: error);

  bool get isIdle => status == ModelManagerStatus.idle;
  bool get isLoading => status == ModelManagerStatus.loading;
  bool get isLoaded => status == ModelManagerStatus.loaded;
  bool get isUnloading => status == ModelManagerStatus.unloading;
  bool get isError => status == ModelManagerStatus.error;
}

/// Model manager status enum
enum ModelManagerStatus { idle, loading, loaded, unloading, error }
