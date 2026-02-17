import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/utils/math_preprocessor.dart';

void main() {
  group('preprocessMathDelimiters', () {
    test('should return empty string unchanged', () {
      expect(preprocessMathDelimiters(''), '');
    });

    test('should return plain text unchanged', () {
      expect(preprocessMathDelimiters('Hello, world!'), 'Hello, world!');
    });

    test('should not modify existing dollar-sign math', () {
      const input = r'Inline $x^2$ and block $$y = mx + b$$';
      expect(preprocessMathDelimiters(input), input);
    });

    group('block math with backslash brackets', () {
      test('should convert single-line \\[...\\]', () {
        expect(
          preprocessMathDelimiters(r'\[y = ax^2 + bx + c\]'),
          r'$$y = ax^2 + bx + c$$',
        );
      });

      test('should convert multi-line \\[...\\]', () {
        const input = '\\[\ny = ax^2\n\\]';
        expect(preprocessMathDelimiters(input), '\$\$\ny = ax^2\n\$\$');
      });
    });

    group('block math with plain brackets', () {
      test('should convert [ LaTeX ] on standalone line', () {
        expect(
          preprocessMathDelimiters(r'[ y = ax^{2}+bx+c \qquad (a\neq 0) ]'),
          r'$$y = ax^{2}+bx+c \qquad (a\neq 0)$$',
        );
      });

      test('should convert [ LaTeX ] with vertex form', () {
        expect(
          preprocessMathDelimiters(r'[ y = a\bigl(x-h\bigr)^{2}+k ]'),
          r'$$y = a\bigl(x-h\bigr)^{2}+k$$',
        );
      });

      test('should convert [ ... ] with simple exponents', () {
        expect(
          preprocessMathDelimiters('[ y = ax^2+bx+c ]'),
          r'$$y = ax^2+bx+c$$',
        );
      });

      test('should NOT convert normal markdown link', () {
        const input = '[link text](https://example.com)';
        expect(preprocessMathDelimiters(input), input);
      });

      test('should NOT convert checkbox-like brackets', () {
        const input = '[ ] unchecked item';
        expect(preprocessMathDelimiters(input), input);
      });

      test('should NOT convert short bracket content', () {
        const input = '[ok]';
        expect(preprocessMathDelimiters(input), input);
      });
    });

    group('inline math with backslash parens', () {
      test('should convert \\(...\\) to dollar signs', () {
        expect(
          preprocessMathDelimiters(r'The value is \(\frac{a}{b}\) here'),
          r'The value is $\frac{a}{b}$ here',
        );
      });
    });

    group('inline math with spaced parens - LLM patterns', () {
      test('should convert ( x^2 - 9 = 0 ) with exponent', () {
        expect(
          preprocessMathDelimiters('Solve ( x^2 - 9 = 0 )'),
          r'Solve $x^2 - 9 = 0$',
        );
      });

      test('should convert ( 3x^2 + 2x - 1 = 0 ) polynomial', () {
        expect(
          preprocessMathDelimiters('Given ( 3x^2 + 2x - 1 = 0 )'),
          r'Given $3x^2 + 2x - 1 = 0$',
        );
      });

      test('should convert ( x^2 + 4x + 1 = 0 )', () {
        expect(
          preprocessMathDelimiters('( x^2 + 4x + 1 = 0 )'),
          r'$x^2 + 4x + 1 = 0$',
        );
      });

      test('should convert ( 5x^2 - 3x - 2 = 0 )', () {
        expect(
          preprocessMathDelimiters('Solve ( 5x^2 - 3x - 2 = 0 )'),
          r'Solve $5x^2 - 3x - 2 = 0$',
        );
      });

      test('should convert ( x = -\\frac{2}{5} )', () {
        expect(
          preprocessMathDelimiters(r'Answer: ( x = -\frac{2}{5} )'),
          r'Answer: $x = -\frac{2}{5}$',
        );
      });

      test('should convert ( x = -\\frac{b}{2a} )', () {
        expect(
          preprocessMathDelimiters(r'vertex formula: ( x = -\frac{b}{2a} ).'),
          r'vertex formula: $x = -\frac{b}{2a}$.',
        );
      });

      test('should convert ( \\frac{b}{a} ) starting with LaTeX', () {
        expect(
          preprocessMathDelimiters(r'coefficient: ( \frac{b}{a} ).'),
          r'coefficient: $\frac{b}{a}$.',
        );
      });

      test('should convert ( \\displaystyle \\frac{b}{2a} )', () {
        expect(
          preprocessMathDelimiters(
            r'Halve it: ( \displaystyle \frac{b}{2a} ).',
          ),
          r'Halve it: $\displaystyle \frac{b}{2a}$.',
        );
      });

      test('should NOT convert normal parenthesized text', () {
        const input = 'This is (just a note) in parens';
        expect(preprocessMathDelimiters(input), input);
      });

      test('should NOT convert prose in parens with English words', () {
        const input = '(if the value is too large)';
        expect(preprocessMathDelimiters(input), input);
      });

      test('should NOT convert (a != 1) without math indicators', () {
        // No exponents, no LaTeX commands, no equation structure
        const input = '(a != 1)';
        expect(preprocessMathDelimiters(input), input);
      });
    });

    group('table cell math patterns', () {
      test('should convert math in table cells', () {
        const input = '| Factoring | ( x^2 - 9 = 0 ) |';
        final result = preprocessMathDelimiters(input);
        expect(result, contains(r'$x^2 - 9 = 0$'));
      });

      test('should convert \\frac in table cells', () {
        const input = r'| vertex | ( x = -\frac{b}{2a} ) |';
        final result = preprocessMathDelimiters(input);
        expect(result, contains(r'$x = -\frac{b}{2a}$'));
      });
    });

    group('mixed content', () {
      test('should handle text with multiple math blocks', () {
        const input =
            'Given:\n'
            r'[ y = ax^{2}+bx+c \qquad (a\neq 0) ]'
            '\nGoal: vertex form\n'
            r'[ y = a\bigl(x-h\bigr)^{2}+k ]';
        final result = preprocessMathDelimiters(input);
        expect(result, contains(r'$$y = ax^{2}+bx+c \qquad (a\neq 0)$$'));
        expect(result, contains(r'$$y = a\bigl(x-h\bigr)^{2}+k$$'));
        expect(result, contains('Given:'));
        expect(result, contains('Goal: vertex form'));
      });

      test('should handle text with inline and block math', () {
        const input =
            'Take \\(\\frac{b}{a}\\) and compute:\n'
            r'[ y = \frac{b^2}{4a} ]';
        final result = preprocessMathDelimiters(input);
        expect(result, contains(r'$\frac{b}{a}$'));
        expect(result, contains(r'$$y = \frac{b^2}{4a}$$'));
      });

      test('should handle practice problem from screenshot', () {
        const input =
            r'Solve ( 5x^2 - 3x - 2 = 0 ) using the quadratic formula. '
            r'*(Answer: ( x = 1 ) or ( x = -\frac{2}{5} ))*';
        final result = preprocessMathDelimiters(input);
        expect(result, contains(r'$5x^2 - 3x - 2 = 0$'));
        expect(result, contains(r'$x = -\frac{2}{5}$'));
      });
    });
  });
}
