import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('conversationUpdates emits when a conversation is updated', () async {
    final storage = StorageService();
    await storage.init();

    final manager = OllamaConnectionManager();
    final chatService = ChatService(manager, storage);

    final conversation = await chatService.createConversation(
      modelName: 'llama3.2',
      title: 'Test Conversation',
    );

    final updates = <String>[];
    final sub = chatService.conversationUpdates.listen((updated) {
      updates.add(updated.title);
    });

    final updatedConversation = conversation.copyWith(title: 'Updated Title');
    await chatService.updateConversation(updatedConversation);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(updates, contains('Updated Title'));

    await sub.cancel();
    chatService.dispose();
  });
}
