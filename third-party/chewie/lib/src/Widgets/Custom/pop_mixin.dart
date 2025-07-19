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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/cupertino.dart';

/// 页面如果需要拦截返回事件，实现这个接口
abstract class PopInterceptable {
  /// 如果返回 true，表示拦截成功，不再继续 pop
  Future<bool> onInterceptPop();
}

mixin PopInterceptMixin<T extends StatefulWidget> on BaseDynamicState<T>
    implements PopInterceptable {
  static final List<PopInterceptable> _activeInterceptors = [];

  @override
  void initState() {
    super.initState();
    _activeInterceptors.add(this);
  }

  @override
  void dispose() {
    _activeInterceptors.remove(this);
    super.dispose();
  }

  static List<PopInterceptable> get activeInterceptors =>
      List.unmodifiable(_activeInterceptors);
}
