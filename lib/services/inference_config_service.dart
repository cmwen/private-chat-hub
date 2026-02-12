import 'dart:async';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing inference mode configuration
///
/// Handles persistence and state of:
/// - Current inference mode (remote/onDevice)
/// - Preferred backend for on-device inference
/// - Auto-unload settings
/// - Last used models
class InferenceConfigService {
  final SharedPreferences _prefs;

  static const String _inferenceModeKey = 'inference_mode';
  static const String _preferredBackendKey = 'litert_preferred_backend';
  static const String _autoUnloadKey = 'litert_auto_unload';
  static const String _autoUnloadTimeoutKey = 'litert_auto_unload_timeout';
  static const String _lastRemoteModelKey = 'last_remote_model';
  static const String _lastOnDeviceModelKey = 'last_on_device_model';

  // LiteLM Model Parameters
  static const String _temperatureKey = 'litert_temperature';
  static const String _topKKey = 'litert_top_k';
  static const String _topPKey = 'litert_top_p';
  static const String _maxTokensKey = 'litert_max_tokens';
  static const String _repetitionPenaltyKey = 'litert_repetition_penalty';

  // Hugging Face API Token
  static const String _huggingFaceTokenKey = 'huggingface_api_token';

  // Stream for mode changes
  final StreamController<InferenceMode> _modeController =
      StreamController<InferenceMode>.broadcast();

  InferenceConfigService(this._prefs);

  /// Stream of inference mode changes
  Stream<InferenceMode> get modeStream => _modeController.stream;

  /// Get current inference mode
  InferenceMode get inferenceMode {
    final modeString = _prefs.getString(_inferenceModeKey);
    if (modeString == 'onDevice') {
      return InferenceMode.onDevice;
    }
    return InferenceMode.remote; // Default to remote (Ollama)
  }

  /// Set inference mode
  Future<void> setInferenceMode(InferenceMode mode) async {
    await _prefs.setString(_inferenceModeKey, mode.name);
    _modeController.add(mode);
  }

  /// Get preferred backend for on-device inference
  String get preferredBackend {
    return _prefs.getString(_preferredBackendKey) ?? 'gpu';
  }

  /// Set preferred backend for on-device inference
  Future<void> setPreferredBackend(String backend) async {
    if (!['cpu', 'gpu', 'npu'].contains(backend)) {
      throw ArgumentError('Invalid backend: $backend');
    }
    await _prefs.setString(_preferredBackendKey, backend);
  }

  /// Check if auto-unload is enabled
  bool get autoUnloadEnabled {
    return _prefs.getBool(_autoUnloadKey) ?? true;
  }

  /// Set auto-unload preference
  Future<void> setAutoUnload(bool enabled) async {
    await _prefs.setBool(_autoUnloadKey, enabled);
  }

  /// Get auto-unload timeout in minutes
  int get autoUnloadTimeoutMinutes {
    return _prefs.getInt(_autoUnloadTimeoutKey) ?? 5;
  }

  /// Set auto-unload timeout in minutes
  Future<void> setAutoUnloadTimeout(int minutes) async {
    await _prefs.setInt(_autoUnloadTimeoutKey, minutes);
  }

  // ========== LiteLM MODEL PARAMETERS ==========

  /// Get temperature for LiteLM inference (0.0-2.0, default 0.7)
  /// Lower = more deterministic, Higher = more creative
  double get temperature {
    return _prefs.getDouble(_temperatureKey) ?? 0.7;
  }

  /// Set temperature for LiteLM inference
  Future<void> setTemperature(double value) async {
    if (value < 0.0 || value > 2.0) {
      throw ArgumentError('Temperature must be between 0.0 and 2.0');
    }
    await _prefs.setDouble(_temperatureKey, value);
  }

  /// Get top-k parameter for LiteLM (0-1000, default 40)
  /// Only consider the k most likely next tokens
  int get topK {
    return _prefs.getInt(_topKKey) ?? 40;
  }

  /// Set top-k parameter for LiteLM
  Future<void> setTopK(int value) async {
    if (value < 0 || value > 1000) {
      throw ArgumentError('Top-K must be between 0 and 1000');
    }
    await _prefs.setInt(_topKKey, value);
  }

  /// Get top-p parameter for LiteLM (0.0-1.0, default 0.9)
  /// Nucleus sampling: only consider tokens up to cumulative probability p
  double get topP {
    return _prefs.getDouble(_topPKey) ?? 0.9;
  }

  /// Set top-p parameter for LiteLM
  Future<void> setTopP(double value) async {
    if (value < 0.0 || value > 1.0) {
      throw ArgumentError('Top-P must be between 0.0 and 1.0');
    }
    await _prefs.setDouble(_topPKey, value);
  }

  /// Get max tokens for LiteLM response (default 512)
  int get maxTokens {
    return _prefs.getInt(_maxTokensKey) ?? 512;
  }

