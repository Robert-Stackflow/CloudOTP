import 'package:flutter/material.dart';

class CustomDialogAnimations {
  static SlideTransition fromLeft(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        end: Offset.zero,
        begin: const Offset(1.0, 0.0),
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
      ),
      child: child,
    );
  }

  static SlideTransition fromRight(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        end: Offset.zero,
        begin: const Offset(-1.0, 0.0),
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
      ),
      child: child,
    );
  }

  static SlideTransition fromTop(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        end: Offset.zero,
        begin: const Offset(0.0, -1.0),
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
      ),
      child: child,
    );
  }

  static SlideTransition fromBottom(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        end: Offset.zero,
        begin: const Offset(0.0, 1.0),
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
      ),
      child: child,
    );
  }

  static ScaleTransition grow(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(end: 1.0, begin: 0.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(
            0.00,
            0.50,
            curve: Curves.linear,
          ),
        ),
      ),
      child: child,
    );
  }

  static ScaleTransition shrink(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(end: 1.0, begin: 1.2).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(
            0.50,
            1.00,
            curve: Curves.linear,
          ),
        ),
      ),
      child: child,
    );
  }
}
