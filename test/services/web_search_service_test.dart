import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/web_search_service.dart';

void main() {
  group('WebSearchService', () {
    late WebSearchService webSearchService;

    setUp(() {
      webSearchService = WebSearchService();
    });

    tearDown(() {
      webSearchService.dispose();
    });

    test('SearchResult should create from JSON correctly', () {
      final json = {
        'title': 'Test Title',
        'url': 'https://test.com',
        'snippet': 'Test snippet',
      };

      final result = SearchResult.fromJson(json);

      expect(result.title, 'Test Title');
      expect(result.url, 'https://test.com');
      expect(result.snippet, 'Test snippet');
    });

    test('SearchResult should handle missing fields', () {
      final json = <String, dynamic>{};

      final result = SearchResult.fromJson(json);

      expect(result.title, '');
      expect(result.url, '');
      expect(result.snippet, '');
    });

    test('SearchResult should serialize to JSON', () {
      const result = SearchResult(
        title: 'Test',
        url: 'https://test.com',
        snippet: 'Snippet',
      );

      final json = result.toJson();

      expect(json['title'], 'Test');
      expect(json['url'], 'https://test.com');
      expect(json['snippet'], 'Snippet');
    });
  });

  group('WebSearchException', () {
    test('should create exception with message', () {
      const exception = WebSearchException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.toString(), contains('Test error'));
    });
  });
}
