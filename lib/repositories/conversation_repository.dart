import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:private_chat_hub/models/comparison_conversation.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/tool_models.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';

/// Persists conversations as session manifests and immutable-ish turn files.
class ConversationRepository {
  ConversationRepository(this._knowledgeStore);

  final KnowledgeStoreService _knowledgeStore;

  List<Conversation> getConversations({
    String? projectId,
    bool excludeProjectConversations = false,
  }) {
    final manifests = _sessionManifestFiles();
    final conversations = manifests
        .map(_readConversation)
        .whereType<Conversation>();

    return conversations.where((conversation) {
      if (projectId != null) {
        return conversation.projectId == projectId;
      }
      if (excludeProjectConversations) {
        return conversation.projectId == null;
      }
      return true;
    }).toList();
  }

  Conversation? getConversation(String id) {
    final manifest = _findManifestFile(id);
    if (manifest == null) {
      return null;
    }
    return _readConversation(manifest);
  }

  Future<void> saveConversation(Conversation conversation) async {
    final sessionDirectory = _knowledgeStore.sessionDirectory(
      createdAt: conversation.createdAt,
      conversationId: conversation.id,
    );
    final turnsDirectory = _knowledgeStore.turnsDirectory(
      createdAt: conversation.createdAt,
      conversationId: conversation.id,
    );
    final attachmentsDirectory = _knowledgeStore.attachmentsDirectory(
      createdAt: conversation.createdAt,
      conversationId: conversation.id,
    );

    await sessionDirectory.create(recursive: true);
    await _knowledgeStore.writeDocument(
      File(p.join(sessionDirectory.path, 'SESSION.md')),
      _sessionMetadata(conversation),
      _sessionBody(conversation),
    );

    await _knowledgeStore.clearDirectory(turnsDirectory);
    await _knowledgeStore.clearDirectory(attachmentsDirectory);
    await turnsDirectory.create(recursive: true);
    await attachmentsDirectory.create(recursive: true);

    for (final message in conversation.messages) {
      final metadata = await _turnMetadata(
        conversation: conversation,
        message: message,
        attachmentsDirectory: attachmentsDirectory,
      );

      final timestamp = message.timestamp.toUtc().toIso8601String().replaceAll(
        ':',
        '-',
      );
      final file = File(
        p.join(
          turnsDirectory.path,
          '${timestamp}_${message.role.name}_${message.id}.md',
        ),
      );
      await _knowledgeStore.writeDocument(file, metadata, message.text);
    }
  }

