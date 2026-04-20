import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:private_chat_hub/models/connection.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';

/// Persists connection profiles in the knowledge store.
class ConnectionRepository {
  final KnowledgeStoreService _knowledgeStore;

  ConnectionRepository(this._knowledgeStore);

  List<Connection> getConnections() {
    final files = _knowledgeStore.listMarkdownFiles(
      _knowledgeStore.connectionsRoot,
      recursive: true,
    );
    return files.map(_readConnection).toList();
  }

  Future<void> saveConnections(List<Connection> connections) async {
    final activeIds = connections.map((connection) => connection.id).toSet();
    final existingFiles = _knowledgeStore.listMarkdownFiles(
      _knowledgeStore.connectionsRoot,
      recursive: true,
    );

    for (final file in existingFiles) {
      final document = _knowledgeStore.readDocument(file);
      final id = document.metadata['id'];
      if (id is String && !activeIds.contains(id) && await file.exists()) {
        await file.delete();
      }
    }

    for (final connection in connections) {
      final existingFile = _findConnectionFile(connection.id);
      final slug = _knowledgeStore.slugify(connection.name);
      final file =
          existingFile ??
          File(
            p.join(
              _knowledgeStore.connectionsRoot.path,
              'connection-${slug.isEmpty ? 'default' : slug}-${connection.id}.md',
            ),
          );

      await _knowledgeStore.writeDocument(
        file,
        connection.toJson(),
        _body(connection),
      );
    }
  }

  String? getSelectedModel() {
    final file = _knowledgeStore.selectedModelFile();
    if (!file.existsSync()) {
      return null;
    }
    final document = _knowledgeStore.readDocument(file);
    return document.metadata['modelName'] as String?;
  }

  Future<void> setSelectedModel(String modelName) async {
    await _knowledgeStore.writeDocument(_knowledgeStore.selectedModelFile(), {
      'modelName': modelName,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, modelName);
  }

  File? _findConnectionFile(String id) {
    final files = _knowledgeStore.listMarkdownFiles(
      _knowledgeStore.connectionsRoot,
      recursive: true,
    );

    for (final file in files) {
      try {
        final document = _knowledgeStore.readDocument(file);
        if (document.metadata['id'] == id) {
          return file;
        }
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  Connection _readConnection(File file) {
    final document = _knowledgeStore.readDocument(file);
    return Connection.fromJson(document.metadata);
  }

  String _body(Connection connection) {
    final protocol = connection.useHttps ? 'https' : 'http';
    return '# ${connection.name}\n\n'
        '- Host: ${connection.host}\n'
        '- Port: ${connection.port}\n'
        '- Protocol: $protocol\n'
        '- Default: ${connection.isDefault}\n';
  }
}
