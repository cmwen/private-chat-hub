import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:private_chat_hub/utils/json_front_matter.dart';

/// Resolves and manages the on-disk knowledge store root.
class KnowledgeStoreService {
  KnowledgeStoreService._({Directory? overrideRoot})
    : _overrideRoot = overrideRoot;

  static KnowledgeStoreService? _instance;

  final Directory? _overrideRoot;
  Directory? _rootDirectory;

  static Future<KnowledgeStoreService> initialize({
    Directory? overrideRoot,
  }) async {
    final service = KnowledgeStoreService._(overrideRoot: overrideRoot);
    await service.init();
    _instance = service;
    return service;
  }

  static KnowledgeStoreService get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'KnowledgeStoreService has not been initialized. Call initialize() first.',
      );
    }
    return instance;
  }

  static void resetForTesting() {
    _instance = null;
  }

  Future<void> init() async {
    final root = _overrideRoot ?? await _defaultRootDirectory();
    await root.create(recursive: true);
    _rootDirectory = root;
  }

  Directory get rootDirectory {
    final rootDirectory = _rootDirectory;
    if (rootDirectory == null) {
      throw StateError(
        'KnowledgeStoreService not initialized. Call init() or initialize() first.',
      );
    }
    return rootDirectory;
  }

  Directory get historyRoot => Directory(
    p.join(rootDirectory.path, 'agents', 'private-chat-hub', 'history'),
  );

  Directory get projectsRoot =>
      Directory(p.join(rootDirectory.path, 'memory', 'shared', 'projects'));

  Directory get runtimeRoot => Directory(p.join(rootDirectory.path, 'runtime'));

  Directory get queueRoot => Directory(p.join(runtimeRoot.path, 'queue'));

  Directory get settingsRoot =>
      Directory(p.join(rootDirectory.path, 'settings'));

  Directory get appSettingsRoot => Directory(p.join(settingsRoot.path, 'app'));

  Directory get connectionsRoot =>
      Directory(p.join(settingsRoot.path, 'connections'));

  Directory sessionDirectory({
    required DateTime createdAt,
    required String conversationId,
  }) {
    return Directory(
      p.join(historyRoot.path, monthBucket(createdAt), conversationId),
    );
  }

  Directory turnsDirectory({
    required DateTime createdAt,
    required String conversationId,
  }) {
    return Directory(
      p.join(
        sessionDirectory(
          createdAt: createdAt,
          conversationId: conversationId,
        ).path,
        'turns',
      ),
    );
  }

  Directory attachmentsDirectory({
    required DateTime createdAt,
    required String conversationId,
  }) {
    return Directory(
      p.join(
        sessionDirectory(
          createdAt: createdAt,
          conversationId: conversationId,
        ).path,
        'attachments',
      ),
    );
  }

  File currentConversationFile() =>
      File(p.join(appSettingsRoot.path, 'current_conversation.md'));

  File selectedModelFile() =>
      File(p.join(appSettingsRoot.path, 'selected_model.md'));

  File queueFile() => File(p.join(queueRoot.path, 'queue.md'));

  String monthBucket(DateTime value) {
    final utc = value.toUtc();
    final month = utc.month.toString().padLeft(2, '0');
    return '${utc.year}-$month';
  }

  String slugify(String value) {
    final lower = value.toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String sanitizeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  List<File> listMarkdownFiles(Directory directory, {bool recursive = false}) {
    if (!directory.existsSync()) {
      return const [];
    }

    return directory
        .listSync(recursive: recursive)
        .whereType<File>()
        .where((file) => p.extension(file.path).toLowerCase() == '.md')
        .toList();
  }

  MarkdownFrontMatterDocument readDocument(File file) {
    return decodeJsonFrontMatter(file.readAsStringSync());
  }

  Future<void> writeDocument(
    File file,
    Map<String, dynamic> metadata,
    String body,
  ) async {
    await file.parent.create(recursive: true);
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(
      encodeJsonFrontMatter(metadata: metadata, body: body),
    );
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  File fileFromRelativePath(String relativePath) {
    return File(p.join(rootDirectory.path, relativePath));
  }

  String relativePath(File file, {required String from}) {
    return p.relative(file.path, from: from);
  }

  Future<void> clearDirectory(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<Directory> _defaultRootDirectory() async {
    final baseDirectory = await getApplicationSupportDirectory();
    return Directory(p.join(baseDirectory.path, 'min-kb-store'));
  }
}
