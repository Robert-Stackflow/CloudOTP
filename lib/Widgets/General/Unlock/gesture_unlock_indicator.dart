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

import './unlock_point.dart';
import 'gesture_unlock_view.dart';

class GestureUnlockIndicator extends StatefulWidget {
  ///控件大小
  final double size;

  ///圆之间的间距
  final double roundSpace;

  ///圆之间的间距比例(以圆直径作为基准)，[roundSpace]设置时无效
  final double roundSpaceRatio;

  ///线宽度
  final double strokeWidth;

  ///默认颜色
  final Color defaultColor;

  ///选中颜色
  final Color selectedColor;

  final GestureUnlockIndicatorState _state = GestureUnlockIndicatorState();

  GestureUnlockIndicator(
      {super.key,
      required this.size,
      required this.roundSpace,
      this.roundSpaceRatio = 0.5,
      this.strokeWidth = 1,
      this.defaultColor = Colors.grey,
      this.selectedColor = Colors.blue});

  void setSelectPoint(List<int> selected) {
    _state.setSelectPoint(selected);
  }

  @override
  GestureUnlockIndicatorState createState() {
    return _state;
  }
}

class GestureUnlockIndicatorState extends State<GestureUnlockIndicator> {
  final List<UnlockPoint> _rounds =
      List.filled(9, UnlockPoint(x: 0, y: 0, position: 0));
  late double _radius;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: Size(widget.size, widget.size),
        painter: LockPatternIndicatorPainter(
          _rounds,
          _radius,
          widget.strokeWidth,
          widget.defaultColor,
          widget.selectedColor,
        ));
  }

  void setSelectPoint(List<int> selected) {
    for (int i = 0; i < _rounds.length; i++) {
      _rounds[i].status =
          selected.contains(i) ? UnlockStatus.success : UnlockStatus.normal;
    }
  }

  void _init() {
    var width = widget.size;
    var roundSpace = widget.roundSpace;
    if (roundSpace != null) {
      _radius = (width - roundSpace * 2) / 3 / 2;
    } else {
      _radius = width / (3 + widget.roundSpaceRatio * 2) / 2;
      roundSpace = _radius * 2 * widget.roundSpaceRatio;
    }

    for (int i = 0; i < _rounds.length; i++) {
      var row = i ~/ 3;
      var column = i % 3;
      var dx = column * (_radius * 2 + roundSpace) + _radius;
      var dy = row * (_radius * 2 + roundSpace) + _radius;
      _rounds[i] = UnlockPoint(x: dx, y: dy, position: i);
    }
    setState(() {});
  }
}

class LockPatternIndicatorPainter extends CustomPainter {
  final List<UnlockPoint> _rounds;
  final double _radius;
  final double _strokeWidth;
  final Color _defaultColor;
  final Color _selectedColor;

  LockPatternIndicatorPainter(this._rounds, this._radius, this._strokeWidth,
      this._defaultColor, this._selectedColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (_radius == null) return;

    var paint = Paint();
    paint.strokeWidth = _strokeWidth;

    for (var round in _rounds) {
      switch (round.status) {
        case UnlockStatus.normal:
          paint.style = PaintingStyle.fill;
          paint.color = _defaultColor;
          canvas.drawCircle(round.toOffset(), _radius, paint);
          break;
        case UnlockStatus.success:
          paint.style = PaintingStyle.fill;
          paint.color = _selectedColor;
          canvas.drawCircle(round.toOffset(), _radius, paint);
          break;
        default:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
