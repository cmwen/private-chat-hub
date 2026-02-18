import 'package:shared_preferences/shared_preferences.dart';

/// Keys for storing Ollama configuration in SharedPreferences
class OllamaConfigKeys {
  static const baseUrl = 'ollama_base_url';
  static const timeout = 'ollama_timeout';
  static const defaultModel = 'ollama_default_model';
  static const lastUsedModel = 'ollama_last_used_model';
  static const streamEnabled = 'ollama_stream_enabled';
  static const modelHistory = 'ollama_model_history';
  static const developerMode = 'developer_mode_enabled';
}

/// Service for persisting Ollama configuration using SharedPreferences
class OllamaConfigService {
  /// Default base URL for Ollama server
  static const defaultBaseUrl = 'http://localhost:11434';

  /// Default timeout in seconds (2 minutes)
  static const defaultTimeout = 120;

  /// Maximum timeout in seconds (10 minutes)
  static const maxTimeout = 600;

  /// Minimum timeout in seconds (30 seconds)
  static const minTimeout = 30;

  /// Maximum number of models to keep in history
  static const maxHistorySize = 10;

  SharedPreferences? _prefs;

  /// Get SharedPreferences instance
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get base URL for Ollama server
  Future<String> getBaseUrl() async {
    final prefs = await _preferences;
    return prefs.getString(OllamaConfigKeys.baseUrl) ?? defaultBaseUrl;
  }

  /// Set base URL for Ollama server
  Future<void> setBaseUrl(String url) async {
    final prefs = await _preferences;
    await prefs.setString(OllamaConfigKeys.baseUrl, url);
  }

  /// Get timeout in seconds
  Future<int> getTimeout() async {
    final prefs = await _preferences;
    return prefs.getInt(OllamaConfigKeys.timeout) ?? defaultTimeout;
  }

  /// Set timeout in seconds (will be clamped between minTimeout and maxTimeout)
  Future<void> setTimeout(int seconds) async {
    final prefs = await _preferences;
    // Clamp timeout between min and max values
    final clampedSeconds = seconds.clamp(minTimeout, maxTimeout);
    await prefs.setInt(OllamaConfigKeys.timeout, clampedSeconds);
  }

  /// Get default model name
  Future<String?> getDefaultModel() async {
    final prefs = await _preferences;
    return prefs.getString(OllamaConfigKeys.defaultModel);
  }

  /// Set default model name
  Future<void> setDefaultModel(String model) async {
    final prefs = await _preferences;
    await prefs.setString(OllamaConfigKeys.defaultModel, model);
  }

  /// Get last used model name
  Future<String?> getLastUsedModel() async {
    final prefs = await _preferences;
    return prefs.getString(OllamaConfigKeys.lastUsedModel);
  }

  /// Set last used model name and add to history
  Future<void> setLastUsedModel(String model) async {
    final prefs = await _preferences;
    await prefs.setString(OllamaConfigKeys.lastUsedModel, model);
    await _addToHistory(model);
  }

  /// Get whether streaming is enabled
  Future<bool> getStreamEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(OllamaConfigKeys.streamEnabled) ?? true;
  }

  /// Set whether streaming is enabled
  Future<void> setStreamEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(OllamaConfigKeys.streamEnabled, enabled);
  }

  /// Get whether developer mode is enabled (shows debug log popups).
  /// Disabled by default.
  Future<bool> getDeveloperMode() async {
    final prefs = await _preferences;
    return prefs.getBool(OllamaConfigKeys.developerMode) ?? false;
  }

  /// Set whether developer mode is enabled.
  Future<void> setDeveloperMode(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(OllamaConfigKeys.developerMode, enabled);
  }

  /// Get model history (recently used models)
  Future<List<String>> getModelHistory() async {
    final prefs = await _preferences;
    return prefs.getStringList(OllamaConfigKeys.modelHistory) ?? [];
  }

  /// Save model history
  Future<void> saveModelHistory(List<String> models) async {
    final prefs = await _preferences;
    final limitedHistory = models.take(maxHistorySize).toList();
    await prefs.setStringList(OllamaConfigKeys.modelHistory, limitedHistory);
  }

  /// Add a model to history
  Future<void> _addToHistory(String model) async {
    final history = await getModelHistory();

    // Remove if already exists
    history.remove(model);

    // Add to front
    history.insert(0, model);

    // Limit size
    await saveModelHistory(history);
  }

  /// Clear all configuration
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(OllamaConfigKeys.baseUrl);
    await prefs.remove(OllamaConfigKeys.timeout);
    await prefs.remove(OllamaConfigKeys.defaultModel);
    await prefs.remove(OllamaConfigKeys.lastUsedModel);
    await prefs.remove(OllamaConfigKeys.streamEnabled);
    await prefs.remove(OllamaConfigKeys.modelHistory);
  }

  /// Get all configuration as a map
  Future<Map<String, dynamic>> getAll() async {
    return {
      'baseUrl': await getBaseUrl(),
      'timeout': await getTimeout(),
      'defaultModel': await getDefaultModel(),
      'lastUsedModel': await getLastUsedModel(),
      'streamEnabled': await getStreamEnabled(),
      'modelHistory': await getModelHistory(),
    };
  }
}
