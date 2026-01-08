import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/ollama_toolkit/services/ollama_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OllamaConfigService configService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    configService = OllamaConfigService();
  });

  group('OllamaConfigService - Streaming', () {
    test('should return true for streaming enabled by default', () async {
      final enabled = await configService.getStreamEnabled();
      expect(enabled, isTrue);
    });

    test('should set streaming enabled to false', () async {
      await configService.setStreamEnabled(false);
      final enabled = await configService.getStreamEnabled();
      expect(enabled, isFalse);
    });

    test('should set streaming enabled to true', () async {
      await configService.setStreamEnabled(true);
      final enabled = await configService.getStreamEnabled();
      expect(enabled, isTrue);
    });

    test('should persist streaming preference', () async {
      // Set to false
      await configService.setStreamEnabled(false);
      
      // Create new instance (simulating app restart)
      final newConfigService = OllamaConfigService();
      final enabled = await newConfigService.getStreamEnabled();
      
      expect(enabled, isFalse);
    });

    test('should toggle streaming preference multiple times', () async {
      // Initial state
      var enabled = await configService.getStreamEnabled();
      expect(enabled, isTrue);

      // Toggle to false
      await configService.setStreamEnabled(false);
      enabled = await configService.getStreamEnabled();
      expect(enabled, isFalse);

      // Toggle back to true
      await configService.setStreamEnabled(true);
      enabled = await configService.getStreamEnabled();
      expect(enabled, isTrue);

      // Toggle to false again
      await configService.setStreamEnabled(false);
      enabled = await configService.getStreamEnabled();
      expect(enabled, isFalse);
    });
  });

  group('OllamaConfigService - Other Config', () {
    test('should get default base URL', () async {
      final baseUrl = await configService.getBaseUrl();
      expect(baseUrl, 'http://localhost:11434');
    });

    test('should set and get base URL', () async {
      await configService.setBaseUrl('http://192.168.1.100:11434');
      final baseUrl = await configService.getBaseUrl();
      expect(baseUrl, 'http://192.168.1.100:11434');
    });

    test('should get default timeout', () async {
      final timeout = await configService.getTimeout();
      expect(timeout, 60);
    });

    test('should set and get timeout', () async {
      await configService.setTimeout(120);
      final timeout = await configService.getTimeout();
      expect(timeout, 120);
    });

    test('should get all config', () async {
      await configService.setBaseUrl('http://test:11434');
      await configService.setTimeout(90);
      await configService.setStreamEnabled(false);

      final config = await configService.getAll();

      expect(config['baseUrl'], 'http://test:11434');
      expect(config['timeout'], 90);
      expect(config['streamEnabled'], isFalse);
    });

    test('should clear all configuration', () async {
      await configService.setBaseUrl('http://test:11434');
      await configService.setTimeout(90);
      await configService.setStreamEnabled(false);

      await configService.clearAll();

      final baseUrl = await configService.getBaseUrl();
      final timeout = await configService.getTimeout();
      final streamEnabled = await configService.getStreamEnabled();

      expect(baseUrl, 'http://localhost:11434'); // Default
      expect(timeout, 60); // Default
      expect(streamEnabled, isTrue); // Default
    });
  });
}
