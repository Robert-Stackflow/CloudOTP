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

import 'package:cloudotp/Utils/lottie_util.dart';
import 'package:flutter/material.dart';

class LoadingDialogWidget extends StatefulWidget {
  final bool dismissible;

  final String? title;

  final double size;

  final double scale;

  const LoadingDialogWidget({
    super.key,
    this.dismissible = false,
    this.title,
    this.size = 40,
    this.scale = 1.0,
  });

  @override
  State<StatefulWidget> createState() => LoadingDialogWidgetState();
}

class LoadingDialogWidgetState extends State<LoadingDialogWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PopScope(
          canPop: widget.dismissible,
          onPopInvoked: (_) => Future.value(widget.dismissible),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).canvasColor,
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LottieUtil.load(
                  LottieUtil.getLoadingPath(context),
                  size: widget.size,
                  fit: BoxFit.fill,
                  scale: widget.scale * 1.8,
                ),
                if (widget.title != null) const SizedBox(height: 16),
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
