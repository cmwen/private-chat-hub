import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/services/storage_service.dart';

class ProviderModelStorage {
  static const _selectedModelKey = 'selected_model';
  final StorageService _storage;

  ProviderModelStorage(this._storage);

  String? getSelectedModel(AiProviderType providerType) {
    return _storage.getString(_keyForProvider(providerType));
  }

  Future<void> setSelectedModel(
    AiProviderType providerType,
    String modelName,
  ) async {
    await _storage.setString(_keyForProvider(providerType), modelName);
  }

  String _keyForProvider(AiProviderType providerType) {
    if (providerType == AiProviderType.ollama) return _selectedModelKey;
    return 'selected_model_${providerType.name}';
  }
}
