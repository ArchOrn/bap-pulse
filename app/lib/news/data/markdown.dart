import 'package:flutter/material.dart';
import 'package:bap_pulse/core/theme/colors.dart';

/// Tiny Markdown subset shared with the BO. Supports `**bold**` (rendered with
/// the brand accent color, mirroring the existing pulse-feed style where player
/// names pop) and `*italic*`. Anything else is rendered as plain text — by
/// design, the BO editor exposes only this subset.
List<TextSpan> markdownToSpans(
  String input, {
  TextStyle? baseStyle,
}) {
  final base = baseStyle ?? const TextStyle(color: AppColors.textPrimary);
  final spans = <TextSpan>[];
  final buffer = StringBuffer();

  void flush() {
    if (buffer.isEmpty) return;
    spans.add(TextSpan(text: buffer.toString(), style: base));
    buffer.clear();
  }

  int i = 0;
  while (i < input.length) {
    if (i + 1 < input.length && input.substring(i, i + 2) == '**') {
      final end = input.indexOf('**', i + 2);
      if (end != -1) {
        flush();
        spans.add(TextSpan(
          text: input.substring(i + 2, end),
          style: base.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ));
        i = end + 2;
        continue;
      }
    }
    if (input[i] == '*') {
      final end = input.indexOf('*', i + 1);
      if (end != -1) {
        flush();
        spans.add(TextSpan(
          text: input.substring(i + 1, end),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ));
        i = end + 1;
        continue;
      }
    }
    buffer.write(input[i]);
    i++;
  }
  flush();
  return spans;
}
