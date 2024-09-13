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

import 'package:cloudotp/Widgets/Shake/shake_animation_builder.dart';
import 'package:cloudotp/Widgets/Shake/shake_animation_controller.dart';
import 'package:cloudotp/Widgets/Shake/shake_animation_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 抖动效果的组件
class ShakeAnimationWidget extends StatefulWidget {
  ///[child] 执行动画的组件
  final Widget child;

  ///抖动的范围配置
  final double shakeRange;

  ///抖动的类型
  final ShakeAnimationType shakeAnimationType;

  ///抖动次数 0 为无限抖动
  final int shakeCount;

  ///随机动画时抖动的波动范围
  final double randomValue;

  ///抖动动画控制器
  final ShakeAnimationController? shakeAnimationController;

  ///是否自动执行抖动
  final bool isForward;

  const ShakeAnimationWidget({
    super.key,
    required this.child,
    this.shakeRange = 0.1,
    this.shakeCount = 0,
    this.shakeAnimationType = ShakeAnimationType.RoateShake,
    this.shakeAnimationController,
    this.isForward = true,
    this.randomValue = 4,
  });

  @override
  State<StatefulWidget> createState() {
    return _ShakeAnimationState();
  }
}

class _ShakeAnimationState extends State<ShakeAnimationWidget>
    with SingleTickerProviderStateMixin {
  ///动画控制器
  late AnimationController _animationController;

  ///旋转弧度动画
  late Animation<double> _angleAnimation;

  ///抖动执行次数
  int _shakeTotalCount = 0;

  ///当前抖动执行次数
  int _shakeCurrentCount = 0;

  ///抖动的范围配置
  late double _shakeRange;

  @override
  void initState() {
    super.initState();

    ///抖动的执行次数
    _shakeTotalCount = widget.shakeCount;

    ///抖动的范围
    _shakeRange = widget.shakeRange;
    if (_shakeRange <= 0) {
      _shakeRange = 0;
    } else if (_shakeRange > 1.0) {
      _shakeRange = 1.0;
    }

    ///1、创建动画控制器
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);

    ///2、创建串行动画
    _angleAnimation = TweenSequence<double>([
      ///TweenSequenceItem来组合其他的Tween
      TweenSequenceItem<double>(
          tween: Tween(begin: 0, end: _shakeRange), weight: 1),
      TweenSequenceItem<double>(
          tween: Tween(begin: _shakeRange, end: 0), weight: 2),
      TweenSequenceItem<double>(
          tween: Tween(begin: 0, end: -_shakeRange), weight: 3),
      TweenSequenceItem<double>(
          tween: Tween(begin: -_shakeRange, end: 0), weight: 4),
    ]).animate(_animationController);

    ///----------------------------------------------------------------
    ///添加动画状态监听
    _angleAnimation.addStatusListener(statusListener);

    ///----------------------------------------------------------------
    ///添加动画控制器
    if (widget.shakeAnimationController != null) {
      ///参数一 isOpen 为true 是为打开动画
      ///参数二 shakeCount默认为1 执行一次抖动
      widget.shakeAnimationController!.setShakeListener(shakeListener);
    }
    if (widget.isForward) {
      ///正向执行
      _animationController.forward();
      if (widget.shakeAnimationController != null) {
        widget.shakeAnimationController!.animationRuning = true;
      }
    }
  }

  ///抖动动画控制器监听
  void shakeListener(isOpen, shakeCount) {
    _shakeCurrentCount = 0;

    if (isOpen) {
      ///赋值抖动次数
      _shakeTotalCount = shakeCount;
      _animationController.reset();
      _animationController.forward();
    } else {
      ///重置抖动次数
      _shakeTotalCount = widget.shakeCount;

      ///停止抖动动画
      _animationController.stop();
    }
  }

  ///动画执行状态监听
  void statusListener(status) {
    if (status == AnimationStatus.completed) {
      ///正向执行完毕后立刻反向执行（倒回去）
      _animationController.reverse();
    } else if (status == AnimationStatus.dismissed) {
      ///无次数限定执行
      if (_shakeTotalCount == 0) {
        ///反向执行完毕后立刻正向执行
        _animationController.forward();
      } else {
        ///有次数限定执行
        if (_shakeCurrentCount < _shakeTotalCount) {
          ///未执行够次数时继续执行
          _animationController.forward();
        } else {
          if (widget.shakeAnimationController != null) {
            widget.shakeAnimationController!.animationRuning = false;
          }
        }

        ///动画执行次数自增
        _shakeCurrentCount++;
      }
    }
  }

  @override
  void dispose() {
    ///销毁
    _animationController.dispose();
    if (widget.shakeAnimationController != null) {
      ///移动监听
      widget.shakeAnimationController!.removeListener();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShakeAnimationBuilder(
      //执行动画的Widget
      animation: _angleAnimation,
      //动画类型
      shakeAnimationType: widget.shakeAnimationType,
      //随机动画时抖动的波动范围
      randomValue: widget.randomValue,
      //执行动画的Widget
      child: widget.child,
    );
  }
}
