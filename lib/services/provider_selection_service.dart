import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/services/storage_service.dart';

class ProviderSelectionService {
  static const _providerKey = 'ai_provider_type';
  final StorageService _storage;

  ProviderSelectionService(this._storage);

  AiProviderType getSelectedProvider() {
    final value = _storage.getString(_providerKey);
    return parseAiProviderType(value);
  }

  Future<void> setSelectedProvider(AiProviderType providerType) async {
    await _storage.setString(_providerKey, providerType.name);
  }
}
