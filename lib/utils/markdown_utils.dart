/// Strips common markdown syntax for plain-text display (e.g. conversation titles).
String stripMarkdown(String text) {
  return text
      .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!) // **bold**
      .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!) // *italic*
      .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m[1]!) // __bold__
      .replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m[1]!) // _italic_
      .replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m[1]!) // `code`
      .replaceAllMapped(RegExp(r'~~(.+?)~~'), (m) => m[1]!) // ~~strikethrough~~
      .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '') // # headings
      .replaceAllMapped(
        RegExp(r'\[(.+?)\]\(.+?\)'),
        (m) => m[1]!,
      ) // [link](url)
      .trim();
}
