import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/services/provider_selection_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<StorageService> _buildStorage() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  return storage;
}

void main() {
  group('ProviderSelectionService', () {
    test('should default to Ollama when unset', () async {
      final storage = await _buildStorage();
      final service = ProviderSelectionService(storage);

      expect(service.getSelectedProvider(), AiProviderType.ollama);
    });

    test('should persist selected provider', () async {
      final storage = await _buildStorage();
      final service = ProviderSelectionService(storage);

      await service.setSelectedProvider(AiProviderType.liteLlm);
      expect(service.getSelectedProvider(), AiProviderType.liteLlm);
    });
  });
}
