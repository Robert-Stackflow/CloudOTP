library context_menus;

import 'package:flutter/material.dart';

import 'measured_size_widget.dart';

typedef AnimatedWidgetBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Widget child,
);

extension ContextMenuExtensions on BuildContext {
  GenericContextMenuOverlayState get genericContextMenuOverlay =>
      GenericContextMenuOverlay.of(this);
}

// The main overlay class which displays the menus and dismisses them when empty space is pressed.
// Can wrap your MaterialApp or be nested at any level of your widget tree.
// Shows a contextMenu and contextModal on top. Does not rely on Navigator.overlay, so you can place it around your Navigator,
class GenericContextMenuOverlay extends StatefulWidget {
  const GenericContextMenuOverlay({
    required this.child,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationBuilder,
    super.key,
  });

  final Widget child;

  final Duration animationDuration;

  final AnimatedWidgetBuilder? animationBuilder;

  @override
  GenericContextMenuOverlayState createState() =>
      GenericContextMenuOverlayState();

  static GenericContextMenuOverlayState of(BuildContext context) {
    final state = (context
            .dependOnInheritedWidgetOfExactType<_InheritedContextMenuOverlay>())
        ?.state;
    if (state == null) {
      throw ('No ContextMenuOverlay was found. Check that you have inserted a ContextMenuOverlay above your ContextMenuRegion in the widget tree.');
    }
    return state;
  }
}

class GenericContextMenuOverlayState extends State<GenericContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  Widget? _currentMenu;
  Size? _prevSize;
  Size _menuSize = Size.zero;
  Offset _mousePos = Offset.zero;

  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _opacityAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        _nullMenuIfOverlayWasResized(constraints);

        final screenWidth = constraints.biggest.width;
        final screenHeight = constraints.biggest.height;
        const double edgePadding = 10.0;

        double dx = 0, dy = 0;
        if (_mousePos.dx > (_prevSize?.width ?? 0) / 2) dx = -_menuSize.width;
        if (_mousePos.dy > (_prevSize?.height ?? 0) / 2) dy = -_menuSize.height;

        Offset menuPos = _mousePos + Offset(dx, dy);

        double finalX = menuPos.dx;
        double finalY = menuPos.dy;

        if (finalX < edgePadding) finalX = edgePadding;
        if (finalX + _menuSize.width > screenWidth - edgePadding) {
          finalX = screenWidth - _menuSize.width - edgePadding;
        }

        if (finalY < edgePadding) finalY = edgePadding;
        if (finalY + _menuSize.height > screenHeight - edgePadding) {
          finalY = screenHeight - _menuSize.height - edgePadding;
        }

        menuPos = Offset(finalX, finalY);

        Widget? menuToShow = _currentMenu;
        TextDirection? dir = Directionality.maybeOf(context);
        return Directionality(
          textDirection: dir ?? TextDirection.ltr,
          child: _InheritedContextMenuOverlay(
            state: this,
            child: ColoredBox(
              color: Colors.transparent,
              child: Listener(
                onPointerDown: (e) => _mousePos = e.localPosition,
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    widget.child,
                    if (menuToShow != null) ...[
                      Positioned.fill(
                          child: Container(color: Colors.transparent)),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (_) => hide(),
                        onTap: () => hide(),
                        onSecondaryTapDown: (_) => hide(),
                        child: Container(),
                      ),
                      Transform.translate(
                        offset: menuPos,
                        child: _buildMenuWithAnimation(
                            menuToShow, _handleMenuSizeChanged),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuWithAnimation(
      Widget menu, void Function(Size size) onChange) {
    if (widget.animationBuilder != null) {
      return widget.animationBuilder!(context, _opacityAnimation, menu);
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: MeasuredSizeWidget(
        key: ObjectKey(menu),
        onChange: onChange,
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: menu,
          ),
        ),
      ),
    );
  }

  void show(Widget child) {
    setState(() {
      _menuSize = Size.zero;
      _currentMenu = child;
    });
    _animationController.forward(from: 0.0);
  }

  void hide() {
    _animationController.reverse().then((_) {
      setState(() {
        _currentMenu = null;
      });
    });
  }

  void _handleMenuSizeChanged(Size value) => setState(() => _menuSize = value);

  void _nullMenuIfOverlayWasResized(BoxConstraints constraints) {
    final size = constraints.biggest;
    bool appWasResized = size != _prevSize;
    if (appWasResized) _currentMenu = null;
    _prevSize = size;
  }
}

class _InheritedContextMenuOverlay extends InheritedWidget {
  const _InheritedContextMenuOverlay({
    required super.child,
    required this.state,
  });

  final GenericContextMenuOverlayState state;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}
