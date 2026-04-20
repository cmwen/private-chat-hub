import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/repositories/conversation_repository.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';

void main() {
  late Directory tempDirectory;
  late KnowledgeStoreService knowledgeStoreService;
  late MarkdownConversationRepository repository;

  setUp(() async {
    KnowledgeStoreService.resetForTesting();
    tempDirectory = await Directory.systemTemp.createTemp(
      'conversation-repo-test',
    );
    knowledgeStoreService = await KnowledgeStoreService.initialize(
      overrideRoot: tempDirectory,
    );
    repository = MarkdownConversationRepository(knowledgeStoreService);
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
    KnowledgeStoreService.resetForTesting();
  });

  test('persists conversations as session and turn markdown files', () async {
    final conversation = Conversation(
      id: 'conversation-1',
      title: 'Hello World',
      modelName: 'llama3.2',
      createdAt: DateTime.utc(2025, 1, 15, 12),
      updatedAt: DateTime.utc(2025, 1, 15, 12, 5),
      projectId: 'project-1',
      messages: [
        Message.user(
          id: 'message-1',
          text: 'Hi there',
          timestamp: DateTime.utc(2025, 1, 15, 12, 0),
          attachments: [
            Attachment(
              id: 'attachment-1',
              name: 'hello.txt',
              mimeType: 'text/plain',
              data: Uint8List.fromList('hello'.codeUnits),
              size: 5,
            ),
          ],
        ),
        Message.assistant(
          id: 'message-2',
          text: 'General Kenobi',
          timestamp: DateTime.utc(2025, 1, 15, 12, 1),
        ),
      ],
    );

    await repository.saveConversation(conversation);

    final sessionDir = knowledgeStoreService
        .sessionDirectory(
          createdAt: conversation.createdAt,
          conversationId: conversation.id,
        )
        .path;
    expect(File('$sessionDir/SESSION.md').existsSync(), isTrue);
    expect(Directory('$sessionDir/turns').existsSync(), isTrue);
    expect(Directory('$sessionDir/attachments').existsSync(), isTrue);

    final stored = repository.getConversation(conversation.id);
    expect(stored, isNotNull);
    expect(stored!.title, conversation.title);
    expect(stored.projectId, 'project-1');
    expect(stored.messages, hasLength(2));
    expect(stored.messages.first.attachments, hasLength(1));
    expect(stored.messages.first.attachments.first.textContent, 'hello');
    expect(stored.messages.last.text, 'General Kenobi');
  });
}
