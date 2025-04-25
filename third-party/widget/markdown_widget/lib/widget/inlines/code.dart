import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/configs.dart';
import '../span_node.dart';

///Tag:  [MarkdownTag.code]
///the code textSpan
class CodeNode extends ElementNode {
  final CodeConfig codeConfig;
  final String text;

  CodeNode(this.text, this.codeConfig);

  @override
  InlineSpan build() => WidgetSpan(
        child: Container(
          padding: codeConfig.padding,
          decoration: codeConfig.decoration,
          child: Text(
            text,
            style: style,
          ),
        ),
      );

  @override
  TextStyle get style => codeConfig.style.merge(parentStyle);
}

///config class for code, tag: code
class CodeConfig implements InlineConfig {
  final TextStyle style;
  final BoxDecoration decoration;
  final EdgeInsets padding;

  const CodeConfig({
    this.style = const TextStyle(),
    this.decoration = const BoxDecoration(
      color: Color(0xCCeff1f3),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  });

  static CodeConfig get darkConfig => CodeConfig(
          decoration: BoxDecoration(
        color: Color(0xCC1e1e1e),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ));

  @nonVirtual
  @override
  String get tag => MarkdownTag.code.name;
}
