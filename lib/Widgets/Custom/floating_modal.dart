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

import 'dart:math';

import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:flutter/material.dart';

class FloatingModal extends StatelessWidget {
  final Widget child;
  final double? preferMinWidth;
  final bool useVerticalMargin;
  final bool useWideLandscape;

  const FloatingModal({
    super.key,
    required this.child,
    this.preferMinWidth,
    this.useWideLandscape = true,
    this.useVerticalMargin = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isLandScape = useWideLandscape
        ? ResponsiveUtil.isWideLandscape()
        : ResponsiveUtil.isLandscape();
    double width = MediaQuery.sizeOf(context).width - 60;
    double height = MediaQuery.sizeOf(context).height - 60;
    double preferWidth = min(width, preferMinWidth ?? 540);
    double preferHeight = min(width, 500);
    double preferHorizontalMargin = isLandScape
        ? width > preferWidth
            ? (width - preferWidth) / 2
            : 0
        : 0;
    double preferVerticalMargin =
        height > preferHeight ? (height - preferHeight) / 2 : 0;
    return Container(
      margin: EdgeInsets.only(
        left: preferHorizontalMargin,
        right: preferHorizontalMargin,
        top: useVerticalMargin
            ? preferVerticalMargin
            : ResponsiveUtil.isLandscape()
                ? 0
                : 100,
        bottom: useVerticalMargin ? preferVerticalMargin : 0,
      ),
      child: child,
    );
  }
}
