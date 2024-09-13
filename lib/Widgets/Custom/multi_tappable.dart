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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MultiTapGestureDetector extends StatefulWidget {
  final Map<int, VoidCallback>? onNTap;
  final Function()? onTap;
  final Function()? onDoubleTap;
  final int tapThresholdMilliseconds;
  final bool haptic;
  final Widget child;

  const MultiTapGestureDetector({
    super.key,
    this.onNTap,
    this.tapThresholdMilliseconds = 200,
    this.haptic = false,
    required this.child,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<MultiTapGestureDetector> createState() =>
      _MultiTapGestureDetectorState();
}

class _MultiTapGestureDetectorState extends State<MultiTapGestureDetector> {
  int _taps = 0;
  Timer? _t;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _taps++;
        _t?.cancel();
        _t = Timer(Duration(milliseconds: widget.tapThresholdMilliseconds), () {
          if (widget.haptic) HapticFeedback.lightImpact();
          if (_taps == 1) {
            widget.onTap?.call();
          } else if (_taps == 1) {
            widget.onTap?.call();
          } else {
            widget.onNTap?[_taps]?.call();
          }
          _taps = 0;
        });
      },
      child: widget.child,
    );
  }
}
