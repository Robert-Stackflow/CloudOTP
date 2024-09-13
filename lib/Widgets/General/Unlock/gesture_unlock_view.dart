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

import 'dart:async';

import 'package:flutter/material.dart';

import 'unlock_line_painter.dart';
import 'unlock_point.dart';
import 'unlock_point_painter.dart';

enum UnlockType { solid, hollow }

enum UnlockStatus { normal, success, failed, disable }

class GestureUnlockView extends StatefulWidget {
  final double size;

  final UnlockType type;

  final double padding;

  final double roundSpace;

  final double roundSpaceRatio;

  final Color defaultColor;

  final Color selectedColor;

  final Color failedColor;

  final Color disableColor;

  final double lineWidth;

  final double solidRadiusRatio;

  final double touchRadiusRatio;

  final int delayTime;

  final Function(List<int>, UnlockStatus) onCompleted;

  const GestureUnlockView({
    super.key,
    required this.size,
    this.type = UnlockType.solid,
    this.padding = 10,
    required this.roundSpace,
    this.roundSpaceRatio = 0.6,
    this.defaultColor = Colors.grey,
    this.selectedColor = Colors.blue,
    this.failedColor = Colors.red,
    this.disableColor = Colors.grey,
    this.lineWidth = 2,
    this.solidRadiusRatio = 0.4,
    this.touchRadiusRatio = 0.6,
    this.delayTime = 500,
    required this.onCompleted,
  });

  @override
  State<StatefulWidget> createState() => GestureState();

  static String selectedToString(List<int> rounds) {
    var sb = StringBuffer();
    for (int i = 0; i < rounds.length; i++) {
      sb.write(rounds[i] + 1);
    }
    return sb.toString();
  }
}

class GestureState extends State<GestureUnlockView> {
  UnlockStatus _status = UnlockStatus.normal;

  final List<UnlockPoint> points =
      List.filled(9, UnlockPoint(x: 0, y: 0, position: 0));

  final List<UnlockPoint> pathPoints = [];
  late UnlockPoint curPoint = UnlockPoint(x: 0, y: 0, position: 0);
  late double _radius;
  late double _solidRadius;
  late double _touchRadius;
  late Timer _timer = Timer(Duration(milliseconds: widget.delayTime), () {
    updateStatus(UnlockStatus.normal);
  });

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_timer.isActive == true) {
      _timer.cancel();
    }
  }

  void _init() {
    var width = widget.size;
    var roundSpace = widget.roundSpace;
    if (roundSpace != null) {
      _radius = (width - widget.padding * 2 - roundSpace * 2) / 3 / 2;
    } else {
      _radius =
          (width - widget.padding * 2) / (3 + widget.roundSpaceRatio * 2) / 2;
      roundSpace = _radius * 2 * widget.roundSpaceRatio;
    }

    _solidRadius = _radius * widget.solidRadiusRatio;
    _touchRadius = _radius * widget.touchRadiusRatio;

    for (int i = 0; i < points.length; i++) {
      var row = i ~/ 3;
      var column = i % 3;
      var dx = widget.padding + column * (_radius * 2 + roundSpace) + _radius;
      var dy = widget.padding + row * (_radius * 2 + roundSpace) + _radius;
      points[i] = UnlockPoint(x: dx, y: dy, position: i);
    }
  }

  @override
  Widget build(BuildContext context) {
    var enableTouch = _status == UnlockStatus.normal;
    return Stack(
      children: <Widget>[
        CustomPaint(
          size: Size(widget.size, widget.size),
          painter: UnlockPointPainter(
              type: widget.type,
              points: points,
              radius: _radius,
              solidRadius: _solidRadius,
              lineWidth: widget.lineWidth,
              defaultColor: widget.defaultColor,
              selectedColor: widget.selectedColor,
              failedColor: widget.failedColor,
              disableColor: widget.disableColor),
        ),
        GestureDetector(
          onPanDown: enableTouch ? _onPanDown : null,
          onPanUpdate: enableTouch
              ? (DragUpdateDetails e) => _onPanUpdate(e, context)
              : null,
          onPanEnd:
              enableTouch ? (DragEndDetails e) => _onPanEnd(e, context) : null,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: UnlockLinePainter(
                pathPoints: pathPoints,
                status: _status,
                selectColor: widget.selectedColor,
                failedColor: widget.failedColor,
                lineWidth: widget.lineWidth,
                curPoint: curPoint),
          ),
        )
      ],
    );
  }

  void updateStatus(UnlockStatus status) {
    _status = status;
    switch (status) {
      case UnlockStatus.normal:
      case UnlockStatus.disable:
        _updateRoundStatus(status);
        _clearAllData();
        break;
      case UnlockStatus.failed:
        for (UnlockPoint round in points) {
          if (round.status == UnlockStatus.success) {
            round.status = UnlockStatus.failed;
          }
        }
        _timer = Timer(Duration(milliseconds: widget.delayTime), () {
          updateStatus(UnlockStatus.normal);
        });
        break;
      case UnlockStatus.success:
        _timer = Timer(Duration(milliseconds: widget.delayTime), () {
          updateStatus(UnlockStatus.normal);
        });
        break;
    }
    setState(() {});
  }

  void _updateRoundStatus(UnlockStatus status) {
    for (UnlockPoint round in points) {
      round.status = status;
    }
  }

  void _onPanDown(DragDownDetails e) {
    _clearAllData();
//    if (this.onPanDown != null) this.onPanDown();
  }

  void _onPanUpdate(DragUpdateDetails e, BuildContext context) {
    RenderBox box = context.findRenderObject() as RenderBox;
    if (box == null) return;
    Offset offset = box.globalToLocal(e.globalPosition);
    _slideDealt(offset);
    setState(() {
      curPoint = UnlockPoint(x: offset.dx, y: offset.dy, position: -1);
    });
  }

  void _onPanEnd(DragEndDetails e, BuildContext context) {
    if (pathPoints.isNotEmpty) {
      setState(() {
        curPoint = pathPoints[pathPoints.length - 1];
      });
      List<int> items = pathPoints.map((item) => item.position).toList();
      widget.onCompleted(items, _status);
//      if (this.immediatelyClear) this._clearAllData(); //clear data
    }
  }

  ///滑动处理
  void _slideDealt(Offset offSet) {
    int xPosition = -1;
    int yPosition = -1;
    for (int i = 0; i < 3; i++) {
      if (xPosition == -1 &&
          points[i].x + _radius + _touchRadius >= offSet.dx &&
          offSet.dx >= points[i].x - _radius - _touchRadius) {
        xPosition = i;
      }
      if (yPosition == -1 &&
          points[i * 3].y + _radius + _touchRadius >= offSet.dy &&
          offSet.dy >= points[i * 3].y - _radius - _touchRadius) {
        yPosition = i;
      }
    }
    if (xPosition == -1 || yPosition == -1) return;
    int position = yPosition * 3 + xPosition;

    if (points[position].status != UnlockStatus.success) {
      points[position].status = UnlockStatus.success;
      pathPoints.add(points[position]);
    }

//    for (int i = 0; i < points.length; i++) {
//      var round = points[i];
//      if (round.status == UnlockStatus.normal &&
//          round.contains(offSet, _touchRadius)) {
//        round.status = UnlockStatus.success;
//        pathPoints.add(round);
//        break;
//      }
//    }
  }

  _clearAllData() {
    for (int i = 0; i < 9; i++) {
      points[i].status = UnlockStatus.normal;
    }
    pathPoints.clear();
    setState(() {});
  }
}
