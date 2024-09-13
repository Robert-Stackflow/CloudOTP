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

class AnimatedOverlay extends AnimatedWidget {
  final Color color;
  final Widget? child;
  final void Function()? onPress;

  const AnimatedOverlay({
    super.key,
    required Animation animation,
    required this.color,
    this.child,
    this.onPress,
  }) : super(listenable: animation);

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: animation.value == 0,
          child: InkWell(
            onTap: onPress,
            child: Container(
              color: color.withOpacity(animation.value * 0.5),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}
