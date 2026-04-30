import 'dart:convert';

import 'package:private_chat_hub/models/queue_item.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';

/// Persists offline queue state in the knowledge store.
class QueueRepository {
  final KnowledgeStoreService _knowledgeStore;

  QueueRepository(this._knowledgeStore);

  List<QueueItem> getQueue() {
    final file = _knowledgeStore.queueFile();
    if (!file.existsSync()) {
      return <QueueItem>[];
    }

    final document = _knowledgeStore.readDocument(file);
    final items = jsonDecode(document.body) as List<dynamic>;
    return items
        .map((item) => QueueItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<QueueItem> getQueueItems() => getQueue();

  Future<void> saveQueue(List<QueueItem> queue) async {
    final file = _knowledgeStore.queueFile();
    final metadata = {
      'count': queue.length,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };

    await _knowledgeStore.writeDocument(
      file,
      metadata,
      const JsonEncoder.withIndent(
        '  ',
      ).convert(queue.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> saveQueueItems(List<QueueItem> queue) => saveQueue(queue);
}

class MarkdownQueueRepository extends QueueRepository {
  MarkdownQueueRepository(super.knowledgeStore);
}
