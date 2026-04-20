import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late KnowledgeStoreService knowledgeStoreService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDirectory = await Directory.systemTemp.createTemp('chat-service-test');
    KnowledgeStoreService.resetForTesting();
    knowledgeStoreService = await KnowledgeStoreService.initialize(
      overrideRoot: tempDirectory,
    );
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
    KnowledgeStoreService.resetForTesting();
  });

  test('conversationUpdates emits when a conversation is updated', () async {
    final storage = StorageService();
    await storage.init();

    final manager = OllamaConnectionManager();
    final chatService = ChatService(
      manager,
      storage,
      knowledgeStoreService: knowledgeStoreService,
    );

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
    expect(
      chatService.getConversation(conversation.id)?.title,
      'Updated Title',
    );

    await sub.cancel();
    chatService.dispose();
  });
}
