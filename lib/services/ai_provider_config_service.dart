import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiProviderConfigService {
  static const _providerKey = 'ai_provider_type';
  final SharedPreferences _prefs;

  AiProviderConfigService(this._prefs);

  AiProviderType getSelectedProvider() {
    final stored = _prefs.getString(_providerKey);
    return parseAiProviderType(stored);
  }

  Future<void> setSelectedProvider(AiProviderType providerType) async {
    await _prefs.setString(_providerKey, providerType.name);
  }
}
