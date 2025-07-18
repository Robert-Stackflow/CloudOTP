/*
 * Copyright (c) 2025 Robert-Stackflow.
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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:window_manager/window_manager.dart';

abstract class BaseWindowState<T extends StatefulWidget>
    extends BaseDynamicState<T> with WindowListener {
  bool isMaximized = false;
  bool isStayOnTop = false;

  @override
  Future<void> onWindowResize() async {
    super.onWindowResize();
    windowManager.setMinimumSize(ChewieProvider.minimumWindowSize);
    ChewieHiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowResized() async {
    super.onWindowResized();
    ChewieHiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowMove() async {
    super.onWindowMove();
    ChewieHiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  Future<void> onWindowMoved() async {
    super.onWindowMoved();
    ChewieHiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  void onWindowMaximize() {
    windowManager.setMinimumSize(ChewieProvider.minimumWindowSize);
    setState(() {
      isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    windowManager.setMinimumSize(ChewieProvider.minimumWindowSize);
    setState(() {
      isMaximized = false;
    });
  }
}
