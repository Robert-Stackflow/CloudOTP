import 'package:awesome_chewie/src/Utils/System/uri_util.dart';
import 'package:awesome_chewie/src/Utils/utils.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/toggle_icon_button.dart';
import 'package:code_highlight_view/themes/github.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_highlighting/themes/github-dark.dart';
import 'package:markdown_widget/markdown_widget.dart';

import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/color_util.dart';
import 'package:awesome_chewie/src/generated/l10n.dart';
import 'latex.dart';

class CustomMarkdownWidget extends StatefulWidget {
  const CustomMarkdownWidget(
    this.content, {
    super.key,
    this.baseStyle,
    this.maxWidth,
  });

  final String content;
  final double? maxWidth;
  final TextStyle? baseStyle;

  @override
  CustomMarkdownWidgetState createState() => CustomMarkdownWidgetState();
}

class CustomMarkdownWidgetState extends State<CustomMarkdownWidget> {
  TextStyle get baseStyle => widget.baseStyle ?? ChewieTheme.bodyMedium;

  Color get codeBackgroundColor => ChewieTheme.cardColor;

  List<WidgetConfig> commonConfigs() {
    return [
      PConfig(textStyle: baseStyle),
      H1Config(
        headingDivider:
            HeadingDivider(color: ChewieTheme.dividerColor, height: 0),
      ),
      H2Config(
        headingDivider: HeadingDivider(
            color: ChewieTheme.dividerColor, space: 3.6, height: 0),
      ),
      H3Config(
        headingDivider: HeadingDivider(
            color: ChewieTheme.dividerColor, space: 2.4, height: 0),
      ),
      CodeConfig(
        style: baseStyle.apply(fontSizeDelta: -1),
        decoration: BoxDecoration(
          color: ChewieTheme.cardColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      HrConfig(height: 0.8, color: ChewieTheme.borderColor),
      LinkConfig(
        style: TextStyle(
          color: ChewieTheme.linkColor,
          decoration: TextDecoration.underline,
        ),
        onTap: (url) {
          UriUtil.processUrl(context, url);
        },
      ),
      TableConfig(
        border: TableBorder.all(color: ChewieTheme.borderColor, width: 1.5),
        headerRowDecoration:
            BoxDecoration(color: ChewieTheme.scaffoldBackgroundColor),
        bodyOddRowDecoration: BoxDecoration(
            color: ChewieTheme.scaffoldBackgroundColor.withOpacity(0.5)),
        bodyEvenRowDecoration: BoxDecoration(color: ChewieTheme.cardColor),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      ),
    ];
  }

  MarkdownConfig lightConfig() {
    var config = MarkdownConfig.defaultConfig;
    return config.copy(
      configs: [
        ...commonConfigs(),
        PreConfig(
          decoration: BoxDecoration(
            color: codeBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          theme: githubTheme,
          wrapper: (child, text, language) =>
              CodeWrapperWidget(child, text, language),
        ),
      ],
    );
  }

  MarkdownConfig darkConfig() {
    var config = MarkdownConfig.darkConfig;
    return config.copy(configs: [
      ...commonConfigs(),
      PreConfig(
        decoration: BoxDecoration(
          color: codeBackgroundColor,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        theme: githubDarkTheme,
        wrapper: (child, text, language) =>
            CodeWrapperWidget(child, text, language),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ColorUtil.isDark(context);
    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth ?? double.infinity),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: MarkdownGenerator(
          generators: [latexGenerator],
          inlineSyntaxList: [LatexSyntax()],
        ).buildWidgets(
          widget.content,
          config: isDark ? darkConfig() : lightConfig(),
        ),
      ),
    );
  }
}

class CodeWrapperWidget extends StatefulWidget {
  final Widget child;
  final String text;
  final String? language;

  const CodeWrapperWidget(this.child, this.text, this.language, {super.key});

  @override
  State<CodeWrapperWidget> createState() => _CodeWrapperWidgetState();
}

class _CodeWrapperWidgetState extends State<CodeWrapperWidget> {
  Color get codeBackgroundColor => ChewieTheme.scaffoldBackgroundColor;

  bool get isError => widget.language!.toUpperCase() == "CHATTIEEXCEPTION";

  String get language => widget.language!.toUpperCase().isNotEmpty
      ? widget.language!.toUpperCase()
      : "CODE";

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: codeBackgroundColor,
        border: ChewieTheme.border,
        borderRadius: ChewieDimens.borderRadius8,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(border: ChewieTheme.bottomBorder),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                if (widget.language != null)
                  Text(
                    isError ? widget.language! : widget.language!.toUpperCase(),
                    style: ChewieTheme.titleMedium.apply(
                      color: isError ? ChewieTheme.errorColor : null,
                      fontWeightDelta: isError ? 2 : 0,
                    ),
                  ),
                const Spacer(),
                ToggleIconButton(
                  tooltip: ChewieS.current.copy,
                  iconA: Icon(
                    CupertinoIcons.square_on_square,
                    size: 18,
                    color: ChewieTheme.iconColor,
                  ),
                  iconB: Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 18,
                    color: ChewieTheme.iconColor,
                  ),
                  onPressed: () => ChewieUtils.copy(context, widget.text),
                ),
              ],
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
