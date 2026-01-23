import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:private_chat_hub/services/on_device_llm_service.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:private_chat_hub/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnDeviceLLMService service;
  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    storageService = StorageService();
    await storageService.init();
    service = OnDeviceLLMService(storageService);

    // Set up method channel mocking for path_provider
    const MethodChannel(
      'plugins.flutter.io/path_provider',
    ).setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '/tmp/test_docs';
      }
      return null;
    });

    // Set up method channel mocking for LiteRT
    const MethodChannel(
      'com.cmwen.private_chat_hub/litert',
    ).setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'isAvailable') {
        return true;
      } else if (methodCall.method == 'loadModel') {
        return {'success': true};
      } else if (methodCall.method == 'unloadModel') {
        return {'success': true};
      } else if (methodCall.method == 'generateText') {
        return 'Hello! This is a simulated response.';
      } else if (methodCall.method == 'getDeviceCapabilities') {
        return {'cpu': true, 'gpu': true, 'npu': false};
      } else if (methodCall.method == 'getMemoryInfo') {
        return {'totalMemory': 8589934592, 'freeMemory': 4294967296};
      }
      return null;
    });
  });

  tearDown(() {
    service.dispose();
  });

  group('OnDeviceLLMService - Basic Functionality', () {
    test('should create service instance', () {
      expect(service, isNotNull);
      expect(service, isA<LLMService>());
    });

    test('should provide model manager', () {
      expect(service.modelManager, isNotNull);
    });

    test('should have no model loaded initially', () {
      expect(service.currentModelId, isNull);
    });

    test('should check availability', () async {
      final available = await service.isAvailable();
      expect(available, isA<bool>());
    });
  });

  group('OnDeviceLLMService - Model Management', () {
    test('should get available models', () async {
      final models = await service.getAvailableModels();

      expect(models, isNotNull);
      expect(models, isA<List<ModelInfo>>());
      expect(models, isNotEmpty);

      // Check first model structure
      final firstModel = models.first;
      expect(firstModel.id, isNotEmpty);
      expect(firstModel.name, isNotEmpty);
      expect(firstModel.description, isNotEmpty);
      expect(firstModel.sizeBytes, greaterThan(0));
    });

    test('should report model not loaded initially', () {
      expect(service.isModelLoaded('gemma3-1b'), false);
    });
  });

  group('OnDeviceLLMService - Lifecycle', () {
    test('should dispose cleanly', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('should create new service instance after dispose', () {
      service.dispose();

      final newService = OnDeviceLLMService(storageService);
      expect(newService, isNotNull);
      expect(newService.currentModelId, isNull);

      newService.dispose();
    });
  });
}
