import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:private_chat_hub/services/inference_config_service.dart';
import 'package:private_chat_hub/services/llm_service.dart';

void main() {
  late SharedPreferences prefs;
  late InferenceConfigService service;

  setUp(() async {
    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = InferenceConfigService(prefs);
  });

  group('InferenceConfigService - Mode Management', () {
    test('should default to remote inference mode', () {
      expect(service.inferenceMode, InferenceMode.remote);
    });

    test('should set and persist inference mode', () async {
      await service.setInferenceMode(InferenceMode.onDevice);
      expect(service.inferenceMode, InferenceMode.onDevice);
      expect(prefs.getString('inference_mode'), 'onDevice');
    });

    test('should restore inference mode from SharedPreferences', () async {
      // Set mode using SharedPreferences directly
      await prefs.setString('inference_mode', 'onDevice');

      // Create new service instance - should load saved mode
      final newService = InferenceConfigService(prefs);
      expect(newService.inferenceMode, InferenceMode.onDevice);
    });

    test('should emit mode changes via stream', () async {
      expectLater(
        service.modeStream,
        emitsInOrder([InferenceMode.onDevice, InferenceMode.remote]),
      );

      await service.setInferenceMode(InferenceMode.onDevice);
      await service.setInferenceMode(InferenceMode.remote);
    });

    test('should handle invalid mode string gracefully', () {
      // Create service with invalid stored mode
      prefs.setString('inference_mode', 'invalid_mode');
      final newService = InferenceConfigService(prefs);

      // Should fallback to remote
      expect(newService.inferenceMode, InferenceMode.remote);
    });

    test('should provide mode description and label', () {
      expect(service.modeDescription, 'Remote (Ollama Server)');
      expect(service.modeLabel, 'Remote');
    });
  });

  group('InferenceConfigService - Backend Management', () {
    test('should default to GPU backend', () {
      expect(service.preferredBackend, 'gpu');
    });

    test('should set and persist backend preference', () async {
      await service.setPreferredBackend('cpu');
      expect(service.preferredBackend, 'cpu');
      expect(prefs.getString('litert_preferred_backend'), 'cpu');
    });

    test('should restore backend from SharedPreferences', () async {
      await prefs.setString('litert_preferred_backend', 'npu');

      final newService = InferenceConfigService(prefs);
      expect(newService.preferredBackend, 'npu');
    });

    test('should handle all valid backend types', () async {
      for (final backend in ['cpu', 'gpu', 'npu']) {
        await service.setPreferredBackend(backend);
        expect(service.preferredBackend, backend);
      }
    });

    test('should throw error for invalid backend', () {
      expect(() => service.setPreferredBackend('invalid'), throwsArgumentError);
    });
  });

  group('InferenceConfigService - Model Management', () {
    test('should have no last model by default for remote mode', () {
      expect(service.lastRemoteModel, isNull);
      expect(service.lastModel, isNull);
    });

    test('should set and persist last remote model', () async {
      await service.setLastRemoteModel('llama3');
      expect(service.lastRemoteModel, 'llama3');
      expect(prefs.getString('last_remote_model'), 'llama3');
    });

    test('should set and persist last on-device model', () async {
      await service.setLastOnDeviceModel('gemma3-1b');
      expect(service.lastOnDeviceModel, 'gemma3-1b');
      expect(prefs.getString('last_on_device_model'), 'gemma3-1b');
    });

    test('should use correct model for current mode', () async {
      // Set both models
      await service.setLastRemoteModel('llama3');
      await service.setLastOnDeviceModel('gemma3-1b');

      // Remote mode should return remote model
      await service.setInferenceMode(InferenceMode.remote);
      expect(service.lastModel, 'llama3');

      // On-device mode should return on-device model
      await service.setInferenceMode(InferenceMode.onDevice);
      expect(service.lastModel, 'gemma3-1b');
    });

    test('should restore models from SharedPreferences', () async {
      await prefs.setString('last_remote_model', 'llama3');
      await prefs.setString('last_on_device_model', 'phi-4-mini');

      final newService = InferenceConfigService(prefs);
      expect(newService.lastRemoteModel, 'llama3');
      expect(newService.lastOnDeviceModel, 'phi-4-mini');
    });
  });

  group('InferenceConfigService - Auto-Unload Settings', () {
    test('should enable auto-unload by default', () {
      expect(service.autoUnloadEnabled, true);
    });

    test('should set and persist auto-unload setting', () async {
      await service.setAutoUnload(false);
      expect(service.autoUnloadEnabled, false);
      expect(prefs.getBool('litert_auto_unload'), false);
    });

    test('should restore auto-unload from SharedPreferences', () async {
      await prefs.setBool('litert_auto_unload', false);

      final newService = InferenceConfigService(prefs);
      expect(newService.autoUnloadEnabled, false);
    });

    test('should default auto-unload timeout to 5 minutes', () {
      expect(service.autoUnloadTimeoutMinutes, 5);
    });

    test('should set and persist auto-unload timeout', () async {
      await service.setAutoUnloadTimeout(10);
      expect(service.autoUnloadTimeoutMinutes, 10);
      expect(prefs.getInt('litert_auto_unload_timeout'), 10);
    });

    test('should restore auto-unload timeout from SharedPreferences', () async {
      await prefs.setInt('litert_auto_unload_timeout', 15);

      final newService = InferenceConfigService(prefs);
      expect(newService.autoUnloadTimeoutMinutes, 15);
    });
  });

  group('InferenceConfigService - Persistence', () {
    test('should persist all settings across service instances', () async {
      // Set all settings
      await service.setInferenceMode(InferenceMode.onDevice);
      await service.setPreferredBackend('npu');
      await service.setLastRemoteModel('llama3');
      await service.setLastOnDeviceModel('gemma3-1b');
      await service.setAutoUnload(false);
      await service.setAutoUnloadTimeout(20);

      // Create new service instance
      final newService = InferenceConfigService(prefs);

      // Verify all settings are restored
      expect(newService.inferenceMode, InferenceMode.onDevice);
      expect(newService.preferredBackend, 'npu');
      expect(newService.lastRemoteModel, 'llama3');
      expect(newService.lastOnDeviceModel, 'gemma3-1b');
      expect(newService.autoUnloadEnabled, false);
      expect(newService.autoUnloadTimeoutMinutes, 20);
    });
  });

  group('InferenceConfigService - Edge Cases', () {
    test('should handle empty SharedPreferences gracefully', () {
      // Service with empty prefs should use defaults
      expect(service.inferenceMode, InferenceMode.remote);
      expect(service.preferredBackend, 'gpu');
      expect(service.lastModel, isNull);
      expect(service.autoUnloadEnabled, true);
      expect(service.autoUnloadTimeoutMinutes, 5);
    });

    test('should handle rapid mode changes', () async {
      // Rapid mode changes should all be processed
      await service.setInferenceMode(InferenceMode.onDevice);
      await service.setInferenceMode(InferenceMode.remote);
      await service.setInferenceMode(InferenceMode.onDevice);

      expect(service.inferenceMode, InferenceMode.onDevice);
    });

    test('should report on-device mode as available', () {
      expect(service.isOnDeviceModeAvailable, true);
    });

    test('should dispose cleanly', () {
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
