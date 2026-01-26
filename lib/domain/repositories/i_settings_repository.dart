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

  Future<void> clearAll();
}
