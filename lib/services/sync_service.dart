import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/project.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/project_service.dart';

/// Status information from a discovered sync server.
class SyncServerStatus {
  final String serverName;
  final int conversationCount;
  final int projectCount;
  final bool hasPin;

  const SyncServerStatus({
    required this.serverName,
    required this.conversationCount,
    required this.projectCount,
    required this.hasPin,
  });
}

/// Result of a sync operation.
class SyncResult {
  final int pulled;
  final int pushed;
  final String? error;

  const SyncResult({this.pulled = 0, this.pushed = 0, this.error});

  bool get hasError => error != null;
}

/// Client for syncing conversations and projects with the desktop Tauri app.
class SyncService {
  static const int syncPort = 9876;
  static const String _hostKey = 'sync_host';
  static const String _pinKey = 'sync_pin';
  static const String _lastSyncKey = 'sync_last_synced_at';
  static const String _enabledKey = 'sync_enabled';

  static const Duration _connectTimeout = Duration(milliseconds: 1500);
  static const Duration _syncTimeout = Duration(seconds: 30);

  final http.Client _client;
  SharedPreferences? _prefs;

  SyncService({http.Client? client}) : _client = client ?? http.Client();

  // ── Persisted config ────────────────────────────────────────────

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String? get savedHost => _prefs?.getString(_hostKey);
  String? get savedPin => _prefs?.getString(_pinKey);

  DateTime? get lastSyncedAt {
    final val = _prefs?.getString(_lastSyncKey);
    return val != null ? DateTime.tryParse(val) : null;
  }

  bool get isEnabled => _prefs?.getBool(_enabledKey) ?? false;

  /// Call this once to warm up the SharedPreferences cache.
  Future<void> init() async {
    await _getPrefs();
  }

  Future<void> saveConfig({String? host, String? pin, bool? enabled}) async {
    final prefs = await _getPrefs();
    if (host != null) await prefs.setString(_hostKey, host);
    if (pin != null) await prefs.setString(_pinKey, pin);
    if (enabled != null) await prefs.setBool(_enabledKey, enabled);
  }

  // ── HTTP helpers ────────────────────────────────────────────────

  Map<String, String> _headers([String? pinOverride]) {
    final pin = pinOverride ?? savedPin;
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (pin != null && pin.isNotEmpty) headers['X-Sync-Pin'] = pin;
    return headers;
  }

  // ── Discovery ───────────────────────────────────────────────────

  /// Streams discovered desktop sync-server IPs on the LAN.
  Stream<String> discoverDesktop() async* {
    // Check localhost first
    if (await _checkSyncServer('127.0.0.1') != null) yield '127.0.0.1';

    final ranges = await _getLocalNetworkRange();

    for (final baseIp in ranges) {
      final futures = <Future<String?>>[];

      for (int i = 1; i < 255; i++) {
        futures.add(_checkSyncServer('$baseIp.$i'));

        if (futures.length >= 20) {
          final results = await Future.wait(futures);
          for (final r in results) {
            if (r != null) yield r;
          }
          futures.clear();
        }
      }

      if (futures.isNotEmpty) {
        final results = await Future.wait(futures);
        for (final r in results) {
          if (r != null) yield r;
        }
      }
    }
  }

