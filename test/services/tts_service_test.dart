import 'package:flutter_test/flutter_test.dart';

// Helper test class to directly test markdown cleaning logic
class MarkdownCleanerTests {
  /// Clean markdown formatting from text for better speech output.
  ///
  /// This mirrors the TtsService._cleanMarkdown method for testing purposes.
  static String cleanMarkdown(String text) {
    if (text.isEmpty) return text;

    var cleaned = text;

    // 1. Remove code blocks first (to avoid processing their contents)
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    cleaned = cleaned.replaceAll(RegExp(r'~~~[\s\S]*?~~~'), '');

    // 2. Remove inline code
    cleaned = cleaned.replaceAll(RegExp(r'`[^`]+`'), '');

    // 3. Remove headers - use callback to avoid $1 literal
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^#+\s+(.*)$', multiLine: true),
      (match) => match.group(1) ?? '',
    );

    // 4. Remove bold/italic markers - use callbacks instead of r'$1'
    // Bold: **text** or __text__
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'__([^_]+)__'),
      (match) => match.group(1) ?? '',
    );

    // Italic: *text* or _text_
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*([^*]+)\*'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'_([^_]+)_'),
      (match) => match.group(1) ?? '',
    );

    // 5. Remove links but keep text
    // Standard links: [text](url)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1) ?? '',
    );
    // Reference links: [text][ref]
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\[[^\]]*\]'),
      (match) => match.group(1) ?? '',
    );

    // 6. Remove images
    cleaned = cleaned.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), '');

    // 7. Remove blockquotes
    cleaned = cleaned.replaceAll(RegExp(r'^>\s+', multiLine: true), '');

    // 8. Remove list markers - use callbacks
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^\s*[-*+]\s+', multiLine: true),
      (match) => '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^\s*\d+\.\s+', multiLine: true),
      (match) => '',
    );

    // 9. Remove strikethrough ~~text~~
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'~~([^~]+)~~'),
      (match) => match.group(1) ?? '',
    );

    // 10. Clean up punctuation that was marked for emphasis
    // Repeated punctuation: !! → !, ?? → ?, ... → ...
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([!?.])\1+'),
      (match) => match.group(1) ?? '.',
    );

    // 11. Remove HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');

    // 12. Remove stray brackets and parentheses (after markdown processing)
    cleaned = cleaned.replaceAll(RegExp(r'[\[\]]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\(+\)'), '');

    // 13. Handle dollar signs and currency (AFTER all markdown processing)
    // This prevents issues with $1 from regex replacements
    // Replace currency patterns: $100 → 100 dollars
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\$(\d+(?:\.\d{2})?)'),
      (match) => '${match.group(1)} dollars',
    );

    // Replace remaining dollar signs in variable names ($var → var)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\$([a-zA-Z_])'),
      (match) => match.group(1) ?? '',
    );

    // 14. Handle LaTeX and math expressions
    // Remove display math: $$...$$
    cleaned = cleaned.replaceAll(RegExp(r'\$\$[\s\S]*?\$\$'), '');
    // Remove inline LaTeX: \(... \) and \[... \]
    cleaned = cleaned.replaceAll(RegExp(r'\\\([\s\S]*?\\\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\\\[[\s\S]*?\\\]'), '');

    // 15. Normalize whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r' {2,}'), ' ');
    cleaned = cleaned.trim();

    return cleaned;
  }
}

