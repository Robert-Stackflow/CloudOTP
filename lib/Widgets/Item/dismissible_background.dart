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

class DismissibleBackground extends StatelessWidget {
  final IconData icon;
  final bool isToRight;

  const DismissibleBackground(this.icon, this.isToRight, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              isToRight ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Icon(
              icon,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            )
          ],
        ),
      );
}
