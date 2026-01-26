import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/repositories/i_settings_repository.dart';

class SettingsRepository implements ISettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static Future<SettingsRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository(prefs);
  }

  @override
  Future<bool> isFirstLaunch() async {
    return _prefs.getBool(StorageKeys.firstLaunch) ?? true;
  }

  @override
  Future<void> setFirstLaunchComplete() async {
    await _prefs.setBool(StorageKeys.firstLaunch, false);
  }

  @override
  Future<String?> getDefaultModel() async {
    return _prefs.getString(StorageKeys.defaultModelName);
  }

  @override
  Future<void> setDefaultModel(String modelName) async {
    await _prefs.setString(StorageKeys.defaultModelName, modelName);
  }

  @override
  Future<String> getThemeMode() async {
    return _prefs.getString(StorageKeys.themeMode) ?? 'system';
  }

  @override
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(StorageKeys.themeMode, mode);
  }

  @override
  Future<String?> getLastConnectionHost() async {
    return _prefs.getString(StorageKeys.lastConnectionHost);
  }

  @override
  Future<void> setLastConnectionHost(String host) async {
    await _prefs.setString(StorageKeys.lastConnectionHost, host);
  }

  @override
  Future<int?> getLastConnectionPort() async {
    return _prefs.getInt(StorageKeys.lastConnectionPort);
  }

  @override
  Future<void> setLastConnectionPort(int port) async {
    await _prefs.setInt(StorageKeys.lastConnectionPort, port);
  }

  @override
  Future<String?> getOpenAIApiKey() async {
    return _prefs.getString(StorageKeys.openaiApiKey);
  }

  @override
  Future<void> setOpenAIApiKey(String apiKey) async {
    await _prefs.setString(StorageKeys.openaiApiKey, apiKey);
  }

  @override
  Future<String?> getOpenAIBaseUrl() async {
    return _prefs.getString(StorageKeys.openaiBaseUrl);
  }

  @override
  Future<void> setOpenAIBaseUrl(String baseUrl) async {
    await _prefs.setString(StorageKeys.openaiBaseUrl, baseUrl);
  }

  @override
  Future<String?> getOpenAIDefaultModel() async {
    return _prefs.getString(StorageKeys.openaiDefaultModel);
  }

  @override
  Future<void> setOpenAIDefaultModel(String model) async {
    await _prefs.setString(StorageKeys.openaiDefaultModel, model);
  }

  @override
  Future<String?> getDefaultProviderType() async {
    return _prefs.getString(StorageKeys.defaultProviderType);
  }

  @override
  Future<void> setDefaultProviderType(String providerType) async {
    await _prefs.setString(StorageKeys.defaultProviderType, providerType);
  }

  @override
  Future<String?> getLiteLLMEndpoint() async {
    return _prefs.getString(StorageKeys.liteLLMEndpoint);
  }

  @override
  Future<void> setLiteLLMEndpoint(String endpoint) async {
    await _prefs.setString(StorageKeys.liteLLMEndpoint, endpoint);
  }

  @override
  Future<String?> getLiteLLMApiKey() async {
    return _prefs.getString(StorageKeys.liteLLMApiKey);
  }

  @override
  Future<void> setLiteLLMApiKey(String apiKey) async {
    await _prefs.setString(StorageKeys.liteLLMApiKey, apiKey);
  }

  @override
  Future<String?> getLiteRTModelPath() async {
    return _prefs.getString(StorageKeys.literTModelPath);
  }

  @override
  Future<void> setLiteRTModelPath(String path) async {
    await _prefs.setString(StorageKeys.literTModelPath, path);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
