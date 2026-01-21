import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LiteLlmSecureStorage {
  static const _apiKeyKey = 'lite_llm_api_key';
  final FlutterSecureStorage _storage;

  LiteLlmSecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> setApiKey(String? apiKey) async {
    if (apiKey == null || apiKey.trim().isEmpty) {
      await _storage.delete(key: _apiKeyKey);
      return;
    }
    await _storage.write(key: _apiKeyKey, value: apiKey.trim());
  }

  Future<String?> getApiKey() async {
    return _storage.read(key: _apiKeyKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _apiKeyKey);
  }
}