  /// Set max tokens for LiteLM response
  Future<void> setMaxTokens(int value) async {
    if (value < 1 || value > 4096) {
      throw ArgumentError('Max tokens must be between 1 and 4096');
    }
    await _prefs.setInt(_maxTokensKey, value);
  }

  /// Get repetition penalty for LiteLM (0.5-2.0, default 1.0)
  /// Penalizes repeated tokens; > 1.0 reduces repetition
  double get repetitionPenalty {
    return _prefs.getDouble(_repetitionPenaltyKey) ?? 1.0;
  }

  /// Set repetition penalty for LiteLM
  Future<void> setRepetitionPenalty(double value) async {
    if (value < 0.5 || value > 2.0) {
      throw ArgumentError('Repetition penalty must be between 0.5 and 2.0');
    }
    await _prefs.setDouble(_repetitionPenaltyKey, value);
  }

  /// Get all model parameters as a map (useful for passing to inference)
  Map<String, dynamic> getModelParameters() {
    return {
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
      'maxTokens': maxTokens,
      'repetitionPenalty': repetitionPenalty,
    };
  }

  /// Reset all model parameters to defaults
  Future<void> resetModelParameters() async {
    await Future.wait([
      _prefs.remove(_temperatureKey),
      _prefs.remove(_topKKey),
      _prefs.remove(_topPKey),
      _prefs.remove(_maxTokensKey),
      _prefs.remove(_repetitionPenaltyKey),
    ]);
  }

  // ========== HUGGING FACE AUTHENTICATION ==========

  /// Get Hugging Face API token
  String? get huggingFaceToken {
    return _prefs.getString(_huggingFaceTokenKey);
  }

  /// Set Hugging Face API token
  Future<void> setHuggingFaceToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _prefs.remove(_huggingFaceTokenKey);
    } else {
      await _prefs.setString(_huggingFaceTokenKey, token);
    }
  }

  /// Check if Hugging Face token is configured
  bool get hasHuggingFaceToken {
    final token = _prefs.getString(_huggingFaceTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Get a human-readable description of current model parameters
  String get modelParametersDescription {
    return 'Temperature: ${temperature.toStringAsFixed(2)}, '
        'Top-K: $topK, '
        'Top-P: ${topP.toStringAsFixed(2)}, '
        'Max Tokens: $maxTokens, '
        'Repetition Penalty: ${repetitionPenalty.toStringAsFixed(2)}';
  }

  /// Get last used remote (Ollama) model
  String? get lastRemoteModel {
    return _prefs.getString(_lastRemoteModelKey);
  }

  /// Set last used remote model
  Future<void> setLastRemoteModel(String modelId) async {
    await _prefs.setString(_lastRemoteModelKey, modelId);
  }

  /// Get last used on-device model
  String? get lastOnDeviceModel {
    return _prefs.getString(_lastOnDeviceModelKey);
  }

  /// Set last used on-device model
  Future<void> setLastOnDeviceModel(String modelId) async {
    await _prefs.setString(_lastOnDeviceModelKey, modelId);
  }

  /// Get the last used model for the current inference mode
  String? get lastModel {
    return inferenceMode == InferenceMode.remote
        ? lastRemoteModel
        : lastOnDeviceModel;
  }

  /// Set the last used model for the current inference mode
  Future<void> setLastModel(String modelId) async {
    if (inferenceMode == InferenceMode.remote) {
      await setLastRemoteModel(modelId);
    } else {
      await setLastOnDeviceModel(modelId);
    }
  }

  /// Check if on-device mode is available
  /// This can be used to show/hide the on-device option in the UI
  bool get isOnDeviceModeAvailable {
    // For now, always return true on Android
    // In the future, we could check for device capabilities
    return true;
  }

  /// Get a human-readable description of the current mode
  String get modeDescription {
    switch (inferenceMode) {
      case InferenceMode.remote:
        return 'Remote (Ollama Server)';
      case InferenceMode.onDevice:
        return 'On-Device (LiteRT)';
    }
  }

  /// Get a short label for the current mode
  String get modeLabel {
    switch (inferenceMode) {
      case InferenceMode.remote:
        return 'Remote';
      case InferenceMode.onDevice:
        return 'On-Device';
    }
  }

  /// Dispose of resources
  void dispose() {
    _modeController.close();
  }
}

/// Extension for InferenceMode serialization
extension InferenceModeExtension on InferenceMode {
  String get displayName {
    switch (this) {
      case InferenceMode.remote:
        return 'Remote (Ollama)';
      case InferenceMode.onDevice:
        return 'On-Device (LiteRT)';
    }
  }

  String get description {
    switch (this) {
      case InferenceMode.remote:
        return 'Run models on your Ollama server. More models available, unlimited size.';
      case InferenceMode.onDevice:
        return 'Run models directly on your device. Fully private, works offline.';
    }
  }

  String get iconName {
    switch (this) {
      case InferenceMode.remote:
        return 'cloud';
      case InferenceMode.onDevice:
        return 'phone_android';
    }
  }
}
