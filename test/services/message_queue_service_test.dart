import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';
import 'package:private_chat_hub/services/message_queue_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storageService;
  late KnowledgeStoreService knowledgeStoreService;
  late MessageQueueService messageQueueService;
  late Directory tempDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    KnowledgeStoreService.resetForTesting();
    tempDirectory = await Directory.systemTemp.createTemp('queue-service-test');
    knowledgeStoreService = await KnowledgeStoreService.initialize(
      overrideRoot: tempDirectory,
    );
    messageQueueService = MessageQueueService(
      storageService,
      knowledgeStoreService: knowledgeStoreService,
    );
  });

  tearDown(() async {
    messageQueueService.dispose();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
    KnowledgeStoreService.resetForTesting();
  });

  test('persists queue items to markdown manifest', () async {
    final queueItem = await messageQueueService.enqueue(
      conversationId: 'conversation-1',
      messageId: 'message-1',
    );

    final reloadedService = MessageQueueService(
      storageService,
      knowledgeStoreService: knowledgeStoreService,
    );
    addTearDown(reloadedService.dispose);

    expect(knowledgeStoreService.queueFile().existsSync(), isTrue);
    expect(reloadedService.getQueue(), hasLength(1));
    expect(reloadedService.getQueue().single.id, queueItem.id);
    expect(reloadedService.getNextQueueItem()!.messageId, 'message-1');
  });

  test('increments retry count and preserves ordering', () async {
    final item = await messageQueueService.enqueue(
      conversationId: 'conversation-1',
      messageId: 'message-1',
    );
    await messageQueueService.enqueue(
      conversationId: 'conversation-1',
      messageId: 'message-2',
    );

    final updated = await messageQueueService.incrementRetryCount(
      item.id,
      'offline',
    );

    expect(updated.retryCount, 1);
    expect(messageQueueService.getQueue().first.id, item.id);
    expect(messageQueueService.getQueue().first.errorMessage, 'offline');
  });
}
