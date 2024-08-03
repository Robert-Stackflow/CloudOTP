import 'dart:io';
import 'dart:math';

import 'package:cloudotp/Utils/shortcuts_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';

/// A keymap widget allowing easy addition of shortcut keys to any widget tree
/// with an optional help screen overlay
class KeyboardWidget extends StatefulWidget {
  final bool hasFocus;
  final Widget title;

  ///Optional introductory/descriptive text to include above the table of
  ///keystroke shortcuts. It expects text in the
  ///[https://daringfireball.net/projects/markdown/] markdown format, using
  ///the [https://pub.dev/packages/flutter_markdown] flutter markdown package.

  ///The list of keystrokes and methods called
  final List<CloudOTPShortcut> bindings;

  final LogicalKeyboardKey showDismissKey;

  ///The number of columns of text in the help screen
  final int columnCount;
  final bool showMap;
  final VoidCallback? callbackOnHide;

  ///The color of the surface of the card used to display a help screen.
  ///If null, the card color of the inherited [ThemeData.colorScheme] will be used
  final Color? backgroundColor;

  ///The text style for the text used in the help screen. If null, the
  ///inherited [TextTheme.labelSmall] is used.
  final TextStyle? textStyle;

  /// Creates a new KeyboardWidget with a list of Keystrokes and associated
  /// functions [bindings], a required [title] widget and an optional
  /// keystroke to show and dismiss the displayed map, [showDismissKey].
  ///
  /// The number of columns of text used to display the options can be optionally
  /// chosen. It defaults to one column.
  ///
  /// The [backgroundColor] and [textColor] set the background of the
  /// card used to display the help screen background and text respectively.
  /// Otherwise they default to the inherited theme's card and primary text
  /// colors.
  ///
  /// By default the F1 keyboard key is used to show and dismiss the keymap
  /// display. If another key is preferred, set the [showDismissKey] to another
  /// [LogicalKeyboardKey].
  ///
  /// If the help map should be displayed, set the parameter [showMap] to true.
  /// This lets the implementer programmatically show the map.
  /// You would usually pair this with a function [callbackOnHide] so that the caller
  /// to show the help screen can be notified when it is hidden
  ///
  const KeyboardWidget({
    super.key,
    required this.bindings,
    this.hasFocus = true,
    required this.title,
    this.showDismissKey = LogicalKeyboardKey.f1,
    this.columnCount = 2,
    this.backgroundColor,
    this.textStyle,
    this.showMap = false,
    this.callbackOnHide,
  }) : assert(columnCount > 0);

  @override
  KeyboardWidgetState createState() => KeyboardWidgetState();
}

class KeyboardWidgetState extends State<KeyboardWidget> {
  late FocusNode _focusNode;

  static const Color defaultBackground = Color(0xFF0a0a0a);
  static const Color defaultTextColor = Colors.white;

