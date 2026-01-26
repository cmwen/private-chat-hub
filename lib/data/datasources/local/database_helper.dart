import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:private_chat_hub/domain/entities/conversation.dart';
import 'package:private_chat_hub/domain/entities/message.dart';
import 'package:private_chat_hub/domain/entities/connection.dart';
import 'package:private_chat_hub/domain/entities/ollama_model.dart';

class DatabaseHelper {
  static const _databaseName = 'private_chat_hub.db';
  static const _databaseVersion = 1;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        model_name TEXT,
        system_prompt TEXT,
        is_archived INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('user', 'assistant', 'system')),
        content TEXT NOT NULL,
        model_name TEXT,
        created_at INTEGER NOT NULL,
        token_count INTEGER,
        images TEXT,
        files TEXT,
        status TEXT DEFAULT 'sent',
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE VIRTUAL TABLE messages_fts USING fts5(
        content,
        content='messages',
        content_rowid='id'
      )
    ''');

    await db.execute('''
      CREATE TRIGGER messages_ai AFTER INSERT ON messages BEGIN
        INSERT INTO messages_fts(rowid, content) VALUES (new.id, new.content);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER messages_au AFTER UPDATE ON messages BEGIN
        UPDATE messages_fts SET content = new.content WHERE rowid = new.id;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER messages_ad AFTER DELETE ON messages BEGIN
        DELETE FROM messages_fts WHERE rowid = old.id;
      END
    ''');

    await db.execute('''
      CREATE TABLE connection_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER NOT NULL DEFAULT 11434,
        is_default INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_models (
        name TEXT PRIMARY KEY,
        size INTEGER,
        parameter_size TEXT,
        capabilities TEXT,
        last_updated INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_messages_conversation ON messages(conversation_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_created_at ON messages(created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_conversations_updated_at ON conversations(updated_at DESC)',
    );
  }

  Future<int> insertConversation(Conversation conversation) async {
    final db = await database;
    return await db.insert('conversations', {
      'title': conversation.title,
      'created_at': conversation.createdAt.millisecondsSinceEpoch,
      'updated_at': conversation.updatedAt.millisecondsSinceEpoch,
      'model_name': conversation.modelName,
      'system_prompt': conversation.systemPrompt,
      'is_archived': conversation.isArchived ? 1 : 0,
    });
  }

  Future<int> updateConversation(Conversation conversation) async {
    final db = await database;
    return await db.update(
      'conversations',
      {
        'title': conversation.title,
        'updated_at': conversation.updatedAt.millisecondsSinceEpoch,
        'model_name': conversation.modelName,
        'system_prompt': conversation.systemPrompt,
        'is_archived': conversation.isArchived ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  Future<int> deleteConversation(int id) async {
    final db = await database;
    return await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  Future<Conversation?> getConversation(int id) async {
    final db = await database;
    final maps = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _conversationFromMap(maps.first);
  }

  Future<List<Conversation>> getAllConversations({
    bool includeArchived = false,
  }) async {
    final db = await database;
    final maps = await db.query(
      'conversations',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'updated_at DESC',
    );

    return maps.map(_conversationFromMap).toList();
  }

  Future<int> insertMessage(Message message, int conversationId) async {
    final db = await database;
    final id = await db.insert('messages', {
      'conversation_id': conversationId,
      'role': message.role.name,
      'content': message.content,
      'model_name': message.modelName,
      'created_at': message.createdAt.millisecondsSinceEpoch,
      'token_count': message.tokenCount,
      'images': message.images?.isNotEmpty == true
          ? message.images!.join(',')
          : null,
      'files': message.files?.isNotEmpty == true
          ? message.files!.join(',')
          : null,
      'status': message.status.name,
    });

    await db.update(
      'conversations',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    return id;
  }

  Future<int> updateMessage(Message message) async {
    final db = await database;
    return await db.update(
      'messages',
      {
        'content': message.content,
        'model_name': message.modelName,
        'token_count': message.tokenCount,
        'status': message.status.name,
      },
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> deleteMessage(int id) async {
    final db = await database;
    return await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Message>> getMessages(int conversationId) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

    return maps.map(_messageFromMap).toList();
  }

  Future<List<Message>> searchMessages(String query) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT messages.* FROM messages_fts
      JOIN messages ON messages.id = messages_fts.rowid
      WHERE messages_fts MATCH ?
      ORDER BY messages.created_at DESC
      LIMIT 50
    ''',
      [query],
    );

    return maps.map(_messageFromMap).toList();
  }

  Future<int> insertConnectionProfile(ConnectionProfile profile) async {
    final db = await database;

    if (profile.isDefault) {
      await db.update('connection_profiles', {'is_default': 0});
    }

    return await db.insert('connection_profiles', {
      'name': profile.name,
      'host': profile.host,
      'port': profile.port,
      'is_default': profile.isDefault ? 1 : 0,
      'created_at': profile.createdAt.millisecondsSinceEpoch,
    });
  }

  Future<int> updateConnectionProfile(ConnectionProfile profile) async {
    final db = await database;

    if (profile.isDefault) {
      await db.update('connection_profiles', {'is_default': 0});
    }

    return await db.update(
      'connection_profiles',
      {
        'name': profile.name,
        'host': profile.host,
        'port': profile.port,
        'is_default': profile.isDefault ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<int> deleteConnectionProfile(int id) async {
    final db = await database;
    return await db.delete(
      'connection_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ConnectionProfile?> getDefaultConnectionProfile() async {
    final db = await database;
    final maps = await db.query(
      'connection_profiles',
      where: 'is_default = 1',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _connectionProfileFromMap(maps.first);
  }

  Future<List<ConnectionProfile>> getAllConnectionProfiles() async {
    final db = await database;
    final maps = await db.query(
      'connection_profiles',
      orderBy: 'is_default DESC, created_at DESC',
    );

    return maps.map(_connectionProfileFromMap).toList();
  }

  Future<void> cacheModel(OllamaModel model) async {
    final db = await database;
    await db.insert('cached_models', {
      'name': model.name,
      'size': model.size,
      'parameter_size': model.details?.parameterSize,
      'capabilities': model.details?.capabilities?.join(','),
      'last_updated': model.modifiedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<OllamaModel>> getCachedModels() async {
    final db = await database;
    final maps = await db.query('cached_models', orderBy: 'name ASC');

    return maps
        .map(
          (map) => OllamaModel(
            name: map['name'] as String,
            size: (map['size'] as int?) ?? 0,
            modifiedAt: DateTime.fromMillisecondsSinceEpoch(
              (map['last_updated'] as int?) ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
            details: ModelDetails(
              parameterSize: map['parameter_size'] as String?,
              capabilities: (map['capabilities'] as String?)?.split(','),
            ),
          ),
        )
        .toList();
  }

  Future<void> clearCachedModels() async {
    final db = await database;
    await db.delete('cached_models');
  }

  /// Clear all data from the database (conversations, messages, profiles, etc.)
  /// WARNING: This is a destructive operation and cannot be undone
  Future<void> clearAllData() async {
    final db = await database;

    // Delete in order to respect foreign key constraints
    await db.delete('messages'); // First delete messages
    await db.delete('conversations'); // Then conversations
    await db.delete('connection_profiles'); // Then connection profiles
    await db.delete('cached_models'); // Finally cached models

    // Note: FTS5 table is automatically synced with messages table
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Conversation _conversationFromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as int,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      modelName: map['model_name'] as String?,
      systemPrompt: map['system_prompt'] as String?,
      isArchived: (map['is_archived'] as int) == 1,
    );
  }

  Message _messageFromMap(Map<String, dynamic> map) {
    final imagesStr = map['images'] as String?;
    final filesStr = map['files'] as String?;

    return Message(
      id: map['id'] as int,
      conversationId: map['conversation_id'] as int,
      role: MessageRole.values.firstWhere(
        (r) => r.name == map['role'] as String,
      ),
      content: map['content'] as String,
      modelName: map['model_name'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      tokenCount: map['token_count'] as int?,
      images: imagesStr != null && imagesStr.isNotEmpty
          ? imagesStr.split(',')
          : null,
      files: filesStr != null && filesStr.isNotEmpty
          ? filesStr.split(',')
          : null,
      status: MessageStatus.values.firstWhere(
        (s) => s.name == map['status'] as String,
      ),
    );
  }

  ConnectionProfile _connectionProfileFromMap(Map<String, dynamic> map) {
    return ConnectionProfile(
      id: map['id'] as int,
      name: map['name'] as String,
      host: map['host'] as String,
      port: map['port'] as int,
      isDefault: (map['is_default'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
