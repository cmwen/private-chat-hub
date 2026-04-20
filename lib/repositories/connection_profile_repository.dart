import 'package:private_chat_hub/models/connection.dart';
import 'package:private_chat_hub/repositories/connection_repository.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';

abstract class ConnectionProfileRepository {
  List<Connection> getConnections();

  Connection? getConnection(String id);

  Future<void> saveConnection(Connection connection);

  Future<void> deleteConnection(String id);

  String? getSelectedModel();

  Future<void> setSelectedModel(String? modelName);
}

class MarkdownConnectionProfileRepository
    implements ConnectionProfileRepository {
  final ConnectionRepository _repository;

  MarkdownConnectionProfileRepository(KnowledgeStoreService knowledgeStore)
    : _repository = ConnectionRepository(knowledgeStore);

  @override
  Future<void> deleteConnection(String id) async {
    final connections = _repository.getConnections()
      ..removeWhere((connection) => connection.id == id);
    await _repository.saveConnections(connections);
  }

  @override
  Connection? getConnection(String id) {
    return _repository
        .getConnections()
        .where((connection) => connection.id == id)
        .firstOrNull;
  }

  @override
  List<Connection> getConnections() {
    return _repository.getConnections();
  }

  @override
  String? getSelectedModel() {
    return _repository.getSelectedModel();
  }

  @override
  Future<void> saveConnection(Connection connection) async {
    final connections = _repository.getConnections();
    final index = connections.indexWhere((item) => item.id == connection.id);
    if (index == -1) {
      connections.add(connection);
    } else {
      connections[index] = connection;
    }
    await _repository.saveConnections(connections);
  }

  @override
  Future<void> setSelectedModel(String? modelName) async {
    if (modelName == null) {
      return;
    }
    await _repository.setSelectedModel(modelName);
  }
}
