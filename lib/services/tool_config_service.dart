import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:private_chat_hub/models/tool_models.dart';

/// Service for managing tool configuration.
///
/// Handles persistence of tool settings including API keys
/// and feature toggles.
class ToolConfigService {
  static const String _configKey = 'tool_config';
  static const String _jinaApiKeyKey = 'jina_api_key';

  final SharedPreferences _prefs;

  ToolConfigService(this._prefs);

  /// Gets the current tool configuration.
  ToolConfig getConfig() {
    final configJson = _prefs.getString(_configKey);
    if (configJson == null) {
      return const ToolConfig();
    }

    try {
      final json = jsonDecode(configJson) as Map<String, dynamic>;
      // Get API key separately (more secure)
      final apiKey = _prefs.getString(_jinaApiKeyKey);
      return ToolConfig.fromJson({...json, 'jinaApiKey': apiKey});
    } catch (e) {
      return const ToolConfig();
    }
  }

  /// Saves the tool configuration.
  Future<void> saveConfig(ToolConfig config) async {
    // Save API key separately
    if (config.jinaApiKey != null) {
      await _prefs.setString(_jinaApiKeyKey, config.jinaApiKey!);
    } else {
      await _prefs.remove(_jinaApiKeyKey);
    }

    // Save rest of config without API key
    final json = config.toJson();
    json.remove('jinaApiKey'); // Don't store in main config
    await _prefs.setString(_configKey, jsonEncode(json));
  }

  /// Enables or disables tool calling.
  Future<void> setToolsEnabled(bool enabled) async {
    final config = getConfig();
    await saveConfig(config.copyWith(enabled: enabled));
  }

  /// Enables or disables web search.
  Future<void> setWebSearchEnabled(bool enabled) async {
    final config = getConfig();
    await saveConfig(config.copyWith(webSearchEnabled: enabled));
  }

  /// Sets the Jina API key.
  Future<void> setJinaApiKey(String? apiKey) async {
    final config = getConfig();
    await saveConfig(config.copyWith(jinaApiKey: apiKey));
  }

  /// Gets the Jina API key.
  String? getJinaApiKey() {
    return _prefs.getString(_jinaApiKeyKey);
  }

  /// Checks if Jina API key is configured.
  bool hasJinaApiKey() {
    final key = getJinaApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Clears all tool configuration.
  Future<void> clearConfig() async {
    await _prefs.remove(_configKey);
    await _prefs.remove(_jinaApiKeyKey);
  }
}
