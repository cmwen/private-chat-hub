/// Preprocessor to normalize various LaTeX math delimiters from LLM output
/// into standard `$...$` (inline) and `$$...$$` (block) format that
/// flutter_markdown_latex can reliably parse.
///
/// Many LLMs output math using inconsistent delimiters:
/// - `[ y = ax^2 ]` instead of `$$ y = ax^2 $$`
/// - `( \frac{a}{b} )` instead of `$\frac{a}{b}$`
/// - `( x^2 + 3x = 0 )` instead of `$x^2 + 3x = 0$`
/// - `\[ ... \]` and `\( ... \)`
///
/// This preprocessor detects these patterns and converts them before rendering.
library;

/// Pattern to detect LaTeX-like math content — commands, superscripts,
/// subscripts, braces, etc.
final _mathIndicatorPattern = RegExp(
  r'\\[a-zA-Z]+|' // LaTeX commands like \frac, \sqrt, \neq
  r'\^{|_{|'       // Superscript/subscript with braces: x^{2}, a_{n}
  r'\^[0-9a-zA-Z]|' // Simple superscript: x^2, x^n
  r'_[0-9a-zA-Z]'   // Simple subscript: a_1, x_i
);

/// Check if content looks like LaTeX math.
bool _looksLikeMath(String content) {
  return _mathIndicatorPattern.hasMatch(content);
}

/// Check if content looks like a math equation (contains = and variables/numbers).
/// Used for patterns like `( x^2 - 9 = 0 )`.
bool _looksLikeMathEquation(String content) {
  // Must contain an equals sign or comparison operator
  if (!RegExp(r'[=<>≤≥≠]').hasMatch(content)) return false;
  // Must contain a variable letter followed by something math-ish
  // e.g. "x^2", "3x", "ax", or a LaTeX command
  return RegExp(r'[a-zA-Z]\^|[0-9][a-zA-Z]|[a-zA-Z][0-9]|\\[a-zA-Z]')
      .hasMatch(content);
}

/// Preprocess message text to normalize math delimiters for rendering.
///
/// Converts various LLM math output formats to standard `$`/`$$` notation:
/// 1. Block math: `\[ ... \]` → `$$ ... $$`
/// 2. Block math: standalone `[ ... ]` lines with LaTeX content → `$$ ... $$`
/// 3. Inline math: `\( ... \)` → `$ ... $`
/// 4. Inline math: `( math... )` within text → `$ ... $`
String preprocessMathDelimiters(String text) {
  if (text.isEmpty) return text;

  // Step 1: Handle multi-line \[...\] blocks
  text = _convertBackslashBracketBlocks(text);

  // Step 2: Handle single-line \[...\]
  text = text.replaceAllMapped(
    RegExp(r'\\\[(.+?)\\\]'),
    (m) => '\$\$${m.group(1)}\$\$',
  );

  // Step 3: Handle standalone [ ... ] lines containing LaTeX
  text = _convertBracketBlockMath(text);

  // Step 4: Handle \(...\) inline math
  text = text.replaceAllMapped(
    RegExp(r'\\\((.+?)\\\)'),
    (m) => '\$${m.group(1)}\$',
  );

  // Step 5: Handle inline ( ... ) containing math
  text = _convertSpacedParenMath(text);

  return text;
}

/// Convert multi-line \[...\] blocks to $$...$$ blocks.
String _convertBackslashBracketBlocks(String text) {
  final pattern = RegExp(r'\\\[\s*\n([\s\S]*?)\n\s*\\\]');
  return text.replaceAllMapped(pattern, (m) {
    return '\$\$\n${m.group(1)}\n\$\$';
  });
}

/// Convert standalone `[ ... ]` lines that contain LaTeX into `$$...$$`.
String _convertBracketBlockMath(String text) {
  final lines = text.split('\n');
  final result = <String>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Check for lines that are `[ math content ]`
    if (trimmed.startsWith('[') &&
        trimmed.endsWith(']') &&
        !trimmed.startsWith('[[') && // Not a wiki-link
        !trimmed.startsWith('[^') && // Not a footnote
        !trimmed.contains('](') &&   // Not a markdown link
        trimmed.length > 4) {
      final content = trimmed.substring(1, trimmed.length - 1).trim();

      if (_looksLikeMath(content) || _looksLikeMathEquation(content)) {
        result.add('\$\$$content\$\$');
        continue;
      }
    }

    result.add(line);
  }

  return result.join('\n');
}

/// Convert inline `( math )` patterns to `$...$`.
///
/// Matches `( content )` where the opening and closing have spaces
/// (LLM convention for math delimiters) and content looks like math.
///
/// Handles patterns like:
/// - `( x^2 - 9 = 0 )` — equation with exponent
/// - `( \frac{b}{a} )` — LaTeX command
/// - `( x = -\frac{2}{5} )` — mixed
/// - `( 3x^2 + 2x - 1 = 0 )` — polynomial
///
/// Does NOT convert:
/// - `(just text)` — no spaces around content
/// - `(if a != 1)` — prose-like content
/// - `((x-3)(x+3))` — nested parens without math indicators
String _convertSpacedParenMath(String text) {
  // Match ( space content space ) — the spaced convention LLMs use
  // Content must not contain newlines and should not be too long (avoid prose)
  return text.replaceAllMapped(
    RegExp(r'\(\s+(.+?)\s+\)'),
    (m) {
      final content = m.group(1)!;

      // Skip if content is too long (likely prose, not math)
      if (content.length > 200) return m.group(0)!;

      // Skip if it looks like prose (contains common English words)
      if (RegExp(r'\b(?:if|the|is|are|was|were|and|but|for|not|with|this|that|from|have|has)\b',
              caseSensitive: false)
          .hasMatch(content)) {
        return m.group(0)!;
      }

      // Convert if it has LaTeX commands OR math indicators
      if (_looksLikeMath(content) || _looksLikeMathEquation(content)) {
        return '\$$content\$';
      }

      return m.group(0)!; // Leave unchanged
    },
  );
}
