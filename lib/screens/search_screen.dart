import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:intl/intl.dart';

/// Search result containing a message and its conversation.
class SearchResult {
  final Conversation conversation;
  final Message message;
  final String highlightedText;

  const SearchResult({
    required this.conversation,
    required this.message,
    required this.highlightedText,
  });
}

/// Screen for searching across all conversations.
class SearchScreen extends StatefulWidget {
  final ChatService chatService;
  final Function(Conversation conversation, String? messageId) onResultSelected;

  const SearchScreen({
    super.key,
    required this.chatService,
    required this.onResultSelected,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchResult> _results = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = '';
      });
      return;
    }

    if (query == _lastQuery) return;

    setState(() {
      _isSearching = true;
      _lastQuery = query;
    });

    // Search in all conversations
    final conversations = widget.chatService.getConversations();
    final results = <SearchResult>[];
    final queryLower = query.toLowerCase();

    for (final conversation in conversations) {
      for (final message in conversation.messages) {
        final textLower = message.text.toLowerCase();
        if (textLower.contains(queryLower)) {
          results.add(
            SearchResult(
              conversation: conversation,
              message: message,
              highlightedText: _getHighlightedSnippet(message.text, query),
            ),
          );
        }
      }
    }

    // Sort by most recent first
    results.sort((a, b) => b.message.timestamp.compareTo(a.message.timestamp));

    setState(() {
      _results = results.take(100).toList(); // Limit to 100 results
      _isSearching = false;
    });
  }

  String _getHighlightedSnippet(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return text.length > 100 ? '${text.substring(0, 100)}...' : text;
    }

    // Get context around the match
    final start = (index - 30).clamp(0, text.length);
    final end = (index + query.length + 50).clamp(0, text.length);

    var snippet = text.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';

    return snippet;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            // Debounce search
            Future.delayed(const Duration(milliseconds: 300), () {
              if (value == _searchController.text) {
                _performSearch(value);
              }
            });
          },
          onSubmitted: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lastQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search your conversations',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Find messages across all chats',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results for "$_lastQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Group results by conversation
    final groupedResults = <String, List<SearchResult>>{};
    for (final result in _results) {
      groupedResults.putIfAbsent(result.conversation.id, () => []).add(result);
    }

    return ListView.builder(
      itemCount: groupedResults.length,
      itemBuilder: (context, index) {
        final conversationId = groupedResults.keys.elementAt(index);
        final results = groupedResults[conversationId]!;
        final conversation = results.first.conversation;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conversation.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Text(
                    '${results.length} match${results.length > 1 ? 'es' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            ...results.map(
              (result) => _SearchResultTile(
                result: result,
                query: _lastQuery,
                onTap: () {
                  widget.onResultSelected(
                    result.conversation,
                    result.message.id,
                  );
                },
              ),
            ),
            const Divider(),
          ],
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final String query;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: result.message.isMe
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[300],
        child: Icon(
          result.message.isMe ? Icons.person : Icons.psychology,
          color: result.message.isMe ? Colors.white : Colors.grey[700],
          size: 20,
        ),
      ),
      title: _buildHighlightedText(context, result.highlightedText, query),
      subtitle: Text(
        DateFormat('MMM d, y • HH:mm').format(result.message.timestamp),
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      onTap: onTap,
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
  ) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];

    var start = 0;
    var index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