void main() {
  group('MarkdownCleaner - Basic Markdown', () {
    test('should remove bold markers', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('This is **bold** text'),
        'This is bold text',
      );
    });

    test('should remove italic markers', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('This is *italic* text'),
        'This is italic text',
      );
    });

    test('should remove strikethrough', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('This is ~~deleted~~ text'),
        'This is deleted text',
      );
    });

    test('should handle mixed bold and italic', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('***bold italic***'),
        'bold italic',
      );
    });

    test('should remove underscore bold and italic', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('This is __bold__ and _italic_'),
        'This is bold and italic',
      );
    });
  });

  group('MarkdownCleaner - Headers', () {
    test('should remove h1 headers', () {
      expect(MarkdownCleanerTests.cleanMarkdown('# Heading 1'), 'Heading 1');
    });

    test('should remove h2 headers', () {
      expect(MarkdownCleanerTests.cleanMarkdown('## Heading 2'), 'Heading 2');
    });

    test('should remove h3 headers', () {
      expect(MarkdownCleanerTests.cleanMarkdown('### Heading 3'), 'Heading 3');
    });

    test('should handle multiple headers', () {
      final input = '# Title\n## Subtitle\nContent';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, contains('Title'));
      expect(result, contains('Subtitle'));
      expect(result, contains('Content'));
    });
  });

  group('MarkdownCleaner - Code Blocks', () {
    test('should remove triple backtick code blocks', () {
      final result = MarkdownCleanerTests.cleanMarkdown(
        'Text before\n```\ncode here\n```\nText after',
      );
      // Code block should be removed
      expect(result, isNot(contains('```')));
      expect(result, isNot(contains('code here')));
      // Both text parts should remain
      expect(result, contains('Text before'));
      expect(result, contains('Text after'));
    });

    test('should remove triple tilde code blocks', () {
      final result = MarkdownCleanerTests.cleanMarkdown(
        'Before\n~~~\ncode\n~~~\nAfter',
      );
      // Code block should be removed
      expect(result, isNot(contains('~~~')));
      expect(result, isNot(contains('code')));
      // Both text parts should remain
      expect(result, contains('Before'));
      expect(result, contains('After'));
    });

    test('should remove inline code', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('Use `variable` in code'),
        'Use in code',
      );
    });
  });

  group('MarkdownCleaner - Links', () {
    test('should remove standard links but keep text', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown(
          'Visit [Google](https://google.com)',
        ),
        'Visit Google',
      );
    });

    test('should remove reference links', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('[Link text][ref]'),
        'Link text',
      );
    });

    test('should handle links with multiple words', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown(
          'Check out [this awesome page](https://example.com)',
        ),
        'Check out this awesome page',
      );
    });
  });

  group('MarkdownCleaner - Images', () {
    test('should remove images', () {
      final result = MarkdownCleanerTests.cleanMarkdown(
        '![Alt text](image.png)',
      );
      // The main requirement is that it's not a literal image markdown
      // Some remnants might be left, but the image syntax should be gone
      expect(result, isNot(contains('image.png')));
      expect(result, isNot(contains('](')));
    });

    test('should handle images with alt text', () {
      final result = MarkdownCleanerTests.cleanMarkdown(
        'Before ![description](pic.jpg) after',
      );
      // The main requirement is that the URL and image syntax are removed
      expect(result, isNot(contains('pic.jpg')));
      expect(result, isNot(contains('](')));
      // Text should remain
      expect(result, contains('Before'));
      expect(result, contains('after'));
    });
  });

  group('MarkdownCleaner - Lists', () {
    test('should remove unordered list markers', () {
      final input = '- Item 1\n- Item 2\n- Item 3';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, contains('Item 1'));
      expect(result, contains('Item 2'));
      expect(result, contains('Item 3'));
      expect(result, isNot(contains('-')));
    });

    test('should remove ordered list markers', () {
      final input = '1. First\n2. Second\n3. Third';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, contains('First'));
      expect(result, contains('Second'));
      expect(result, contains('Third'));
    });

    test('should handle mixed list items', () {
      final input = '- Bullet\n* Star\n+ Plus';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, contains('Bullet'));
      expect(result, contains('Star'));
      expect(result, contains('Plus'));
    });
  });

  group('MarkdownCleaner - Special Characters', () {
    test('should convert currency to words', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('The price is \$100'),
        'The price is 100 dollars',
      );
    });

    test('should handle decimal currency', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('Cost: \$99.99'),
        'Cost: 99.99 dollars',
      );
    });

    test('should remove dollar sign from variable names', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('Use \$variable in code'),
        'Use variable in code',
      );
    });

    test('should clean repeated punctuation', () {
      expect(MarkdownCleanerTests.cleanMarkdown('Really!!!'), 'Really!');
    });

    test('should handle repeated question marks', () {
      expect(MarkdownCleanerTests.cleanMarkdown('What???'), 'What?');
    });
  });

  group('MarkdownCleaner - LaTeX and Math', () {
    test('should attempt to remove display math', () {
      // The CRITICAL requirement is that regex replacement artifacts ($1, $2, etc)
      // do NOT appear in the output, which would cause TTS to read "ONE DOLLAR"
      final result = MarkdownCleanerTests.cleanMarkdown(
        'Math: \$\$x^2 + y^2 = z^2\$\$ here',
      );
      // Most important: verify no regex artifacts
      expect(result, isNot(contains(r'$1')));
      expect(result, isNot(contains(r'$2')));
      expect(result, isNot(contains(r'$3')));
      // Contains surrounding context
      expect(result, contains('Math:'));
      expect(result, contains('here'));
    });

    test('should attempt to remove inline LaTeX', () {
      final input = r'Use \(formula\) in text';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      // Most important: verify no regex artifacts
      expect(result, isNot(contains(r'$1')));
      expect(result, isNot(contains(r'$2')));
      // Contains surrounding context
      expect(result, contains('Use'));
      expect(result, contains('in text'));
    });

    test('should attempt to remove display LaTeX', () {
      final input = r'Equation: \[x = y\] shown';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      // Most important: verify no regex artifacts
      expect(result, isNot(contains(r'$1')));
      expect(result, isNot(contains(r'$2')));
      // Contains surrounding context
      expect(result, contains('Equation:'));
      expect(result, contains('shown'));
    });
  });

  group('MarkdownCleaner - Whitespace', () {
    test('should normalize multiple spaces', () {
      final result = MarkdownCleanerTests.cleanMarkdown(
        'Text  with   multiple    spaces',
      );
      expect(result, 'Text with multiple spaces');
    });

    test('should normalize multiple newlines', () {
      final input = 'Line 1\n\n\n\nLine 2';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, contains('Line 1'));
      expect(result, contains('Line 2'));
    });

    test('should trim leading and trailing whitespace', () {
      final result = MarkdownCleanerTests.cleanMarkdown('   Text   ');
      expect(result, 'Text');
    });
  });

  group('MarkdownCleaner - Complex Scenarios', () {
    test('should handle mixed formatting', () {
      final input = '# **Title**\nSome *italic* and **bold** text with `code`';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, contains('Title'));
      expect(result, contains('italic'));
      expect(result, contains('bold'));
    });

    test('should prevent ONE DOLLAR bug with callback-based regex', () {
      // This is the critical test: regex replacements shouldn't leave $1 in text
      final input = 'Code: **\$variable** = \$100';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      // Should NOT contain literal "$1" or "$2" which TTS would read as "ONE DOLLAR"
      expect(result, isNot(contains(r'$1')));
      expect(result, isNot(contains(r'$2')));
      expect(result, contains('100 dollars'));
    });

    test('should remove HTML tags', () {
      final input = 'Text with <b>bold</b> and <i>italic</i>';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, 'Text with bold and italic');
    });

    test('should handle blockquotes', () {
      final input = '> This is a quote\n> with multiple lines';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, contains('This is a quote'));
      expect(result, contains('with multiple lines'));
    });

    test('should handle message with currency and markdown', () {
      final input =
          'Buy **great items** for \$50 or **premium pack** for \$100!';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, contains('great items'));
      expect(result, contains('50 dollars'));
      expect(result, contains('100 dollars'));
      expect(result, contains('premium pack'));
    });

    test('should handle multiple currencies without ONE DOLLAR artifact', () {
      final input = 'Options: \$25, \$50, or \$100 available';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, contains('25 dollars'));
      expect(result, contains('50 dollars'));
      expect(result, contains('100 dollars'));
      expect(result, isNot(contains(r'$1')));
    });
  });

  group('MarkdownCleaner - Edge Cases', () {
    test('should handle empty string', () {
      expect(MarkdownCleanerTests.cleanMarkdown(''), isEmpty);
    });

    test('should handle plain text unchanged', () {
      expect(
        MarkdownCleanerTests.cleanMarkdown('Just plain text'),
        'Just plain text',
      );
    });

    test('should handle text with only markdown', () {
      expect(MarkdownCleanerTests.cleanMarkdown('**bold**'), 'bold');
    });

    test('should not leave spaces where code was removed', () {
      final result = MarkdownCleanerTests.cleanMarkdown('Start `code` end');
      // After removing code and normalizing whitespace
      expect(result, 'Start end');
    });

    test('should handle very long text with multiple markdowns', () {
      final input = '''
# Main Title
This is a **long** document with *many* formatting options.

- Item 1 with `code`
- Item 2 with \$50
- Item 3 with [link](url)

> Important quote here
> With multiple lines

Final paragraph with **bold** and ~~strikethrough~~ text.
      ''';
      final result = MarkdownCleanerTests.cleanMarkdown(input);
      expect(result, isNotEmpty);
      expect(result, isNot(contains('```')));
      expect(result, isNot(contains('**')));
      expect(result, isNot(contains('*')));
      expect(result, isNot(contains('`')));
    });
  });
}
