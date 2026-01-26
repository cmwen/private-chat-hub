import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:private_chat_hub/core/errors/exceptions.dart';
import 'package:private_chat_hub/core/utils/logger.dart';
import 'package:private_chat_hub/domain/entities/ollama_model.dart';

class OllamaApiClient {
  final Dio _dio;
  final String baseUrl;
  CancelToken? _currentCancelToken;

  OllamaApiClient({required this.baseUrl, Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<List<OllamaModel>> getTags() async {
    try {
      final response = await _dio.get('/api/tags');

      if (response.statusCode != 200) {
        throw OllamaAPIException(
          'Failed to fetch models: ${response.statusCode}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final models = (data['models'] as List<dynamic>?) ?? [];

      return models
          .map((model) => OllamaModel.fromJson(model as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'getTags');
      }
      rethrow;
    }
  }

  Stream<String> streamChat({
    required String model,
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    List<String>? images,
    CancelToken? cancelToken,
  }) async* {
    _currentCancelToken = cancelToken ?? CancelToken();

    try {
      final requestData = {
        'model': model,
        'messages': messages,
        'stream': true,
        if (systemPrompt != null) 'system': systemPrompt,
        if (images != null && images.isNotEmpty) 'images': images,
      };

      final response = await _dio.post<ResponseBody>(
        '/api/chat',
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Content-Type': 'application/json'},
        ),
        cancelToken: _currentCancelToken,
      );

      if (response.statusCode != 200) {
        throw OllamaAPIException('Chat request failed: ${response.statusCode}');
      }

      await for (final chunk in _parseServerSentEvents(response.data!.stream)) {
        yield chunk;
      }
    } catch (e) {
      if (e is DioException) {
        if (CancelToken.isCancel(e)) {
          AppLogger.debug('Chat request cancelled');
          return;
        }
        throw _handleDioError(e, 'streamChat');
      }
      rethrow;
    } finally {
      _currentCancelToken = null;
    }
  }

  Stream<PullProgress> pullModel(String modelName) async* {
    try {
      final requestData = {'name': modelName, 'stream': true};

      final response = await _dio.post<ResponseBody>(
        '/api/pull',
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(hours: 1),
        ),
      );

      if (response.statusCode != 200) {
        throw OllamaAPIException('Model pull failed: ${response.statusCode}');
      }

      await for (final line in _streamLines(response.data!.stream)) {
        if (line.trim().isEmpty) continue;

        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          yield PullProgress.fromJson(json);
        } catch (e) {
          AppLogger.error('Failed to parse pull progress', e);
        }
      }
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'pullModel');
      }
      rethrow;
    }
  }

  Future<ModelDetails?> showModel(String modelName) async {
    try {
      final response = await _dio.post('/api/show', data: {'name': modelName});

      if (response.statusCode != 200) {
        throw OllamaAPIException(
          'Failed to get model details: ${response.statusCode}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final details = data['details'] as Map<String, dynamic>?;

      if (details == null) return null;
      return ModelDetails.fromJson(details);
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'showModel');
      }
      rethrow;
    }
  }

  Future<void> deleteModel(String modelName) async {
    try {
      final response = await _dio.delete(
        '/api/delete',
        data: {'name': modelName},
      );

      if (response.statusCode != 200) {
        throw OllamaAPIException(
          'Failed to delete model: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'deleteModel');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVersion() async {
    try {
      final response = await _dio.get('/api/version');

      if (response.statusCode != 200) {
        throw OllamaAPIException(
          'Failed to get version: ${response.statusCode}',
        );
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'getVersion');
      }
      rethrow;
    }
  }

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/api/version');
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.debug('Ollama health check failed');
      return false;
    }
  }

  void cancelCurrentRequest() {
    _currentCancelToken?.cancel('Request cancelled by user');
  }

  Stream<String> _streamLines(Stream<Uint8List> stream) async* {
    final reader = utf8.decoder.bind(stream);
    final splitter = const LineSplitter();

    await for (final chunk in reader) {
      final lines = splitter.convert(chunk);
      for (final line in lines) {
        yield line;
      }
    }
  }

  Stream<String> _parseServerSentEvents(Stream<Uint8List> stream) async* {
    await for (final line in _streamLines(stream)) {
      if (line.trim().isEmpty) continue;

      try {
        final json = jsonDecode(line) as Map<String, dynamic>;

        if (json['done'] == true) {
          AppLogger.debug('Chat stream completed');
          return;
        }

        final message = json['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          yield content;
        }
      } catch (e) {
        AppLogger.error('Failed to parse SSE chunk', e);
      }
    }
  }

  AppException _handleDioError(DioException error, String operation) {
    AppLogger.error('Ollama API error in $operation', error);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Connection timeout. Check Ollama server is running.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message =
            error.response?.data?.toString() ?? 'Server error: $statusCode';
        return OllamaAPIException(message, statusCode: statusCode);

      case DioExceptionType.connectionError:
        return NetworkException('Cannot connect to Ollama server at $baseUrl');

      case DioExceptionType.cancel:
        return OllamaAPIException('Request cancelled');

      case DioExceptionType.badCertificate:
        return NetworkException('SSL certificate error');

      case DioExceptionType.unknown:
        return NetworkException('Network error: ${error.message}');

      default:
        return OllamaAPIException('Unexpected error: ${error.message}');
    }
  }

  void dispose() {
    _currentCancelToken?.cancel();
    _dio.close();
  }
}