  static const TextStyle defaultTextStyle =
      TextStyle(color: defaultTextColor, fontSize: 12);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        keyboardHandlerState?.focus();
      }
    });
  }

  @override
  void didUpdateWidget(KeyboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget _getBubble(
    String text,
    Color color,
    Color color2,
    TextStyle textStyle, {
    bool invert = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: invert ? color : color2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color)),
      child: Text(
        text,
        style: textStyle.copyWith(color: invert ? color2 : color),
      ),
    );
  }

  String _getModifiers(CloudOTPShortcut rep) {
    StringBuffer buffer = StringBuffer();
    if (rep.isMetaPressed) {
      if (!kIsWeb && Platform.isMacOS) {
        buffer.write('⌘');
      } else {
        buffer.write('Meta + ');
      }
    }
    if (rep.isControlPressed) {
      if (!kIsWeb && Platform.isMacOS) {
        buffer.write('⌃');
      } else {
        buffer.write('Ctrl + ');
      }
    }
    if (rep.isShiftPressed) {
      if (kIsWeb) {
        buffer.write('Shift + ');
      } else {
        // '⇧'
        buffer.write('Shift + ');
      }
    }
    if (rep.isAltPressed) {
      if (!kIsWeb && Platform.isMacOS) {
        buffer.write('⌥');
      } else {
        buffer.write('Alt ');
      }
    }
    if (kIsWeb || !Platform.isMacOS) {
      return buffer.toString().trimRight();
    } else {
      return buffer.toString();
    }
  }

  static const double horizontalMargin = 16.0;

  Widget _buildMainBody() {
    final ThemeData theme = Theme.of(context);
    TextStyle textStyle =
        widget.textStyle ?? theme.textTheme.bodyMedium ?? defaultTextStyle;
    Color background = widget.backgroundColor ?? theme.canvasColor;
    Color textColor = textStyle.color ?? defaultTextColor;

    int length = widget.bindings.length;

    int rowCount = (length / widget.columnCount).ceil();
    List<List<DataCell>> tableRows = [];
    for (int k = 0; k < rowCount; k++) {
      tableRows.add(<DataCell>[]);
    }
    List<DataColumn> columns = [];
    for (int k = 0; k < widget.columnCount; k++) {
      columns
          .add(const DataColumn(label: Text('m'), numeric: true)); //right-align
      columns.add(const DataColumn(label: Text('k')));
      columns.add(const DataColumn(label: Text('d')));
    }
    int fullRows = widget.bindings.length ~/ widget.columnCount;
    for (int k = 0; k < fullRows; k++) {
      List<DataCell> dataRow = tableRows[k];
      for (int t = 0; t < widget.columnCount; t++) {
        CloudOTPShortcut rep = widget.bindings[k * widget.columnCount + t];
        String modifiers = _getModifiers(rep);
        dataRow.add(modifiers.isNotEmpty
            ? DataCell(
                _getBubble(
                  modifiers,
                  textColor,
                  background,
                  textStyle,
                  invert: true,
                ),
              )
            : DataCell.empty);
        dataRow.add(
          DataCell(
            _getBubble(
              rep.triggerLabel,
              textColor,
              background,
              textStyle,
            ),
          ),
        );
        dataRow.add(
          DataCell(
            Container(
              margin: const EdgeInsets.only(right: 20),
              child: Text(
                rep.labelProvider(S.current),
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ),
        );
      }
    }
    if (widget.bindings.length % widget.columnCount != 0) {
      List<DataCell> dataRow = tableRows[fullRows];
      int k = fullRows * widget.columnCount;
      for (; k < widget.bindings.length; k++) {
        CloudOTPShortcut rep = widget.bindings[k];
        String modifiers = _getModifiers(rep);
        dataRow.add(modifiers.isNotEmpty
            ? DataCell(
                _getBubble(
                  modifiers,
                  textColor,
                  background,
                  textStyle,
                  invert: true,
                ),
              )
            : DataCell.empty);
        dataRow.add(
          DataCell(
            _getBubble(
              rep.triggerLabel,
              textColor,
              background,
              textStyle,
            ),
          ),
        );
        dataRow.add(
          DataCell(
            Container(
              margin: const EdgeInsets.only(right: 20),
              child: Text(
                rep.labelProvider(S.current),
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ),
        );
      }
      k = widget.bindings.length;
      for (; k < rowCount * widget.columnCount; k++) {
        dataRow.add(DataCell.empty);
        dataRow.add(DataCell.empty);
        dataRow.add(DataCell.empty);
      }
    }
    List<DataRow> rows = [];
    for (List<DataCell> cells in tableRows) {
      rows.add(
        DataRow(
          cells: cells,
        ),
      );
    }

    Widget dataTable = SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          dividerTheme: const DividerThemeData(
            color: Colors.transparent,
            space: 0,
            thickness: 0,
            indent: 0,
            endIndent: 0,
          ),
        ),
        child: DataTable(
          columnSpacing: 12,
          border: TableBorder.all(color: Colors.transparent, width: 0),
          columns: columns,
          rows: rows,
          showBottomBorder: true,
          dataRowMinHeight: 36.0 + (textStyle.fontSize ?? 12.0),
          dataRowMaxHeight: 36.0 + (textStyle.fontSize ?? 12.0),
          headingRowHeight: 0,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );

    Widget grid = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Utils.isDark(context)
                ? Theme.of(context).shadowColor
                : Colors.grey.shade400,
            offset: const Offset(0, 4),
            blurRadius: 10,
            spreadRadius: 0,
          ).scale(4)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.title,
          const SizedBox(height: 20),
          Focus(
            descendantsAreFocusable: true,
            skipTraversal: false,
            focusNode: _focusNode,
            autofocus: false,
            onKeyEvent: (FocusNode node, KeyEvent event) {
              if (event.runtimeType == KeyDownEvent && node.hasPrimaryFocus) {
                LogicalKeyboardKey key = event.logicalKey;
                if (key == widget.showDismissKey ||
                    key == LogicalKeyboardKey.escape) {
                  _hideOverlay();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: dataTable,
          ),
        ],
      ),
    );

    double width = MediaQuery.sizeOf(context).width - 200;
    double height = MediaQuery.sizeOf(context).height - 200;
    double preferWidth = min(width, 600);
    double preferHeight = min(height, 400);
    double preferHorizontalMargin =
        width > preferWidth ? (width - preferWidth) / 2 : 0;
    double preferVerticalMargin =
        height > preferHeight ? (height - preferHeight) / 2 : 0;

    return Positioned(
      child: GestureDetector(
        onTap: () {
          _hideOverlay();
        },
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: preferHorizontalMargin,
            vertical: preferVerticalMargin,
          ),
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          decoration: const BoxDecoration(color: Colors.black26),
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                alignment: Alignment.center,
                child: grid,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainBody();
  }

  void _hideOverlay() {
    setState(() {
      if (widget.callbackOnHide != null) {
        widget.callbackOnHide!();
      }
    });
    _focusNode.unfocus();
  }
}
