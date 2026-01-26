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
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
