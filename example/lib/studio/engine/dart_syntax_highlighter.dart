import 'package:flutter/material.dart';

/// A lightweight Dart syntax highlighter that produces a [TextSpan] tree.
///
/// This is intentionally minimal — it colorizes the token classes most
/// relevant to the generated FNQ Studio output (keywords, strings, classes,
/// comments, punctuation) without requiring an external dependency.
class DartSyntaxHighlighter {
  DartSyntaxHighlighter._();

  // ── Token colour palettes ──
  // Dark mode (GitHub dark-mode inspired)
  static const _keywordDark = Color(0xFFFF79C6); // pink
  static const _stringDark = Color(0xFF80CBC4); // teal
  static const _commentDark = Color(0xFF6272A4); // muted blue-grey
  static const _classTypeDark = Color(0xFF8BE9FD); // cyan
  static const _numberDark = Color(0xFFFFB86C); // orange
  static const _punctuationDark = Color(0xFF6D8A9A); // slate
  static const _plainDark = Color(0xFFCDD6F4); // near-white

  // Light mode (GitHub light-mode inspired)
  static const _keywordLight = Color(0xFFCF222E); // red
  static const _stringLight = Color(0xFF0A3069); // dark blue
  static const _commentLight = Color(0xFF6E7781); // grey
  static const _classTypeLight = Color(0xFF953800); // brown/orange
  static const _numberLight = Color(0xFF0550AE); // blue
  static const _punctuationLight = Color(0xFF57606A); // slate
  static const _plainLight = Color(0xFF24292F); // dark slate/black

  static const _keywords = {
    'const',
    'final',
    'var',
    'void',
    'return',
    'null',
    'true',
    'false',
    'new',
    'this',
    'super',
    'import',
    'class',
    'extends',
    'implements',
    'abstract',
    'static',
    'required',
    'assert',
  };

  // Identifiers that start with uppercase are treated as types/classes
  static final _upperStart = RegExp('^[A-Z]');

  /// Tokenises [code] and returns a [TextSpan] suitable for a [RichText] or
  /// [SelectableText.rich] widget.
  static TextSpan highlight(
    final String code, {
    required final bool isDark,
    final double fontSize = 13,
    final double height = 1.6,
  }) {
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: height,
    );

    final keywordColor = isDark ? _keywordDark : _keywordLight;
    final stringColor = isDark ? _stringDark : _stringLight;
    final commentColor = isDark ? _commentDark : _commentLight;
    final classTypeColor = isDark ? _classTypeDark : _classTypeLight;
    final numberColor = isDark ? _numberDark : _numberLight;
    final punctuationColor = isDark ? _punctuationDark : _punctuationLight;
    final plainColor = isDark ? _plainDark : _plainLight;

    // Tokenise by scanning the source left-to-right
    final children = <TextSpan>[];
    final src = code;
    var i = 0;

    while (i < src.length) {
      // ── Single-line comment ──
      if (i + 1 < src.length && src[i] == '/' && src[i + 1] == '/') {
        final end = src.indexOf('\n', i);
        final comment = end == -1 ? src.substring(i) : src.substring(i, end);
        children.add(
          TextSpan(
            text: comment,
            style: style.copyWith(color: commentColor),
          ),
        );
        i += comment.length;
        continue;
      }

      // ── String literal (single or double quotes) ──
      if (src[i] == "'" || src[i] == '"') {
        final quote = src[i];
        var end = i + 1;
        while (end < src.length) {
          if (src[end] == '\\') {
            end += 2;
            continue;
          }
          if (src[end] == quote) {
            end++;
            break;
          }
          end++;
        }
        children.add(
          TextSpan(
            text: src.substring(i, end),
            style: style.copyWith(color: stringColor),
          ),
        );
        i = end;
        continue;
      }

      // ── Identifier or keyword ──
      if (_isIdentStart(src[i])) {
        var end = i + 1;
        while (end < src.length && _isIdentPart(src[end])) {
          end++;
        }
        final word = src.substring(i, end);
        final Color color;
        if (_keywords.contains(word)) {
          color = keywordColor;
        } else if (_upperStart.hasMatch(word)) {
          color = classTypeColor;
        } else {
          color = plainColor;
        }
        children.add(TextSpan(text: word, style: style.copyWith(color: color)));
        i = end;
        continue;
      }

      // ── Number ──
      if (_isDigit(src[i])) {
        var end = i + 1;
        while (end < src.length && (_isDigit(src[end]) || src[end] == '.')) {
          end++;
        }
        children.add(
          TextSpan(
            text: src.substring(i, end),
            style: style.copyWith(color: numberColor),
          ),
        );
        i = end;
        continue;
      }

      // ── Punctuation / operators ──
      if (_isPunct(src[i])) {
        children.add(
          TextSpan(
            text: src[i],
            style: style.copyWith(color: punctuationColor),
          ),
        );
        i++;
        continue;
      }

      // ── Whitespace / unclassified ──
      children.add(
        TextSpan(
          text: src[i],
          style: style.copyWith(color: plainColor),
        ),
      );
      i++;
    }

    return TextSpan(children: children);
  }

  static bool _isIdentStart(final String c) =>
      (c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90) || // A-Z
      (c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122) || // a-z
      c == '_' ||
      c == r'$';

  static bool _isIdentPart(final String c) => _isIdentStart(c) || _isDigit(c);

  static bool _isDigit(final String c) {
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  static bool _isPunct(final String c) =>
      '(){}[]<>,.;:=!&|^~%+-*/\\@#?'.contains(c);
}