  Future<void> deleteConversation(String id) async {
    final manifest = _findManifestFile(id);
    if (manifest == null) {
      return;
    }

    final directory = manifest.parent;
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> deleteProjectConversations(String projectId) async {
    final conversations = getConversations(projectId: projectId);
    for (final conversation in conversations) {
      await deleteConversation(conversation.id);
    }
  }

  Future<void> deleteAllConversations() async {
    await _knowledgeStore.clearDirectory(_knowledgeStore.historyRoot);
    final currentConversation = _knowledgeStore.currentConversationFile();
    if (await currentConversation.exists()) {
      await currentConversation.delete();
    }
  }

  String? getCurrentConversationId() {
    final file = _knowledgeStore.currentConversationFile();
    if (!file.existsSync()) {
      return null;
    }
    final document = _knowledgeStore.readDocument(file);
    return document.metadata['id'] as String?;
  }

  Future<void> setCurrentConversationId(String? id) async {
    final file = _knowledgeStore.currentConversationFile();
    if (id == null) {
      if (await file.exists()) {
        await file.delete();
      }
      return;
    }

    await _knowledgeStore.writeDocument(file, {
      'id': id,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, id);
  }

  List<File> _sessionManifestFiles() {
    return _knowledgeStore
        .listMarkdownFiles(_knowledgeStore.historyRoot, recursive: true)
        .where((file) => p.basename(file.path) == 'SESSION.md')
        .toList();
  }

  File? _findManifestFile(String id) {
    for (final file in _sessionManifestFiles()) {
      final document = _knowledgeStore.readDocument(file);
      if (document.metadata['id'] == id) {
        return file;
      }
    }
    return null;
  }

  Conversation _readConversation(File manifestFile) {
    final document = _knowledgeStore.readDocument(manifestFile);
    final metadata = Map<String, dynamic>.from(document.metadata);
    final turnsDirectory = Directory(p.join(manifestFile.parent.path, 'turns'));
    final turnFiles = _knowledgeStore.listMarkdownFiles(turnsDirectory)
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    final messages = turnFiles
        .map((file) => _readMessage(file, manifestFile.parent))
        .toList();

    final conversationJson = {
      ...metadata,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
    if (metadata['isComparisonMode'] == true) {
      return ComparisonConversation.fromJson(conversationJson);
    }
    return Conversation.fromJson(conversationJson);
  }

  Message _readMessage(File turnFile, Directory sessionDirectory) {
    final document = _knowledgeStore.readDocument(turnFile);
    final metadata = document.metadata;
    final attachments = <Attachment>[
      for (final raw in (metadata['attachments'] as List<dynamic>? ?? const []))
        _readAttachment(
          Map<String, dynamic>.from(raw as Map),
          sessionDirectory,
        ),
    ];

    final modelSourceName = metadata['modelSource'] as String?;
    final statusName = metadata['status'] as String?;

    return Message(
      id: metadata['id'] as String,
      text: document.body,
      isMe: metadata['isMe'] as bool? ?? false,
      timestamp: DateTime.parse(metadata['timestamp'] as String),
      role: MessageRole.values.firstWhere(
        (role) => role.name == metadata['role'],
        orElse: () => MessageRole.user,
      ),
      isStreaming: metadata['isStreaming'] as bool? ?? false,
      isError: metadata['isError'] as bool? ?? false,
      errorMessage: metadata['errorMessage'] as String?,
      attachments: attachments,
      modelSource: modelSourceName == null
          ? null
          : ModelSource.values.firstWhere(
              (value) => value.name == modelSourceName,
              orElse: () => ModelSource.user,
            ),
      toolCalls: (metadata['toolCalls'] as List<dynamic>? ?? const [])
          .map(
            (item) => ToolCall.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      statusMessage: metadata['statusMessage'] as String?,
      status: statusName == null
          ? MessageStatus.sent
          : MessageStatus.values.firstWhere(
              (value) => value.name == statusName,
              orElse: () => MessageStatus.sent,
            ),
      queuedAt: metadata['queuedAt'] == null
          ? null
          : DateTime.parse(metadata['queuedAt'] as String),
    );
  }

  Attachment _readAttachment(
    Map<String, dynamic> metadata,
    Directory sessionDirectory,
  ) {
    final relativePath = metadata['path'] as String;
    final file = File(p.join(sessionDirectory.path, relativePath));
    final bytes = file.existsSync() ? file.readAsBytesSync() : Uint8List(0);
    return Attachment(
      id: metadata['id'] as String,
      name: metadata['name'] as String,
      mimeType: metadata['mimeType'] as String,
      data: bytes,
      size: metadata['size'] as int? ?? bytes.length,
    );
  }

  Map<String, dynamic> _sessionMetadata(Conversation conversation) {
    final metadata = conversation.toJson()..remove('messages');
    if (conversation is ComparisonConversation) {
      metadata['isComparisonMode'] = true;
    }
    return metadata;
  }

  String _sessionBody(Conversation conversation) {
    final buffer = StringBuffer()..writeln('# ${conversation.title}');

    if (conversation.systemPrompt != null &&
        conversation.systemPrompt!.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## System Prompt')
        ..writeln()
        ..writeln(conversation.systemPrompt);
    }

    if (conversation.projectId != null) {
      buffer
        ..writeln()
        ..writeln('Project: ${conversation.projectId}');
    }

    return buffer.toString().trimRight();
  }

  Future<Map<String, dynamic>> _turnMetadata({
    required Conversation conversation,
    required Message message,
    required Directory attachmentsDirectory,
  }) async {
    final attachments = <Map<String, dynamic>>[];
    for (final attachment in message.attachments) {
      final safeName = _knowledgeStore.sanitizeFileName(attachment.name);
      final fileName = '${attachment.id}_$safeName';
      final file = File(p.join(attachmentsDirectory.path, fileName));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(attachment.data, flush: true);
      attachments.add({
        'id': attachment.id,
        'name': attachment.name,
        'mimeType': attachment.mimeType,
        'size': attachment.size,
        'path': _knowledgeStore.relativePath(
          file,
          from: _knowledgeStore
              .sessionDirectory(
                createdAt: conversation.createdAt,
                conversationId: conversation.id,
              )
              .path,
        ),
      });
    }

    return {
      'id': message.id,
      'timestamp': message.timestamp.toIso8601String(),
      'role': message.role.name,
      'isMe': message.isMe,
      'isStreaming': message.isStreaming,
      'isError': message.isError,
      'errorMessage': message.errorMessage,
      'attachments': attachments,
      'modelSource': message.modelSource?.name,
      'toolCalls': message.toolCalls.map((call) => call.toJson()).toList(),
      'statusMessage': message.statusMessage,
      'status': message.status.name,
      'queuedAt': message.queuedAt?.toIso8601String(),
    };
  }
}

class MarkdownConversationRepository extends ConversationRepository {
  MarkdownConversationRepository(super.knowledgeStore);
}