  Future<String?> _checkSyncServer(String host) async {
    try {
      final uri = Uri.parse('http://$host:$syncPort/api/sync/status');
      final response = await _client.get(uri).timeout(_connectTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('serverName')) return host;
      }
    } catch (_) {}
    return null;
  }

  /// Checks a specific host and returns its status (or null if unreachable).
  Future<SyncServerStatus?> checkServer(String host) async {
    try {
      final uri = Uri.parse('http://$host:$syncPort/api/sync/status');
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('serverName')) {
          return SyncServerStatus(
            serverName: data['serverName'] as String,
            conversationCount:
                (data['conversationCount'] as num?)?.toInt() ?? 0,
            projectCount: (data['projectCount'] as num?)?.toInt() ?? 0,
            hasPin: data['hasPin'] as bool? ?? false,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Sync ────────────────────────────────────────────────────────

  /// Performs a full pull+push sync with the desktop server.
  Future<SyncResult> syncWith(
    String host, {
    String? pin,
    required ChatService chatService,
    required ProjectService projectService,
  }) async {
    try {
      final headers = _headers(pin);
      final baseUrl = 'http://$host:$syncPort';

      final localConversations = chatService.getConversations();
      final localProjects = projectService.getProjects();

      // Build known-items list for delta pull
      final knownItems = [
        for (final c in localConversations)
          {'id': c.id, 'updatedAt': c.updatedAt.toIso8601String()},
        for (final p in localProjects)
          {'id': p.id, 'updatedAt': p.updatedAt.toIso8601String()},
      ];

      // ── Pull ──────────────────────────────────────────────────
      int pulled = 0;

      final pullResponse = await _client
          .post(
            Uri.parse('$baseUrl/api/sync/pull'),
            headers: headers,
            body: jsonEncode({'knownItems': knownItems}),
          )
          .timeout(_syncTimeout);

      if (pullResponse.statusCode == 200) {
        final pullData = jsonDecode(pullResponse.body) as Map<String, dynamic>;

        final receivedConvs =
            (pullData['conversations'] as List<dynamic>? ?? [])
                .map((c) => _conversationFromDesktop(c as Map<String, dynamic>))
                .toList();

        for (final conv in receivedConvs) {
          await _mergeConversation(conv, chatService);
          pulled++;
        }

        final receivedProjects = (pullData['projects'] as List<dynamic>? ?? [])
            .map((p) => _projectFromDesktop(p as Map<String, dynamic>))
            .toList();

        for (final proj in receivedProjects) {
          await _mergeProject(proj, projectService);
          pulled++;
        }
      }

      // ── Push ──────────────────────────────────────────────────
      int pushed = 0;

      final pushResponse = await _client
          .post(
            Uri.parse('$baseUrl/api/sync/push'),
            headers: headers,
            body: jsonEncode({
              'conversations': localConversations
                  .map(_conversationToDesktop)
                  .toList(),
              'projects': localProjects.map(_projectToDesktop).toList(),
            }),
          )
          .timeout(_syncTimeout);

      if (pushResponse.statusCode == 200) {
        final pushData = jsonDecode(pushResponse.body) as Map<String, dynamic>;
        pushed =
            ((pushData['mergedConversations'] as num?)?.toInt() ?? 0) +
            ((pushData['mergedProjects'] as num?)?.toInt() ?? 0);
      }

      // Save last-sync timestamp
      final prefs = await _getPrefs();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return SyncResult(pulled: pulled, pushed: pushed);
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  // ── Field mapping: Desktop → Android ────────────────────────────

  Conversation _conversationFromDesktop(Map<String, dynamic> data) {
    final rawMessages = data['messages'] as List<dynamic>? ?? [];
    final mappedMessages = rawMessages.map((m) {
      final msg = Map<String, dynamic>.from(m as Map<String, dynamic>);
      // content → text
      if (msg.containsKey('content') && !msg.containsKey('text')) {
        msg['text'] = msg['content'];
      }
      msg.remove('content');
      // Android-specific fields
      msg['isMe'] = msg['role'] == 'user';
      msg['isStreaming'] = false;
      msg['isError'] ??= false;
      return msg;
    }).toList();

    final mapped = Map<String, dynamic>.from(data);
    mapped['messages'] = mappedMessages;
    return Conversation.fromJson(mapped);
  }

  Project _projectFromDesktop(Map<String, dynamic> data) {
    final mapped = Map<String, dynamic>.from(data);
    // color hex → colorValue int
    if (mapped.containsKey('color') && !mapped.containsKey('colorValue')) {
      final hex = mapped['color'] as String?;
      if (hex != null) mapped['colorValue'] = _hexToColorValue(hex);
      mapped.remove('color');
    }
    // icon → iconName
    if (mapped.containsKey('icon') && !mapped.containsKey('iconName')) {
      mapped['iconName'] = mapped['icon'];
      mapped.remove('icon');
    }
    return Project.fromJson(mapped);
  }

  // ── Field mapping: Android → Desktop ────────────────────────────

  Map<String, dynamic> _conversationToDesktop(Conversation conversation) {
    final data = conversation.toJson();
    final rawMessages = data['messages'] as List<dynamic>? ?? [];
    data['messages'] = rawMessages.map((m) {
      final msg = Map<String, dynamic>.from(m as Map<String, dynamic>);
      // text → content
      if (msg.containsKey('text')) {
        msg['content'] = msg['text'];
        msg.remove('text');
      }
      // Remove Android-only fields
      msg
        ..remove('isMe')
        ..remove('isStreaming')
        ..remove('isError')
        ..remove('errorMessage');
      return msg;
    }).toList();
    return data;
  }

  Map<String, dynamic> _projectToDesktop(Project project) {
    final data = project.toJson();
    // colorValue int → color hex
    if (data.containsKey('colorValue')) {
      data['color'] = _colorValueToHex(data['colorValue'] as int);
      data.remove('colorValue');
    }
    // iconName → icon
    if (data.containsKey('iconName')) {
      data['icon'] = data['iconName'];
      data.remove('iconName');
    }
    return data;
  }

  // ── Conflict resolution (last-write-wins + message union) ────────

  Future<void> _mergeConversation(
    Conversation received,
    ChatService chatService,
  ) async {
    final local = chatService.getConversation(received.id);
    if (local == null) {
      await chatService.importConversation(received);
    } else if (received.updatedAt.isAfter(local.updatedAt)) {
      // Remote is newer: keep all local messages + add any new remote messages
      final localIds = local.messages.map((m) => m.id).toSet();
      final newMessages = received.messages
          .where((m) => !localIds.contains(m.id))
          .toList();
      final mergedMessages = List<Message>.from(local.messages)
        ..addAll(newMessages)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await chatService.updateConversation(
        received.copyWith(messages: mergedMessages),
      );
    }
    // else: local is newer or same — keep local unchanged
  }

  Future<void> _mergeProject(
    Project received,
    ProjectService projectService,
  ) async {
    final local = projectService.getProject(received.id);
    if (local == null) {
      await projectService.importProject(received);
    } else if (received.updatedAt.isAfter(local.updatedAt)) {
      await projectService.updateProject(received);
    }
    // else: keep local
  }

  // ── Color helpers ────────────────────────────────────────────────

  int _hexToColorValue(String hex) {
    final clean = hex.replaceFirst('#', '');
    return int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
  }

  String _colorValueToHex(int colorValue) {
    final rgb = colorValue & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  // ── Network helpers ──────────────────────────────────────────────

  Future<List<String>> _getLocalNetworkRange() async {
    final ranges = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          final parts = ip.split('.');
          if (parts.length == 4 && _isPrivateNetwork(ip)) {
            final base = parts.sublist(0, 3).join('.');
            if (!ranges.contains(base)) ranges.add(base);
          }
        }
      }
    } catch (_) {
      ranges.addAll(['192.168.1', '192.168.0', '10.0.0']);
    }
    return ranges;
  }

  bool _isPrivateNetwork(String ip) {
    final parts = ip.split('.').map(int.parse).toList();
    if (parts.length != 4) return false;
    if (parts[0] == 10) return true;
    if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return true;
    if (parts[0] == 192 && parts[1] == 168) return true;
    return false;
  }

  void dispose() => _client.close();
}
