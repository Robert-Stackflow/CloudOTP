import 'dart:math';
import 'dart:ui';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DialogWrapperWidget extends StatefulWidget {
  final Widget child;
  final double? preferMinWidth;
  final double? preferMinHeight;
  final bool showCloseButton;
  final bool fullScreen;
  final bool barrierDismissible;

  const DialogWrapperWidget({
    super.key,
    required this.child,
    this.preferMinWidth,
    this.preferMinHeight,
    this.showCloseButton = true,
    this.fullScreen = false,
    this.barrierDismissible = true,
  });

  @override
  State<StatefulWidget> createState() => DialogWrapperWidgetState();
}

class DialogWrapperWidgetState extends State<DialogWrapperWidget>
    with SingleTickerProviderStateMixin {
  bool canNavigatorPop = true;

  late AnimationController _shakingController;
  late Animation<double> _shakingAnimation;

  BorderRadius borderRadius = ChewieDimens.defaultBorderRadius;

  @override
  void initState() {
    super.initState();

    _shakingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _shakingAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 10.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: 10.0, end: -10.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: -10.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1),
    ]).animate(_shakingController);
  }

  @override
  void dispose() {
    _shakingController.dispose();
    super.dispose();
  }

  void _onBackgroundTap() {
    if (!_shakingController.isAnimating) {
      _shakingController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width - 60;
    double height = MediaQuery.sizeOf(context).height - 60;
    double preferWidth = min(width, widget.preferMinWidth ?? 800);
    double preferHeight = min(width, widget.preferMinHeight ?? 720);
    double preferHorizontalMargin =
        width > preferWidth ? (width - preferWidth) / 2 : 0;
    double preferVerticalMargin =
        height > preferHeight ? (height - preferHeight) / 2 : 0;
    preferHorizontalMargin = max(preferHorizontalMargin, 20);
    preferVerticalMargin = max(preferVerticalMargin, 80);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: GestureDetector(
        onTap: _onBackgroundTap,
        child: AnimatedBuilder(
          animation: _shakingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakingAnimation.value, 0),
              child: child,
            );
          },
          child: PopScope(
            canPop: !canNavigatorPop,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              setState(() {
                canNavigatorPop = DialogNavigatorHelper.canPop();
              });
              DialogNavigatorHelper.popPage();
            },
            child: Container(
              color: widget.barrierDismissible ? null : Colors.transparent,
              padding: widget.fullScreen
                  ? EdgeInsets.zero
                  : EdgeInsets.symmetric(
                      horizontal: preferHorizontalMargin,
                      vertical: preferVerticalMargin,
                    ),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    boxShadow: ChewieTheme.defaultBoxShadow,
                    border: widget.fullScreen ? null : ChewieTheme.border,
                  ),
                  child: ClipRRect(
                    borderRadius: widget.fullScreen
                        ? BorderRadius.circular(0)
                        : borderRadius,
                    child: Stack(
                      children: [
                        Navigator(
                          onGenerateRoute: (settings) {
                            return RouteUtil.getFadeRoute(
                              Builder(
                                builder: (context) {
                                  DialogNavigatorHelper.init(context);
                                  return widget.child;
                                },
                              ),
                            );
                          },
                        ),
                        if (widget.showCloseButton)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: ToolButton(
                              context: context,
                              buttonSize: const Size(32, 32),
                              icon: LucideIcons.x,
                              onPressed: () {
                                DialogNavigatorHelper.popPage();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
