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

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'color_generator.dart';
import 'contrast_helper.dart';

// ignore: must_be_immutable
class TextDrawable extends StatefulWidget {
  /// The text supplied. Only first character will be displayed.
  final String text;

  /// Height of the [TextDrawable] widget.
  final double height;

  /// Width of the [TextDrawable] widget.
  final double width;

  /// `TextStyle` for the `text` to be displayed.
  final TextStyle? textStyle;

  /// Background color to for the widget.
  /// If not specified, a random color will be generated.
  final Color? backgroundColor;

  /// Shape of the widget.
  /// Defaults to `BoxShape.circle`.
  final BoxShape boxShape;

  /// Border radius of the widget.
  /// Only specify this if `boxShape == BoxShape.circle`.
  final BorderRadiusGeometry? borderRadius;

  /// Creates a customizable [TextDrawable] widget.
  TextDrawable({
    super.key,
    required this.text,
    this.height = 48,
    this.width = 48,
    this.textStyle,
    this.backgroundColor,
    this.boxShape = BoxShape.circle,
    this.borderRadius,
  }) {
    assert(
      boxShape == BoxShape.rectangle || borderRadius == null,
      "Set boxShape = BoxShape.rectangle when borderRadius is specified",
    );
  }

  @override
  TextDrawableState createState() => TextDrawableState();
}

class TextDrawableState extends State<TextDrawable> {
  Color? backgroundColor;

  @override
  void initState() {
    backgroundColor = widget.backgroundColor ??
        ColorGenerator().getColorByString(widget.text);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double contrast = ContrastHelper.contrast([
      backgroundColor!.red,
      backgroundColor!.green,
      backgroundColor!.blue,
    ], [
      255,
      255,
      255
    ]);
    contrast = 2;
    return _getSide(contrast);
  }

  Widget _getSide(double contrast) {
    return Container(
      alignment: Alignment.center,
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: widget.boxShape,
        borderRadius: widget.borderRadius,
      ),
      child: Text(
        widget.text.isNotEmpty ? widget.text[0].toUpperCase() : 'A',
        style: widget.textStyle?.copyWith(
              color: contrast > 1.8 ? Colors.white : Colors.black,
              fontSize: widget.height * 0.5,
            ) ??
            ChewieTheme.titleMedium.copyWith(
              fontSize: widget.height * 0.5,
              color: contrast > 1.8 ? Colors.white : Colors.black,
            ),
      ),
    );
  }
}
