abstract class ISettingsRepository {
  Future<bool> isFirstLaunch();

  Future<void> setFirstLaunchComplete();

  Future<String?> getDefaultModel();

  Future<void> setDefaultModel(String modelName);

  Future<String> getThemeMode();

  Future<void> setThemeMode(String mode);

  Future<String?> getLastConnectionHost();

  Future<void> setLastConnectionHost(String host);

  Future<int?> getLastConnectionPort();

  Future<void> setLastConnectionPort(int port);

  Future<String?> getOpenAIApiKey();

  Future<void> setOpenAIApiKey(String apiKey);

  Future<String?> getOpenAIBaseUrl();

  Future<void> setOpenAIBaseUrl(String baseUrl);

  Future<String?> getOpenAIDefaultModel();

  Future<void> setOpenAIDefaultModel(String model);

  Future<String?> getDefaultProviderType();

  Future<void> setDefaultProviderType(String providerType);

  Future<String?> getLiteLLMEndpoint();

  Future<void> setLiteLLMEndpoint(String endpoint);

  Future<String?> getLiteLLMApiKey();

  Future<void> setLiteLLMApiKey(String apiKey);

  Future<String?> getLiteRTModelPath();

  Future<void> setLiteRTModelPath(String path);

  Future<void> clearAll();
}
