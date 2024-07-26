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
