/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';

class ProgressText extends StatelessWidget {
  final String text;
  final double progress;
  final BuildContext mContext;
  final Color? color;
  final Color? backgroundColor;
  final double? fontSize;
  final double? letterSpacing;
  final AlignmentGeometry? alignment;

  static const Color defaultColor = Colors.green;
  static const Color defaultBackgroundColor = Colors.grey;

  const ProgressText(
    this.mContext,
    this.text, {
    super.key,
    required this.progress,
    this.color = defaultColor,
    this.backgroundColor = defaultBackgroundColor,
    this.fontSize = 24,
    this.letterSpacing = 5,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: buildTextSpan(),
    );
  }

  TextSpan buildTextSpan() {
    final int completedLength = (text.length * progress).floor();
    final double partialProgress = text.length * progress - completedLength;

    List<TextSpan> spans = [];

    if (completedLength > 0) {
      spans.add(
        TextSpan(
          text: text.substring(0, completedLength),
          style: TextStyle(color: color),
        ),
      );
    }

    if (completedLength < text.length) {
      final String partialChar = text[completedLength];
      spans.add(
        TextSpan(
          text: partialChar,
          style: TextStyle(
            foreground: Paint()..shader = _createPartialShader(partialProgress),
          ),
        ),
      );
    }

    if (completedLength + 1 < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(completedLength + 1),
          style: TextStyle(color: backgroundColor),
        ),
      );
    }

    return TextSpan(
      children: spans,
      style: Theme.of(mContext).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: fontSize! + 30.0,
            // letterSpacing: 5,
          ),
    );
  }

  Shader _createPartialShader(double progress) {
    return LinearGradient(
      colors: [
        color ?? defaultColor,
        backgroundColor ?? defaultBackgroundColor
      ],
      stops: [progress, progress],
    ).createShader(const Rect.fromLTWH(0, 0, 50, 0));
  }
}
