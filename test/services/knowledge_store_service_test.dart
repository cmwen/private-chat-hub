import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';

void main() {
  late Directory tempDirectory;
  late KnowledgeStoreService knowledgeStoreService;

  setUp(() async {
    KnowledgeStoreService.resetForTesting();
    tempDirectory = await Directory.systemTemp.createTemp(
      'knowledge-store-test',
    );
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

  test('exposes knowledge store directory conventions', () {
    expect(knowledgeStoreService.rootDirectory.path, tempDirectory.path);
    expect(
      knowledgeStoreService.historyRoot.path,
      contains('agents/private-chat-hub/history'),
    );
    expect(
      knowledgeStoreService.projectsRoot.path,
      contains('memory/shared/projects'),
    );
    expect(
      knowledgeStoreService.connectionsRoot.path,
      contains('settings/connections'),
    );
  });

  test('writes and reads markdown documents with JSON front matter', () async {
    final file = File('${knowledgeStoreService.rootDirectory.path}/sample.md');
    await knowledgeStoreService.writeDocument(file, const {
      'title': 'Sample',
      'flags': ['a', 'b'],
      'count': 2,
      'enabled': true,
    }, '# Heading\n\nBody');

    final document = knowledgeStoreService.readDocument(file);

    expect(document.metadata['title'], 'Sample');
    expect(document.metadata['count'], 2);
    expect(document.metadata['enabled'], isTrue);
    expect(document.body, '# Heading\n\nBody');
  });
}
