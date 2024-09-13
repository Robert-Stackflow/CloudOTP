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

///抖动监听
typedef ShakeAnimationListener = void Function(bool isOpen, int shakeCount);

///抖动动画控制器
class ShakeAnimationController {
  ///当前抖动动画的状态
  bool animationRuning = false;

  ///监听
  ShakeAnimationListener? _shakeAnimationListener;

  ///控制器中添加监听
  setShakeListener(ShakeAnimationListener listener) {
    _shakeAnimationListener = listener;
  }

  ///打开
  void start({int shakeCount = 1}) {
    if (_shakeAnimationListener != null) {
      animationRuning = true;
      _shakeAnimationListener!(true, shakeCount);
    }
  }

  ///关闭
  void stop() {
    if (_shakeAnimationListener != null) {
      animationRuning = false;
      _shakeAnimationListener!(false, 0);
    }
  }

  ///移除监听
  void removeListener() {
    _shakeAnimationListener = null;
  }
}
