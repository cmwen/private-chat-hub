import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Represents a discovered Ollama instance on the network.
class DiscoveredOllama {
  final String host;
  final int port;
  final String? name;
  final String? version;

  const DiscoveredOllama({
    required this.host,
    required this.port,
    this.name,
    this.version,
  });

  String get displayName => name ?? host;
  String get address => '$host:$port';
}

/// Service for discovering Ollama instances on the local network.
class NetworkDiscoveryService {
  final http.Client _client;
  static const int _ollamaPort = 11434;
  static const Duration _timeout = Duration(milliseconds: 1500);

  NetworkDiscoveryService({http.Client? client})
      : _client = client ?? http.Client();

  /// Scans the local network for Ollama instances.
  /// 
  /// Returns a stream of discovered instances as they are found.
  /// The scan will complete after checking common local IPs or after timeout.
  Stream<DiscoveredOllama> scanNetwork() async* {
    // Get local IP ranges to scan
    final localIps = await _getLocalNetworkRange();
    
    // Check localhost first
    final localhost = await _checkOllama('127.0.0.1', _ollamaPort);
    if (localhost != null) {
      yield localhost;
    }

    // Also check common Docker host address
    final dockerHost = await _checkOllama('host.docker.internal', _ollamaPort);
    if (dockerHost != null) {
      yield dockerHost;
    }

    // Scan local network in parallel (batches of 20 for performance)
    for (final baseIp in localIps) {
      final futures = <Future<DiscoveredOllama?>>[];
      
      for (int i = 1; i < 255; i++) {
        final ip = '$baseIp.$i';
        futures.add(_checkOllama(ip, _ollamaPort));
        
        // Process in batches
        if (futures.length >= 20) {
          final results = await Future.wait(futures);
          for (final result in results) {
            if (result != null) yield result;
          }
          futures.clear();
        }
      }
      
      // Process remaining
      if (futures.isNotEmpty) {
        final results = await Future.wait(futures);
        for (final result in results) {
          if (result != null) yield result;
        }
      }
    }
  }

  /// Checks a specific host for an Ollama instance.
  Future<DiscoveredOllama?> _checkOllama(String host, int port) async {
    try {
      final uri = Uri.parse('http://$host:$port/api/tags');
      final response = await _client.get(uri).timeout(_timeout);
      
      if (response.statusCode == 200) {
        // Try to get version info
        String? version;
        try {
          final versionUri = Uri.parse('http://$host:$port/api/version');
          final versionResponse = await _client.get(versionUri).timeout(_timeout);
          if (versionResponse.statusCode == 200) {
            version = versionResponse.body;
          }
        } catch (_) {
          // Version check is optional
        }

        return DiscoveredOllama(
          host: host,
          port: port,
          name: host == '127.0.0.1' ? 'Localhost' : null,
          version: version,
        );
      }
    } catch (_) {
      // Ignore errors - host doesn't have Ollama or is unreachable
    }
    return null;
  }

  /// Gets the local network base IPs to scan.
  Future<List<String>> _getLocalNetworkRange() async {
    final ranges = <String>[];
    
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final ip = address.address;
          // Extract base IP (e.g., "192.168.1" from "192.168.1.100")
          final parts = ip.split('.');
          if (parts.length == 4) {
            final baseIp = parts.sublist(0, 3).join('.');
            // Only scan private network ranges
            if (_isPrivateNetwork(ip)) {
              if (!ranges.contains(baseIp)) {
                ranges.add(baseIp);
              }
            }
          }
        }
      }
    } catch (_) {
      // Fallback to common private network ranges
      ranges.addAll(['192.168.1', '192.168.0', '10.0.0']);
    }
    
    return ranges;
  }

  /// Checks if an IP is in a private network range.
  bool _isPrivateNetwork(String ip) {
    final parts = ip.split('.').map(int.parse).toList();
    if (parts.length != 4) return false;
    
    // 10.0.0.0 - 10.255.255.255
    if (parts[0] == 10) return true;
    
    // 172.16.0.0 - 172.31.255.255
    if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return true;
    
    // 192.168.0.0 - 192.168.255.255
    if (parts[0] == 192 && parts[1] == 168) return true;
    
    return false;
  }

  /// Checks a single host for Ollama (for manual testing).
  Future<bool> testConnection(String host, int port) async {
    final result = await _checkOllama(host, port);
    return result != null;
  }

  void dispose() {
    _client.close();
  }
}
