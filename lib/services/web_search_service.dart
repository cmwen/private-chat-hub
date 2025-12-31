import 'dart:convert';
import 'package:http/http.dart' as http;

/// Exception thrown when web search fails.
class WebSearchException implements Exception {
  final String message;

  const WebSearchException(this.message);

  @override
  String toString() => 'WebSearchException: $message';
}

/// Represents a search result.
class SearchResult {
  final String title;
  final String url;
  final String snippet;

  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'snippet': snippet,
    };
  }
}

/// Service for performing web searches.
/// 
/// This service uses DuckDuckGo's HTML search (no API key required).
/// For production use, consider using a proper search API like:
/// - Google Custom Search API
/// - Bing Search API
/// - SerpApi
class WebSearchService {
  final http.Client _client;

  WebSearchService({http.Client? client}) : _client = client ?? http.Client();

  /// Searches the web using DuckDuckGo Instant Answer API.
  /// 
  /// Returns a formatted string with search results.
  Future<String> search(String query) async {
    try {
      // Use DuckDuckGo Instant Answer API (free, no API key required)
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
          'https://api.duckduckgo.com/?q=$encodedQuery&format=json&no_html=1&skip_disambig=1');

      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _formatDuckDuckGoResults(data, query);
      } else {
        throw WebSearchException(
            'Search failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw WebSearchException('Error performing search: $e');
    }
  }

  /// Formats DuckDuckGo API results into a readable string.
  String _formatDuckDuckGoResults(Map<String, dynamic> data, String query) {
    final buffer = StringBuffer();
    buffer.writeln('Web Search Results for: "$query"');
    buffer.writeln();

    // Abstract (main answer)
    final abstractText = data['AbstractText'] as String?;
    final abstractSource = data['AbstractSource'] as String?;
    final abstractUrl = data['AbstractURL'] as String?;

    if (abstractText != null && abstractText.isNotEmpty) {
      buffer.writeln('Summary:');
      buffer.writeln(abstractText);
      if (abstractSource != null && abstractSource.isNotEmpty) {
        buffer.writeln('Source: $abstractSource');
      }
      if (abstractUrl != null && abstractUrl.isNotEmpty) {
        buffer.writeln('URL: $abstractUrl');
      }
      buffer.writeln();
    }

    // Related Topics
    final relatedTopics = data['RelatedTopics'] as List<dynamic>?;
    if (relatedTopics != null && relatedTopics.isNotEmpty) {
      buffer.writeln('Related Information:');
      
      int count = 0;
      for (final topic in relatedTopics) {
        if (count >= 5) break; // Limit to 5 results
        
        if (topic is Map<String, dynamic>) {
          final text = topic['Text'] as String?;
          final firstUrl = topic['FirstURL'] as String?;
          
          if (text != null && text.isNotEmpty) {
            count++;
            buffer.writeln('$count. $text');
            if (firstUrl != null && firstUrl.isNotEmpty) {
              buffer.writeln('   URL: $firstUrl');
            }
            buffer.writeln();
          }
        }
      }
    }

    // Definition (if available)
    final definition = data['Definition'] as String?;
    final definitionSource = data['DefinitionSource'] as String?;
    
    if (definition != null && definition.isNotEmpty) {
      buffer.writeln('Definition:');
      buffer.writeln(definition);
      if (definitionSource != null && definitionSource.isNotEmpty) {
        buffer.writeln('Source: $definitionSource');
      }
      buffer.writeln();
    }

    final result = buffer.toString().trim();
    
    // If no results found, return a helpful message
    if (result == 'Web Search Results for: "$query"') {
      return 'No specific results found for "$query". The information might be too specific or recent. Try rephrasing your query or breaking it into simpler terms.';
    }
    
    return result;
  }

  /// Searches using an alternative method (HTML parsing - more results but less reliable).
  /// This is a fallback option if the Instant Answer API doesn't return results.
  Future<List<SearchResult>> searchHtml(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('https://html.duckduckgo.com/html/?q=$encodedQuery');

      final response = await _client.get(
        url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseHtmlResults(response.body);
      } else {
        throw WebSearchException(
            'HTML search failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw WebSearchException('Error performing HTML search: $e');
    }
  }

  /// Parses HTML search results (basic parsing).
  List<SearchResult> _parseHtmlResults(String html) {
    final results = <SearchResult>[];
    
    // Basic HTML parsing - in a real app, use html package
    // This is a simple implementation for demonstration
    final resultPattern = RegExp(
      r'<a class="result__a" href="([^"]+)">([^<]+)</a>.*?<a class="result__snippet"[^>]*>([^<]+)</a>',
      multiLine: true,
      dotAll: true,
    );

    final matches = resultPattern.allMatches(html);
    
    for (final match in matches.take(5)) {
      final url = match.group(1) ?? '';
      final title = match.group(2) ?? '';
      final snippet = match.group(3) ?? '';
      
      if (url.isNotEmpty && title.isNotEmpty) {
        results.add(SearchResult(
          url: url,
          title: _decodeHtmlEntities(title),
          snippet: _decodeHtmlEntities(snippet),
        ));
      }
    }

    return results;
  }

  /// Decodes basic HTML entities.
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  void dispose() {
    _client.close();
  }
}
