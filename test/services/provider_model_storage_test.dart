import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/services/provider_model_storage.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<StorageService> _buildStorage() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  return storage;
}

void main() {
  group('ProviderModelStorage', () {
    test('should store per provider', () async {
      final storage = await _buildStorage();
      final providerStorage = ProviderModelStorage(storage);

      await providerStorage.setSelectedModel(
        AiProviderType.ollama,
        'llama3.2:latest',
      );
      await providerStorage.setSelectedModel(AiProviderType.liteLlm, 'gpt-4o');

      expect(
        providerStorage.getSelectedModel(AiProviderType.ollama),
        'llama3.2:latest',
      );
      expect(
        providerStorage.getSelectedModel(AiProviderType.liteLlm),
        'gpt-4o',
      );
    });
  });
}
