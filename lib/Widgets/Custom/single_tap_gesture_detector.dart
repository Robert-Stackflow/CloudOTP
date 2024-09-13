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

import 'package:flutter/cupertino.dart';

typedef TapAction = void Function();

class SingleTapGestureDetector extends StatelessWidget {
  final Widget child; //子widget
  final TapAction? onValidTap; //有效点击回调
  final TapAction? onInvalidTap; //无效点击回调
  final Duration tapDuration; //防连点时间间隔
  DateTime? lastTapTime; //上次点击时间

  SingleTapGestureDetector({
    super.key,
    required this.child,
    this.onValidTap,
    this.tapDuration = const Duration(milliseconds: 100),
    this.onInvalidTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (lastTapTime == null ||
            DateTime.now().difference(lastTapTime!) > tapDuration) {
          lastTapTime = DateTime.now();
          onValidTap?.call();
        } else {
          onInvalidTap?.call();
        }
      },
      child: child,
    );
  }
}
