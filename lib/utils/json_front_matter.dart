import 'dart:convert';

/// A Markdown document with a JSON front matter block.
class MarkdownFrontMatterDocument {
  final Map<String, dynamic> metadata;
  final String body;

  const MarkdownFrontMatterDocument({
    required this.metadata,
    required this.body,
  });
}

/// Encodes a JSON front matter document.
String encodeJsonFrontMatter({
  required Map<String, dynamic> metadata,
  String body = '',
}) {
  final normalizedBody = body.trimRight();
  final encodedMetadata = const JsonEncoder.withIndent('  ').convert(metadata);
  if (normalizedBody.isEmpty) {
    return '---\n$encodedMetadata\n---\n';
  }
  return '---\n$encodedMetadata\n---\n$normalizedBody\n';
}

/// Decodes a JSON front matter document.
MarkdownFrontMatterDocument decodeJsonFrontMatter(String source) {
  final normalized = source.replaceAll('\r\n', '\n');
  const separator = '\n---\n';

  if (!normalized.startsWith('---\n')) {
    throw const FormatException('Missing opening front matter marker.');
  }

  final closingIndex = normalized.indexOf(separator, 4);
  if (closingIndex == -1) {
    throw const FormatException('Missing closing front matter marker.');
  }

  final metadataSource = normalized.substring(4, closingIndex);
  final body = normalized.substring(closingIndex + separator.length);
  final decoded = jsonDecode(metadataSource);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Front matter must decode to an object.');
  }

  return MarkdownFrontMatterDocument(metadata: decoded, body: body.trimRight());
}
