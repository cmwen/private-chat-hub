import 'package:shared_preferences/shared_preferences.dart';

/// Manages which models are visible in app-wide model selectors.
///
/// The service name is retained for backwards compatibility, but it now
/// applies to all model IDs (Ollama, on-device, and OpenCode) and also stores
/// OpenCode provider-level visibility filters.
class OpenCodeModelVisibilityService {
  final SharedPreferences _prefs;

  static const String _visibleModelsKey = 'opencode_visible_models';
  static const String _visibleProvidersKey = 'opencode_visible_providers';
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
  /// Returns null if not yet initialized (show all by default).
  Set<String>? getVisibleModelIds() {
    final json = _prefs.getStringList(_visibleModelsKey);
    if (json == null) return null;
    return json.toSet();
  }

  /// Get the set of visible OpenCode provider IDs.
  ///
  /// Returns null when no explicit filter has been configured yet.
  Set<String>? getVisibleProviderIds() {
    final json = _prefs.getStringList(_visibleProvidersKey);
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

  /// Set the visible OpenCode provider IDs.
  Future<void> setVisibleProviderIds(Set<String> providerIds) async {
    await _prefs.setStringList(_visibleProvidersKey, providerIds.toList());
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

  /// Toggle a single OpenCode provider's visibility.
  Future<void> toggleProvider(String providerId) async {
    final current = getVisibleProviderIds() ?? {};
    if (current.contains(providerId)) {
      current.remove(providerId);
    } else {
      current.add(providerId);
    }
    await setVisibleProviderIds(current);
  }

  /// Check if a specific model is visible.
  bool isModelVisible(String modelId) {
    final visible = getVisibleModelIds();
    if (visible == null) {
      // Not initialized — OpenCode models are hidden by default,
      // all other sources (Ollama, on-device) are shown.
      return !_isOpenCodeModel(modelId);
    }
    return visible.contains(modelId);
  }

  /// Check if a model ID is an OpenCode model.
  static bool _isOpenCodeModel(String modelId) {
    return modelId.startsWith('opencode:');
  }

  /// Check if an OpenCode provider is visible.
  ///
  /// If no explicit provider filters are configured yet, this defaults to
  /// connected providers when available, otherwise all providers.
  bool isProviderVisible(String providerId, {Set<String>? connectedProviders}) {
    final visible = getVisibleProviderIds();
    if (visible != null) {
      return visible.contains(providerId);
    }

    if (connectedProviders != null && connectedProviders.isNotEmpty) {
      return connectedProviders.contains(providerId);
    }
    return true;
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
    final recommended = allModelIds
        .where((id) => _isRecommendedModel(id))
        .toSet();
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
