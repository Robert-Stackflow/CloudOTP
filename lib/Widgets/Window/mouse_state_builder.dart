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

import 'package:flutter/widgets.dart';

typedef MouseStateBuilderCB = Widget Function(
    BuildContext context, MouseState mouseState);

class MouseState {
  bool isMouseOver = false;
  bool isMouseDown = false;

  MouseState();

  @override
  String toString() {
    return "isMouseDown: ${this.isMouseDown} - isMouseOver: ${this.isMouseOver}";
  }
}

T? _ambiguate<T>(T? value) => value;

class MouseStateBuilder extends StatefulWidget {
  final MouseStateBuilderCB builder;
  final VoidCallback? onPressed;

  MouseStateBuilder({Key? key, required this.builder, this.onPressed})
      : super(key: key);

  @override
  _MouseStateBuilderState createState() => _MouseStateBuilderState();
}

class _MouseStateBuilderState extends State<MouseStateBuilder> {
  late MouseState _mouseState;

  _MouseStateBuilderState() {
    _mouseState = MouseState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (event) {
          setState(() {
            _mouseState.isMouseOver = true;
          });
        },
        onExit: (event) {
          setState(() {
            _mouseState.isMouseOver = false;
          });
        },
        child: GestureDetector(
            onTapDown: (_) {
              setState(() {
                _mouseState.isMouseDown = true;
              });
            },
            onTapCancel: () {
              setState(() {
                _mouseState.isMouseDown = false;
              });
            },
            onTap: () {
              setState(() {
                _mouseState.isMouseDown = false;
                _mouseState.isMouseOver = false;
              });
              _ambiguate(WidgetsBinding.instance)!.addPostFrameCallback((_) {
                if (widget.onPressed != null) {
                  widget.onPressed!();
                }
              });
            },
            onTapUp: (_) {},
            child: widget.builder(context, _mouseState)));
  }
}
