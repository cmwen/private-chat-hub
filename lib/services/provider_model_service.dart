import 'package:private_chat_hub/models/provider_models.dart';
import 'package:private_chat_hub/services/provider_chat_client.dart';

class ProviderModelService {
  Future<List<ProviderModelInfo>> listModels(ProviderChatClient client) {
    return client.listModels();
  }
}
