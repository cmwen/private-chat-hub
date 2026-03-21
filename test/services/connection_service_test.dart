import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storageService;
  late KnowledgeStoreService knowledgeStoreService;
  late ConnectionService connectionService;
  late Directory tempDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    KnowledgeStoreService.resetForTesting();
    tempDirectory = await Directory.systemTemp.createTemp(
      'connection-service-test',
    );
    knowledgeStoreService = await KnowledgeStoreService.initialize(
      overrideRoot: tempDirectory,
    );
    connectionService = ConnectionService(
      storageService,
      knowledgeStoreService: knowledgeStoreService,
    );
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
    KnowledgeStoreService.resetForTesting();
  });

  test('persists connection profiles and selected model', () async {
    final connection = await connectionService.addConnection(
      name: 'Local',
      host: 'localhost',
      setAsDefault: true,
    );
    await connectionService.setSelectedModel('llama3.2');

    final reloadedService = ConnectionService(
      storageService,
      knowledgeStoreService: knowledgeStoreService,
    );

    expect(
      knowledgeStoreService
          .listMarkdownFiles(
            knowledgeStoreService.connectionsRoot,
            recursive: true,
          )
          .any((file) => file.readAsStringSync().contains(connection.id)),
      isTrue,
    );
    expect(reloadedService.getConnections(), hasLength(1));
    expect(reloadedService.getDefaultConnection()!.id, connection.id);
    expect(reloadedService.getSelectedModel(), 'llama3.2');
  });

  test('reassigns default connection when default is deleted', () async {
    final first = await connectionService.addConnection(
      name: 'First',
      host: 'one.local',
      setAsDefault: true,
    );
    final second = await connectionService.addConnection(
      name: 'Second',
      host: 'two.local',
    );

    await connectionService.deleteConnection(first.id);

    expect(connectionService.getDefaultConnection()!.id, second.id);
    expect(connectionService.getConnections().single.isDefault, isTrue);
  });
}
