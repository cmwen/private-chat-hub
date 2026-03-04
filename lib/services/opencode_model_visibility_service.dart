import 'package:shared_preferences/shared_preferences.dart';

/// Manages which OpenCode models are visible in the model selector.
///
/// Since OpenCode can expose 100+ models from many providers, users need
/// to curate which ones appear in the chat model selector.
class OpenCodeModelVisibilityService {
  final SharedPreferences _prefs;

  static const String _visibleModelsKey = 'opencode_visible_models';
  static const String _initializedKey = 'opencode_visibility_initialized';

  OpenCodeModelVisibilityService(this._prefs);

  /// Whether the visibility settings have been initialized.
  /// On first run, we show a recommended set of models.
  bool get isInitialized => _prefs.getBool(_initializedKey) ?? false;

  /// Mark visibility as initialized.
  Future<void> markInitialized() async {
    await _prefs.setBool(_initializedKey, true);
  }

  /// Get the set of visible model IDs.
  /// Returns null if not yet initialized (show default/recommended).
  Set<String>? getVisibleModelIds() {
    final json = _prefs.getStringList(_visibleModelsKey);
    if (json == null) return null;
    return json.toSet();
  }

  /// Set the visible model IDs.
  Future<void> setVisibleModelIds(Set<String> modelIds) async {
    await _prefs.setStringList(_visibleModelsKey, modelIds.toList());
    if (!isInitialized) {
      await markInitialized();
    }
  }

  /// Toggle a single model's visibility.
  Future<void> toggleModel(String modelId) async {
    final current = getVisibleModelIds() ?? {};
    if (current.contains(modelId)) {
      current.remove(modelId);
    } else {
      current.add(modelId);
    }
    await setVisibleModelIds(current);
  }

  /// Check if a specific model is visible.
  bool isModelVisible(String modelId) {
    final visible = getVisibleModelIds();
    if (visible == null) {
      // Not initialized — use recommended defaults
      return _isRecommendedModel(modelId);
    }
    return visible.contains(modelId);
  }

  /// Show all models.
  Future<void> showAll(List<String> allModelIds) async {
    await setVisibleModelIds(allModelIds.toSet());
  }

  /// Hide all models.
  Future<void> hideAll() async {
    await setVisibleModelIds({});
  }

  /// Set visibility to recommended defaults.
  Future<void> showRecommended(List<String> allModelIds) async {
    final recommended =
        allModelIds.where((id) => _isRecommendedModel(id)).toSet();
    await setVisibleModelIds(recommended);
  }

  /// Check if a model is in the "recommended" set.
  static bool _isRecommendedModel(String modelId) {
    final lower = modelId.toLowerCase();
    // Include popular/capable models from each major provider
    return lower.contains('claude-sonnet') ||
        lower.contains('claude-haiku') ||
        lower.contains('gpt-4') ||
        lower.contains('gpt-4o') ||
        lower.contains('gemini-2') ||
        lower.contains('gemini-pro') ||
        lower.contains('deepseek-r1') ||
        lower.contains('llama-4');
  }

  /// Get the count of visible models.
  int get visibleCount {
    final visible = getVisibleModelIds();
    return visible?.length ?? 0;
  }
}
