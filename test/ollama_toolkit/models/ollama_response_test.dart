import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_response.dart';

void main() {
  group('OllamaGenerateResponse', () {
    test('deserializes from JSON', () {
      final json = {
        'model': 'llama3.2',
        'response': 'Hello there!',
        'done': true,
        'eval_count': 50,
        'eval_duration': 1000000000, // 1 second in nanoseconds
      };

      final response = OllamaGenerateResponse.fromJson(json);

      expect(response.model, 'llama3.2');
      expect(response.response, 'Hello there!');
      expect(response.done, true);
      expect(response.evalCount, 50);
      expect(response.evalDuration, 1000000000);
    });

    test('calculates eval time from duration', () {
      final json = {
        'model': 'llama3.2',
        'response': 'Hi',
        'done': true,
        'eval_duration': 2000000000, // 2 seconds
      };

      final response = OllamaGenerateResponse.fromJson(json);
      final evalTime = response.evalTime;

      expect(evalTime, isNotNull);
      expect(evalTime!.inMilliseconds, 2000);
    });

    test('handles missing optional fields', () {
      final json = {'model': 'llama3.2', 'response': 'Test', 'done': false};

      final response = OllamaGenerateResponse.fromJson(json);

      expect(response.evalCount, isNull);
      expect(response.evalDuration, isNull);
      expect(response.context, isNull);
    });

    test('deserializes with thinking field', () {
      final json = {
        'model': 'deepseek-r1',
        'response': 'The answer is 42',
        'done': true,
        'thinking': 'First I analyzed the question...',
      };

      final response = OllamaGenerateResponse.fromJson(json);

      expect(response.thinking, 'First I analyzed the question...');
      expect(response.response, 'The answer is 42');
    });
  });

  group('OllamaChatResponse', () {
    test('deserializes from JSON', () {
      final json = {
        'model': 'llama3.2',
        'message': {'role': 'assistant', 'content': 'How can I help?'},
        'done': true,
        'eval_count': 25,
      };

      final response = OllamaChatResponse.fromJson(json);

      expect(response.model, 'llama3.2');
      expect(response.message.role, 'assistant');
      expect(response.message.content, 'How can I help?');
      expect(response.done, true);
      expect(response.evalCount, 25);
    });

    test('deserializes message with tool calls', () {
      final json = {
        'model': 'llama3.2',
        'message': {
          'role': 'assistant',
          'content': 'Calling tool',
          'tool_calls': [
            {
              'id': '1',
              'name': 'calculator',
              'arguments': {'expression': '2+2'},
            },
          ],
        },
        'done': false,
      };

      final response = OllamaChatResponse.fromJson(json);

      expect(response.message.toolCalls, hasLength(1));
      expect(response.message.toolCalls![0].name, 'calculator');
    });

    test('deserializes message with thinking', () {
      final json = {
        'model': 'qwen3',
        'message': {
          'role': 'assistant',
          'content': 'The answer is 4',
          'thinking': 'Let me calculate 2+2...',
        },
        'done': true,
      };

      final response = OllamaChatResponse.fromJson(json);

      expect(response.message.thinking, 'Let me calculate 2+2...');
      expect(response.message.content, 'The answer is 4');
    });
  });

  group('OllamaEmbeddingResponse', () {
    test('deserializes from JSON', () {
      final json = {
        'embedding': [0.1, 0.2, 0.3, 0.4, 0.5],
      };

      final response = OllamaEmbeddingResponse.fromJson(json);

      expect(response.embedding, hasLength(5));
      expect(response.embedding[0], 0.1);
      expect(response.embedding[4], 0.5);
    });

    test('toString shows dimensions', () {
      final response = OllamaEmbeddingResponse(
        embedding: List.filled(1536, 0.0),
      );

      expect(response.toString(), contains('1536'));
    });
  });

  group('OllamaModelInfo', () {
    test('deserializes from JSON', () {
      final json = {
        'name': 'llama3.2:8b',
        'modified_at': '2024-01-01T00:00:00Z',
        'size': 4661224448, // ~4.3GB
        'digest': 'abc123',
      };

      final info = OllamaModelInfo.fromJson(json);

      expect(info.name, 'llama3.2:8b');
      expect(info.size, 4661224448);
      expect(info.digest, 'abc123');
    });

    test('formats size correctly', () {
      final info = OllamaModelInfo(
        name: 'test',
        modifiedAt: DateTime.now(),
        size: 4661224448, // 4.3GB
        digest: 'abc',
      );

      expect(info.sizeFormatted, contains('GB'));
    });

    test('formats different sizes', () {
      final bytes = OllamaModelInfo(
        name: 'test',
        modifiedAt: DateTime.now(),
        size: 500,
        digest: 'abc',
      );
      expect(bytes.sizeFormatted, contains('B'));

      final kb = OllamaModelInfo(
        name: 'test',
        modifiedAt: DateTime.now(),
        size: 5000,
        digest: 'abc',
      );
      expect(kb.sizeFormatted, contains('KB'));

      final mb = OllamaModelInfo(
        name: 'test',
        modifiedAt: DateTime.now(),
        size: 5000000,
        digest: 'abc',
      );
      expect(mb.sizeFormatted, contains('MB'));
    });
  });

  group('OllamaModelsResponse', () {
    test('deserializes from JSON', () {
      final json = {
        'models': [
          {
            'name': 'llama3.2',
            'modified_at': '2024-01-01T00:00:00Z',
            'size': 1000000,
            'digest': 'abc',
          },
          {
            'name': 'qwen2.5',
            'modified_at': '2024-01-02T00:00:00Z',
            'size': 2000000,
            'digest': 'def',
          },
        ],
      };

      final response = OllamaModelsResponse.fromJson(json);

      expect(response.models, hasLength(2));
      expect(response.models[0].name, 'llama3.2');
      expect(response.models[1].name, 'qwen2.5');
    });
  });
}
