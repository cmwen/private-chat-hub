import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:private_chat_hub/models/tool_models.dart';

/// Exception thrown when Jina API request fails.
class JinaException implements Exception {
  final String message;
  final int? statusCode;

  const JinaException(this.message, {this.statusCode});

  @override
  String toString() =>
      'JinaException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';

  /// Whether this is a rate limit error.
  bool get isRateLimited => statusCode == 429;

  /// Whether this is an authentication error.
  bool get isAuthError => statusCode == 401;

  /// Whether this is a network error.
  bool get isNetworkError => statusCode == null || statusCode == -1;
}

/// Service for interacting with Jina AI APIs for web search.
///
/// Jina provides:
/// - `/search` endpoint for web search
/// - `r.jina.ai` for fetching and parsing URLs
/// - `/qa` endpoint for Q&A over context
class JinaSearchService {
  static const String _baseUrl = 'https://api.jina.ai';
  static const String _readerUrl = 'https://r.jina.ai';

  final String apiKey;
  final http.Client _httpClient;

  // Rate limiting tracking (100 requests/minute)
  final List<DateTime> _requestTimestamps = [];
  static const int _rateLimitPerMinute = 100;

  // In-memory cache for search results (for session)
  final Map<String, SearchResults> _searchCache = {};

  JinaSearchService({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Performs a web search using Jina API.
  ///
  /// Parameters:
  /// - [query]: Search query string
  /// - [limit]: Number of results (1-50, default 5)
  /// - [lang]: Language code (default "en")
  /// - [fresh]: Freshness filter ("d" day, "w" week, "m" month, or null)
  ///
  /// Returns [SearchResults] with title, URL, snippet for each result.
  ///
  /// Throws [JinaException] on API errors.
  Future<SearchResults> search(
    String query, {
    int limit = 5,
    String lang = 'en',
    String? fresh,
  }) async {
    // Validate inputs
    if (query.trim().isEmpty) {
      throw const JinaException('Search query cannot be empty');
    }
    if (limit < 1 || limit > 50) {
      throw const JinaException('Limit must be between 1 and 50');
    }

    // Check cache first
    final cacheKey = _getCacheKey(query, lang, fresh);
    final cached = _searchCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached;
    }

    // Check rate limiting
    await _checkRateLimit();

    // Build request URL
    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': query,
        'limit': limit.toString(),
        'lang': lang,
        if (fresh != null) 'fresh': fresh,
      },
    );

    try {
      // Make request with timeout
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'User-Agent': 'PrivateChatHub/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      // Track request for rate limiting
      _requestTimestamps.add(DateTime.now());

      // Handle status codes
      if (response.statusCode == 401) {
        throw const JinaException('Invalid API key', statusCode: 401);
      }
      if (response.statusCode == 429) {
        throw const JinaException('Rate limit exceeded. Please wait.', statusCode: 429);
      }
      if (response.statusCode != 200) {
        throw JinaException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }

      // Parse response
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = SearchResults.fromJson({
        'query': query,
        'data': json['data'],
        'searchTime': json['searchTime'],
        'cachedAt': DateTime.now().toIso8601String(),
      });

      // Cache results
      _searchCache[cacheKey] = results;

      return results;
    } on TimeoutException {
      throw const JinaException('Request timeout after 30 seconds', statusCode: -1);
    } on JinaException {
      rethrow;
    } catch (e) {
      throw JinaException('Network error: $e');
    }
  }

  /// Fetches and parses content from a URL using Jina Reader.
  ///
  /// Returns the content as Markdown-formatted text.
  /// This endpoint is free and doesn't require authentication.
  Future<String> fetchContent(String url) async {
    if (url.trim().isEmpty) {
      throw const JinaException('URL cannot be empty');
    }

    // Validate URL
    try {
      Uri.parse(url);
    } catch (e) {
      throw JinaException('Invalid URL: $e');
    }

    await _checkRateLimit();

    try {
      final readerUri = Uri.parse('$_readerUrl/$url');
      final response = await _httpClient.get(
        readerUri,
        headers: {
          'User-Agent': 'PrivateChatHub/1.0',
          'Accept': 'text/plain',
        },
      ).timeout(const Duration(seconds: 60));

      _requestTimestamps.add(DateTime.now());

      if (response.statusCode != 200) {
        throw JinaException(
          'Failed to fetch URL: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      return response.body;
    } on TimeoutException {
      throw const JinaException('Request timeout after 60 seconds', statusCode: -1);
    } on JinaException {
      rethrow;
    } catch (e) {
      throw JinaException('Error fetching content: $e');
    }
  }

  /// Answers a question using provided context via Jina Q&A endpoint.
  ///
  /// Parameters:
  /// - [question]: The question to answer
  /// - [context]: The context to use for answering
  ///
  /// Returns the answer text.
  Future<String> answerQuestion(String question, String context) async {
    if (question.trim().isEmpty) {
      throw const JinaException('Question cannot be empty');
    }
    if (context.trim().isEmpty) {
      throw const JinaException('Context cannot be empty');
    }

    await _checkRateLimit();

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/qa'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'User-Agent': 'PrivateChatHub/1.0',
        },
        body: jsonEncode({
          'question': question,
          'context': context,
        }),
      ).timeout(const Duration(seconds: 30));

      _requestTimestamps.add(DateTime.now());

      if (response.statusCode == 401) {
        throw const JinaException('Invalid API key', statusCode: 401);
      }
      if (response.statusCode == 429) {
        throw const JinaException('Rate limit exceeded', statusCode: 429);
      }
      if (response.statusCode != 200) {
        throw JinaException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['answer'] as String? ?? '';
    } on TimeoutException {
      throw const JinaException('Request timeout', statusCode: -1);
    } on JinaException {
      rethrow;
    } catch (e) {
      throw JinaException('Error answering question: $e');
    }
  }

  /// Generates a cache key for search results.
  String _getCacheKey(String query, String lang, String? fresh) {
    return '${query.toLowerCase()}_${lang}_${fresh ?? 'all'}';
  }

  /// Checks if we're within rate limits, waits if necessary.
  Future<void> _checkRateLimit() async {
    // Clean up old timestamps (older than 1 minute)
    final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
    _requestTimestamps.removeWhere((ts) => ts.isBefore(oneMinuteAgo));

    // If at limit, wait
    if (_requestTimestamps.length >= _rateLimitPerMinute) {
      final oldestInWindow = _requestTimestamps.first;
      final waitTime = oldestInWindow.add(const Duration(minutes: 1)).difference(DateTime.now());
      if (waitTime.isNegative == false) {
        await Future<void>.delayed(waitTime);
        // Clean up again after waiting
        _requestTimestamps.removeWhere(
          (ts) => ts.isBefore(DateTime.now().subtract(const Duration(minutes: 1))),
        );
      }
    }
  }

  /// Gets current rate limit status.
  Map<String, dynamic> getRateLimitStatus() {
    final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
    final recentRequests = _requestTimestamps.where((ts) => ts.isAfter(oneMinuteAgo)).length;
    return {
      'requestsInLastMinute': recentRequests,
      'limit': _rateLimitPerMinute,
      'remaining': _rateLimitPerMinute - recentRequests,
    };
  }

  /// Clears the search cache.
  void clearCache() {
    _searchCache.clear();
  }

  /// Disposes of the HTTP client.
  void dispose() {
    _httpClient.close();
    _searchCache.clear();
    _requestTimestamps.clear();
  }
}
