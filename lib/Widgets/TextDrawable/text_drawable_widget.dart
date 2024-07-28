import 'package:flutter/material.dart';

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
            TextStyle(
              fontSize: widget.height * 0.5,
              color: contrast > 1.8 ? Colors.white : Colors.black,
            ),
      ),
    );
  }
}
