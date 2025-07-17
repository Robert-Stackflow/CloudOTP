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

import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cloudotp/l10n/l10n.dart';

import '../../Utils/shortcuts_util.dart';

class KeyboardWidget extends StatefulWidget {
  final bool hasFocus;
  final Widget title;

  final List<CloudOTPShortcut> bindings;

  final LogicalKeyboardKey showDismissKey;

  final int columnCount;
  final bool showMap;
  final VoidCallback? callbackOnHide;

  final Color? backgroundColor;

  final TextStyle? textStyle;

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

class KeyboardWidgetState extends BaseDynamicState<KeyboardWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
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

  Widget _buildMainBody() {
    TextStyle textStyle = widget.textStyle ?? ChewieTheme.bodyMedium;
    Color background =
        widget.backgroundColor ?? ChewieTheme.scaffoldBackgroundColor;
    Color textColor = textStyle.color ?? ChewieTheme.bodyMedium.color!;

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
                rep.labelProvider(appLocalizations),
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
                rep.labelProvider(appLocalizations),
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
    );

    Widget grid = Column(
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
                _hide();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: dataTable,
        ),
      ],
    );

    return GestureDetector(
      onTap: _hide,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
        ),
        child: grid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainBody();
  }

  void _hide() {
    setState(() {
      if (widget.callbackOnHide != null) {
        widget.callbackOnHide!();
      }
    });
    _focusNode.unfocus();
  }
}
