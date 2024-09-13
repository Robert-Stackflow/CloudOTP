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

import 'package:cloudotp/Widgets/Shake/shake_animation_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 抖动动画效果的 Builder
class ShakeAnimationBuilder extends StatelessWidget {
  ///[child] 执行动画的组件
  ///[animation] 执行的动画
  ShakeAnimationBuilder({
    super.key,
    required this.child,
    required this.animation,
    this.randomValue = 5,
    this.shakeAnimationType = ShakeAnimationType.RoateShake,
  });

  ///执行动画的子Widget
  final Widget child;

  ///动画的定义
  final Animation<double> animation;

  ///抖动的类型
  final ShakeAnimationType shakeAnimationType;

  ///随机动画时使用构建随机数
  final Random random = Random();

  ///随机动画时抖动的波动范围
  final double randomValue;

  static double lastAnimationValue = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Transform(
          transform: buildMatrix4(),
          alignment: Alignment.center,
          child: this.child,
        );
      },
    );
  }

  Matrix4 buildMatrix4() {
    late Matrix4 result;
    if (shakeAnimationType == ShakeAnimationType.RoateShake) {
      result = Matrix4.rotationZ(animation.value);
    } else if (shakeAnimationType == ShakeAnimationType.RandomShake) {
      result = buildRandowMatrix4();
    } else {
      double dx = 0;
      double dy = 0;
      if (shakeAnimationType == ShakeAnimationType.LeftRightShake) {
        dx = animation.value * 15;
      } else if (shakeAnimationType == ShakeAnimationType.TopBottomShake) {
        dy = animation.value * 15;
      } else {
        dx = animation.value * 15;
        dy = animation.value * 15;
      }
      result = Matrix4.translationValues(dx, dy, 0);
    }
    if (lastAnimationValue == animation.value) {
      result = Matrix4.rotationZ(0);
    }
    lastAnimationValue = animation.value;
    return result;
  }

  ///构建随机变换的矩阵
  ///[animation.value]同时要适配旋转，
  ///[Matrix4]的旋转是使用弧度计算的，一般抖动使用 0.1左右的弧度微旋转即可
  ///所以这时配置的[animation.value]的取值范围建议使用 [-0.1,0.1]
  ///那么对于[Matrix4]的translationValues平移来讲是使用的逻辑像素
  ///   [-0.1,0.1]这个范围的变动对于平移无法有明显的抖动效果
  ///   所以在这里 对于平移来说使用的 [-1.5,1.5] 就会有明显一点的抖动效果
  ///[random.nextDouble()]这个方法的值范围为 [0.0-1.0]
  ///然后通过结合配置的[randomValue]抖动的波动范围 默认为 5
  /// [Matrix4]平移范围为 [-1.5,6.5]
  Matrix4 buildRandowMatrix4() {
    int nextRandom = random.nextInt(10);

    double dx = 0;
    double dy = 0;
    if (nextRandom % 4 == 0) {
      dx = animation.value * 15 + randomValue * random.nextDouble();
      return Matrix4.translationValues(dx, dy, 0);
    } else if (nextRandom % 4 == 1) {
      dy = animation.value * 15 + randomValue * random.nextDouble();
      return Matrix4.translationValues(dx, dy, 0);
    } else if (nextRandom % 4 == 2) {
      dx = animation.value * 15 + randomValue * random.nextDouble();
      dy = animation.value * 15 + randomValue * random.nextDouble();
      return Matrix4.translationValues(dx, dy, 0);
    } else {
      return Matrix4.rotationZ(animation.value);
    }
  }
}
