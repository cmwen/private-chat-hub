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
