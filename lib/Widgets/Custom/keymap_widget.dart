import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Utils/utils.dart';

/// A keymap widget allowing easy addition of shortcut keys to any widget tree
/// with an optional help screen overlay
class KeyboardWidget extends StatefulWidget {
  final bool hasFocus;
  final Widget child;

  ///Optional introductory/descriptive text to include above the table of
  ///keystroke shortcuts. It expects text in the
  ///[https://daringfireball.net/projects/markdown/] markdown format, using
  ///the [https://pub.dev/packages/flutter_markdown] flutter markdown package.

  ///The list of keystrokes and methods called
  final List<KeyAction> bindings;

  ///The keystroke used to show and dismiss the help screen
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
  /// functions [bindings], a required [child] widget and an optional
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
    required this.child,
    this.showDismissKey = LogicalKeyboardKey.f1,
    this.columnCount = 1,
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
  late OverlayEntry _overlayEntry;
  late bool showingOverlay;

  static const Color defaultBackground = Color(0xFF0a0a0a);
  static const Color defaultTextColor = Colors.white;

  static const TextStyle defaultTextStyle =
      TextStyle(color: defaultTextColor, fontSize: 12);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    showingOverlay = widget.showMap;
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

  //returns text surrounded with a rounded-rect
  Widget _getBubble(String text, Color color, Color color2, TextStyle textStyle,
      {bool invert = false}) {
    // bool isDark = background.computeLuminance() < .5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: invert ? color : color2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color)),
      child: Text(text,
          style: textStyle.copyWith(
              color: invert
                  ? color2
                  : color)), //isDark? _whiteStyle :_blackStyle,),
    );
  }

  //returns the modifier key as text or a symbol (where possible)
  String _getModifiers(KeyAction rep) {
    StringBuffer buffer = StringBuffer();
    if (rep.isMetaPressed) {
      //Platform operating system is not available in the web platform
      if (!kIsWeb && Platform.isMacOS) {
        buffer.write('⌘');
      } else {
        buffer.write('meta ');
      }
    }
    if (rep.isShiftPressed) {
      if (kIsWeb) {
        buffer.write('shift ');
      } else {
        buffer.write('⇧');
      }
    }
    if (rep.isControlPressed) {
      if (!kIsWeb && Platform.isMacOS) {
        buffer.write('⌃');
      } else {
        buffer.write('ctrl ');
      }
    }
    if (rep.isAltPressed) {
      if (!kIsWeb && Platform.isMacOS) {
        buffer.write('⌥');
      } else {
        buffer.write('alt ');
      }
    }
    if (kIsWeb || !Platform.isMacOS) {
      return buffer.toString().trimRight();
    } else {
      return buffer.toString();
    }
  }

  KeyAction? _findMatch(KeyEvent event) {
    for (KeyAction rep in widget.bindings) {
      if (rep.matchesEvent(event)) {
        return rep;
      }
    }
    return null;
  }

  static const double horizontalMargin = 16.0;

  OverlayEntry _buildOverlay() {
    final ThemeData theme = Theme.of(context);
    TextStyle textStyle =
        widget.textStyle ?? theme.textTheme.labelSmall ?? defaultTextStyle;
    Color background = widget.backgroundColor ?? theme.canvasColor;
    Color textColor = textStyle.color ?? defaultTextColor;

    final MediaQueryData media = MediaQuery.of(context);
    Size size = media.size;
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
        KeyAction rep = widget.bindings[k * widget.columnCount + t];
        String modifiers = _getModifiers(rep);
        dataRow.add(modifiers.isNotEmpty
            ? DataCell(_getBubble(modifiers, textColor, background, textStyle,
                invert: true))
            : DataCell.empty);
        dataRow.add(
            DataCell(_getBubble(rep.label, textColor, background, textStyle)));
        dataRow.add(
          DataCell(
            Text(
              rep.description,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        );
      }
    }
    if (widget.bindings.length % widget.columnCount != 0) {
      List<DataCell> dataRow = tableRows[fullRows];
      for (int k = fullRows * widget.columnCount;
          k < widget.bindings.length;
          k++) {
        KeyAction rep = widget.bindings[k];
        String modifiers = _getModifiers(rep);
        dataRow.add(modifiers.isNotEmpty
            ? DataCell(_getBubble(modifiers, textColor, background, textStyle))
            : DataCell.empty);
        dataRow.add(DataCell(_getBubble(
            rep.label, textColor, background, textStyle,
            invert: true)));
        dataRow.add(DataCell(Text(
          rep.description,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        )));
      }
      for (int k = widget.bindings.length;
          k < rowCount * widget.columnCount;
          k++) {
        dataRow.add(DataCell.empty);
        dataRow.add(DataCell.empty);
        dataRow.add(DataCell.empty);
      }
    }
    List<DataRow> rows = [];
    for (List<DataCell> cells in tableRows) {
      rows.add(DataRow(
        cells: cells,
      ));
    }

    Widget dataTable = Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 6,
          dividerThickness: 1,
          columns: columns,
          rows: rows,
          dataRowMinHeight: 36.0 + (textStyle.fontSize ?? 12.0),
          headingRowHeight: 0,
        ),
      ),
    );

    double width = MediaQuery.sizeOf(context).width - 60;
    double height = MediaQuery.sizeOf(context).width - 80;
    double preferWidth = min(width, 640);
    double preferHeight = min(height, 800);
    double preferHorizontalMargin =
        width > preferWidth ? (width - preferWidth) / 2 : 0;
    double preferVerticalMargin =
        height > preferHeight ? (height - preferHeight) / 2 : 0;

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
      child: dataTable,
    );

    return OverlayEntry(
      builder: (context) {
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
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(color: Colors.black26),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                    alignment: Alignment.center,
                    child: grid,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ///Returns the keyboard widget on desktop platforms. It does not
  ///provide shortcuts on IOS or Android
  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: true,
      descendantsAreFocusable: true,
      skipTraversal: false,
      focusNode: _focusNode,
      autofocus: false,
      //widget.hasFocus,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event.runtimeType == KeyDownEvent && node.hasPrimaryFocus) {
          LogicalKeyboardKey key = event.logicalKey;

          if (key == widget.showDismissKey) {
            toggleOverlay();
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.escape) {
            if (showingOverlay) {
              _hideOverlay();
            }
            return KeyEventResult.handled;
          } else {
            KeyAction? rep = _findMatch(event);
            if (rep != null) {
              rep.callback();
              return KeyEventResult.handled;
            } else {
              return KeyEventResult.ignored;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: FocusTraversalGroup(child: widget.child),
    );
  }

  void toggleOverlay() {
    setState(() {
      if (!showingOverlay) {
        showingOverlay = true;
        _overlayEntry = _buildOverlay();
        Overlay.of(context).insert(_overlayEntry);
      } else {
        if (showingOverlay) {
          _hideOverlay();
        }
      }
    });
  }

  void _hideOverlay() {
    setState(() {
      showingOverlay = false;
      _overlayEntry.remove();
      if (widget.callbackOnHide != null) {
        widget.callbackOnHide!();
      }
    });
  }
}

///A combination of a [LogicalKeyboardKey] (e.g., control-shift-A), a description
///of what action that keystroke should trigger (e.g., "select all text"),
///and a callback method to be invoked when that keystroke is pressed.
@immutable
class KeyAction {
  final SingleActivator keyActivator;
  final String description;
  final VoidCallback callback;
  final String? categoryHeader;

  ///Creates a KeystrokeRep with the given LogicalKeyboardKey [keyStroke],
  ///[description] and [callback] method. Includes optional bool values (defaulting
  ///to false) for key modifiers for meta [isMetaPressed], shift [isShiftPressed],
  ///alt [isAltPressed]
  KeyAction(LogicalKeyboardKey keyStroke, this.description, this.callback,
      {this.categoryHeader,
      bool isControlPressed = false,
      bool isMetaPressed = false,
      bool isShiftPressed = false,
      bool isAltPressed = false})
      : keyActivator = SingleActivator(keyStroke,
            control: isControlPressed,
            shift: isShiftPressed,
            alt: isAltPressed,
            meta: isMetaPressed);

  ///Creates a key action from the first letter of any string [string] with,
  ///[description] and [callback] method. Includes optional bool values (defaulting
  ///to false) for key modifiers for meta [isMetaPressed], shift [isShiftPressed],
  ///alt [isAltPressed]
  KeyAction.fromString(String string, this.description, this.callback,
      {this.categoryHeader,
      bool isControlPressed = false,
      bool isMetaPressed = false,
      bool isShiftPressed = false,
      bool isAltPressed = false})
      : keyActivator = SingleActivator(
            LogicalKeyboardKey(string.toLowerCase().codeUnitAt(0)),
            control: isControlPressed,
            shift: isShiftPressed,
            alt: isAltPressed,
            meta: isMetaPressed);

  bool get isControlPressed => keyActivator.control;

  bool get isMetaPressed => keyActivator.meta;

  bool get isShiftPressed => keyActivator.shift;

  bool get isAltPressed => keyActivator.alt;

  String get label {
    LogicalKeyboardKey key = keyActivator.trigger;
    String label = keyActivator.trigger.keyLabel;
    if (key == LogicalKeyboardKey.arrowRight) {
      if (kIsWeb) {
        label = 'arrow right';
      } else {
        label = '→';
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (kIsWeb) {
        label = 'arrow left';
      } else {
        label = '←';
      }
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (kIsWeb) {
        label = 'arrow up';
      } else {
        label = '↑';
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (kIsWeb) {
        label = 'arrow down';
      } else {
        label = '↓';
      }
    } else if (key == LogicalKeyboardKey.delete) {
      if (kIsWeb) {
        label = 'delete';
      } else {
        label = '\u232B';
      }
    }
    // else if (key == LogicalKeyboardKey.enter) {
    //   if (kIsWeb) {
    //     label = 'enter';
    //   }
    //   else {
    //     label = '\u2B90';
    //   }
    // }
    return label;
  }

  bool matchesEvent(KeyEvent event) {
    return event.logicalKey == keyActivator.trigger &&
        isControlPressed == HardwareKeyboard.instance.isControlPressed &&
        isMetaPressed == HardwareKeyboard.instance.isMetaPressed &&
        isShiftPressed == HardwareKeyboard.instance.isShiftPressed &&
        isAltPressed == HardwareKeyboard.instance.isAltPressed;
  }
}
