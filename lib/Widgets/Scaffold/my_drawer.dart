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

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

// Examples can assume:
// late BuildContext context;

// TODO(eseidel): Draw width should vary based on device size:
// https://material.io/design/components/navigation-drawer.html#specs

// Mobile:
// Width = Screen width − 56 dp
// Maximum width: 320dp
// Maximum width applies only when using a left nav. When using a right nav,
// the panel can cover the full width of the screen.

// Desktop/Tablet:
// Maximum width for a left nav is 400dp.
// The right nav can vary depending on content.

const double _kWidth = 304.0;
const double _kEdgeDragWidth = 20.0;
const double _kMinFlingVelocity = 365.0;
const Duration _kBaseSettleDuration = Duration(milliseconds: 246);

/// A Material Design panel that slides in horizontally from the edge of a
/// [Scaffold] to show navigation links in an application.
///
/// There is a Material 3 version of this component, [NavigationDrawer],
/// that's preferred for applications that are configured for Material 3
/// (see [ThemeData.useMaterial3]).
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=WRj86iHihgY}
///
/// Drawers are typically used with the [Scaffold.drawer] property. The child of
/// the drawer is usually a [ListView] whose first child is a [DrawerHeader]
/// that displays status information about the current user. The remaining
/// drawer children are often constructed with [ListTile]s, often concluding
/// with an [AboutListTile].
///
/// The [AppBar] automatically displays an appropriate [IconButton] to show the
/// [MyDrawer] when a [MyDrawer] is available in the [Scaffold]. The [Scaffold]
/// automatically handles the edge-swipe gesture to show the drawer.
///
/// {@animation 350 622 https://flutter.github.io/assets-for-api-docs/assets/material/drawer.mp4}
///
/// ## Updating to [NavigationDrawer]
///
/// There is a Material 3 version of this component, [NavigationDrawer],
/// that's preferred for applications that are configured for Material 3
/// (see [ThemeData.useMaterial3]). The [NavigationDrawer] widget's visual
/// are a little bit different, see the Material 3 spec at
/// <https://m3.material.io/components/navigation-drawer/overview> for
/// more details. While the [MyDrawer] widget can have only one child, the
/// [NavigationDrawer] widget can have list of widgets, which typically contains
/// [NavigationDrawerDestination] widgets and/or customized widgets like headlines
/// and dividers.
///
/// {@tool snippet}
/// This example shows how to create a [Scaffold] that contains an [AppBar] and
/// a [MyDrawer]. A user taps the "menu" icon in the [AppBar] to open the
/// [MyDrawer]. The [MyDrawer] displays four items: A header and three menu items.
/// The [MyDrawer] displays the four items using a [ListView], which allows the
/// user to scroll through the items if need be.
///
/// ```dart
/// Scaffold(
///   appBar: AppBar(
///     title: const Text('Drawer Demo'),
///   ),
///   drawer: Drawer(
///     child: ListView(
///       padding: EdgeInsets.zero,
///       children: const <Widget>[
///         DrawerHeader(
///           decoration: BoxDecoration(
///             color: Colors.blue,
///           ),
///           child: Text(
///             'Drawer Header',
///             style: TextStyle(
///               color: Colors.white,
///               fontSize: 24,
///             ),
///           ),
///         ),
///         ListTile(
///           leading: Icon(Icons.message),
///           title: Text('Messages'),
///         ),
///         ListTile(
///           leading: Icon(Icons.account_circle),
///           title: Text('Profile'),
///         ),
///         ListTile(
///           leading: Icon(Icons.settings),
///           title: Text('Settings'),
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// This example shows how to migrate the above [MyDrawer] to a [NavigationDrawer].
///
/// See code in examples/api/lib/material/navigation_drawer/navigation_drawer.1.dart **
/// {@end-tool}
///
/// An open drawer may be closed with a swipe to close gesture, pressing the
/// escape key, by tapping the scrim, or by calling pop route function such as
/// [Navigator.pop]. For example a drawer item might close the drawer when tapped:
///
/// ```dart
/// ListTile(
///   leading: const Icon(Icons.change_history),
///   title: const Text('Change history'),
///   onTap: () {
///     // change app state...
///     Navigator.pop(context); // close the drawer
///   },
/// );
/// ```
///
/// See also:
///
///  * [Scaffold.drawer], where one specifies a [MyDrawer] so that it can be
///    shown.
///  * [Scaffold.of], to obtain the current [ScaffoldState], which manages the
///    display and animation of the drawer.
///  * [ScaffoldState.openDrawer], which displays its [MyDrawer], if any.
///  * <https://material.io/design/components/navigation-drawer.html>
class MyDrawer extends StatelessWidget {
  /// Creates a Material Design drawer.
  ///
  /// Typically used in the [Scaffold.drawer] property.
  ///
  /// The [elevation] must be non-negative.
  const MyDrawer({
    super.key,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.width,
    this.child,
    this.semanticLabel,
    this.clipBehavior,
  }) : assert(elevation == null || elevation >= 0.0);

  /// Sets the color of the [Material] that holds all of the [MyDrawer]'s
  /// contents.
  ///
  /// If this is null, then [DrawerThemeData.backgroundColor] is used. If that
  /// is also null, then it falls back to [Material]'s default.
  final Color? backgroundColor;

  /// The z-coordinate at which to place this drawer relative to its parent.
  ///
  /// This controls the size of the shadow below the drawer.
  ///
  /// If this is null, then [DrawerThemeData.elevation] is used. If that
  /// is also null, then it defaults to 16.0.
  final double? elevation;

  /// The color used to paint a drop shadow under the drawer's [Material],
  /// which reflects the drawer's [elevation].
  ///
  /// If null and [ThemeData.useMaterial3] is true then no drop shadow will
  /// be rendered.
  ///
  /// If null and [ThemeData.useMaterial3] is false then it will default to
  /// [ThemeData.shadowColor].
  ///
  /// See also:
  ///   * [Material.shadowColor], which describes how the drop shadow is painted.
  ///   * [elevation], which affects how the drop shadow is painted.
  ///   * [surfaceTintColor], which can be used to indicate elevation through
  ///     tinting the background color.
  final Color? shadowColor;

  /// The color used as a surface tint overlay on the drawer's background color,
  /// which reflects the drawer's [elevation].
  ///
  /// If [ThemeData.useMaterial3] is false property has no effect.
  ///
  /// If null and [ThemeData.useMaterial3] is true then [ThemeData]'s
  /// [ColorScheme.surfaceTint] will be used.
  ///
  /// To disable this feature, set [surfaceTintColor] to [Colors.transparent].
  ///
  /// See also:
  ///   * [Material.surfaceTintColor], which describes how the surface tint will
  ///     be applied to the background color of the drawer.
  ///   * [elevation], which affects the opacity of the surface tint.
  ///   * [shadowColor], which can be used to indicate elevation through
  ///     a drop shadow.
  final Color? surfaceTintColor;

  /// The shape of the drawer.
  ///
  /// Defines the drawer's [Material.shape].
  ///
  /// If this is null, then [DrawerThemeData.shape] is used. If that
  /// is also null, then it falls back to [Material]'s default.
  final ShapeBorder? shape;

  /// The width of the drawer.
  ///
  /// If this is null, then [DrawerThemeData.width] is used. If that is also
  /// null, then it falls back to the Material spec's default (304.0).
  final double? width;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [SliverList].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// The semantic label of the drawer used by accessibility frameworks to
  /// announce screen transitions when the drawer is opened and closed.
  ///
  /// If this label is not provided, it will default to
  /// [MaterialLocalizations.drawerLabel].
  ///
  /// See also:
  ///
  ///  * [SemanticsConfiguration.namesRoute], for a description of how this
  ///    value is used.
  final String? semanticLabel;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// The [clipBehavior] argument specifies how to clip the drawer's [shape].
  ///
  /// If the drawer has a [shape], it defaults to [Clip.hardEdge]. Otherwise,
  /// defaults to [Clip.none].
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final DrawerThemeData drawerTheme = DrawerTheme.of(context);
    String? label = semanticLabel;
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        label = semanticLabel ?? MaterialLocalizations.of(context).drawerLabel;
    }
    final bool useMaterial3 = Theme.of(context).useMaterial3;
    final bool isDrawerStart =
        MyDrawerController.maybeOf(context)?.alignment != DrawerAlignment.end;
    final DrawerThemeData defaults =
        useMaterial3 ? _DrawerDefaultsM3(context) : _DrawerDefaultsM2(context);
    final ShapeBorder? effectiveShape = shape ??
        (isDrawerStart
            ? (drawerTheme.shape ?? defaults.shape)
            : (drawerTheme.endShape ?? defaults.endShape));
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: label,
      child: ConstrainedBox(
        constraints:
            BoxConstraints.expand(width: width ?? drawerTheme.width ?? _kWidth),
        child: Material(
          color: backgroundColor ??
              drawerTheme.backgroundColor ??
              defaults.backgroundColor,
          elevation: elevation ?? drawerTheme.elevation ?? defaults.elevation!,
          shadowColor:
              shadowColor ?? drawerTheme.shadowColor ?? defaults.shadowColor,
          surfaceTintColor: surfaceTintColor ??
              drawerTheme.surfaceTintColor ??
              defaults.surfaceTintColor,
          shape: effectiveShape,
          clipBehavior: effectiveShape != null
              ? (clipBehavior ?? Clip.hardEdge)
              : Clip.none,
          child: child,
        ),
      ),
    );
  }
}

class _DrawerControllerScope extends InheritedWidget {
  const _DrawerControllerScope({
    required this.controller,
    required super.child,
  });

  final MyDrawerController controller;

  @override
  bool updateShouldNotify(_DrawerControllerScope old) {
    return controller != old.controller;
  }
}

/// Provides interactive behavior for [MyDrawer] widgets.
///
/// Rarely used directly. Drawer controllers are typically created automatically
/// by [Scaffold] widgets.
///
/// The drawer controller provides the ability to open and close a drawer, either
/// via an animation or via user interaction. When closed, the drawer collapses
/// to a translucent gesture detector that can be used to listen for edge
/// swipes.
///
/// See also:
///
///  * [MyDrawer], a container with the default width of a drawer.
///  * [Scaffold.drawer], the [Scaffold] slot for showing a drawer.
class MyDrawerController extends StatefulWidget {
  /// Creates a controller for a [MyDrawer].
  ///
  /// Rarely used directly.
  ///
  /// The [child] argument must not be null and is typically a [MyDrawer].
  const MyDrawerController({
    GlobalKey? key,
    required this.child,
    required this.alignment,
    this.isDrawerOpen = false,
    this.drawerCallback,
    this.dragStartBehavior = DragStartBehavior.start,
    this.scrimColor,
    this.edgeDragWidth,
    this.customAnimationController,
    this.enableOpenDragGesture = true,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// Typically a [MyDrawer].
  final Widget child;

  final AnimationController? customAnimationController;

  /// The alignment of the [MyDrawer].
  ///
  /// This controls the direction in which the user should swipe to open and
  /// close the drawer.
  final DrawerAlignment alignment;

  /// Optional callback that is called when a [MyDrawer] is opened or closed.
  final DrawerCallback? drawerCallback;

  /// {@template flutter.material.DrawerController.dragStartBehavior}
  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], the drag behavior used for opening
  /// and closing a drawer will begin at the position where the drag gesture won
  /// the arena. If set to [DragStartBehavior.down] it will begin at the position
  /// where a down event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation scloudotpther and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for
  ///    the different behaviors.
  ///
  /// {@endtemplate}
  final DragStartBehavior dragStartBehavior;

  /// The color to use for the scrim that obscures the underlying content while
  /// a drawer is open.
  ///
  /// If this is null, then [DrawerThemeData.scrimColor] is used. If that
  /// is also null, then it defaults to [Colors.black54].
  final Color? scrimColor;

  /// Determines if the [MyDrawer] can be opened with a drag gesture.
  ///
  /// By default, the drag gesture is enabled.
  final bool enableOpenDragGesture;

  /// The width of the area within which a horizontal swipe will open the
  /// drawer.
  ///
  /// By default, the value used is 20.0 added to the padding edge of
  /// `MediaQuery.paddingOf(context)` that corresponds to [alignment].
  /// This ensures that the drag area for notched devices is not obscured. For
  /// example, if [alignment] is set to [DrawerAlignment.start] and
  /// `TextDirection.of(context)` is set to [TextDirection.ltr],
  /// 20.0 will be added to `MediaQuery.paddingOf(context).left`.
  final double? edgeDragWidth;

  /// Whether or not the drawer is opened or closed.
  ///
  /// This parameter is primarily used by the state restoration framework
  /// to restore the drawer's animation controller to the open or closed state
  /// depending on what was last saved to the target platform before the
  /// application was killed.
  final bool isDrawerOpen;

  /// The closest instance of [MyDrawerController] that encloses the given
  /// context, or null if none is found.
  ///
  /// {@tool snippet} Typical usage is as follows:
  ///
  /// ```dart
  /// DrawerController? controller = DrawerController.maybeOf(context);
  /// ```
  /// {@end-tool}
  ///
  /// Calling this method will create a dependency on the closest
  /// [MyDrawerController] in the [context], if there is one.
  ///
  /// See also:
  ///
  /// * [MyDrawerController.of], which is similar to this method, but asserts
  ///   if no [MyDrawerController] ancestor is found.
  static MyDrawerController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DrawerControllerScope>()
        ?.controller;
  }

  /// The closest instance of [MyDrawerController] that encloses the given
  /// context.
  ///
  /// If no instance is found, this method will assert in debug mode and throw
  /// an exception in release mode.
  ///
  /// Calling this method will create a dependency on the closest
  /// [MyDrawerController] in the [context].
  ///
  /// {@tool snippet} Typical usage is as follows:
  ///
  /// ```dart
  /// DrawerController controller = DrawerController.of(context);
  /// ```
  /// {@end-tool}
  static MyDrawerController of(BuildContext context) {
    final MyDrawerController? controller = maybeOf(context);
    assert(() {
      if (controller == null) {
        throw FlutterError(
          'DrawerController.of() was called with a context that does not '
          'contain a DrawerController widget.\n'
          'No DrawerController widget ancestor could be found starting from '
          'the context that was passed to DrawerController.of(). This can '
          'happen because you are using a widget that looks for a DrawerController '
          'ancestor, but no such ancestor exists.\n'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return controller!;
  }

  @override
  MyDrawerControllerState createState() => MyDrawerControllerState();
}

/// State for a [MyDrawerController].
///
/// Typically used by a [Scaffold] to [open] and [close] the drawer.
class MyDrawerControllerState extends State<MyDrawerController>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    if (widget.customAnimationController != null) {
      _controller = widget.customAnimationController!;
    } else {
      _controller = AnimationController(
        value: widget.isDrawerOpen ? 1.0 : 0.0,
        duration: _kBaseSettleDuration,
        vsync: this,
      );
    }
    _controller
      ..addListener(_animationChanged)
      ..addStatusListener(_animationStatusChanged);
  }

  @override
  void dispose() {
    _historyEntry?.remove();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrimColorTween = _buildScrimColorTween();
  }

  @override
  void didUpdateWidget(MyDrawerController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrimColor != oldWidget.scrimColor) {
      _scrimColorTween = _buildScrimColorTween();
    }
    if (widget.isDrawerOpen != oldWidget.isDrawerOpen) {
      switch (_controller.status) {
        case AnimationStatus.completed:
        case AnimationStatus.dismissed:
          _controller.value = widget.isDrawerOpen ? 1.0 : 0.0;
        case AnimationStatus.forward:
        case AnimationStatus.reverse:
          break;
      }
    }
  }

  void _animationChanged() {
    setState(() {
      // The animation controller's state is our build state, and it changed already.
    });
  }

  LocalHistoryEntry? _historyEntry;
  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  void _ensureHistoryEntry() {
    if (_historyEntry == null) {
      final ModalRoute<dynamic>? route = ModalRoute.of(context);
      if (route != null) {
        _historyEntry = LocalHistoryEntry(
            onRemove: _handleHistoryEntryRemoved,
            impliesAppBarDismissal: false);
        route.addLocalHistoryEntry(_historyEntry!);
        FocusScope.of(context).setFirstFocus(_focusScopeNode);
      }
    }
  }

  void _animationStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward:
        _ensureHistoryEntry();
      case AnimationStatus.reverse:
        _historyEntry?.remove();
        _historyEntry = null;
      case AnimationStatus.dismissed:
        break;
      case AnimationStatus.completed:
        break;
    }
  }

  void _handleHistoryEntryRemoved() {
    _historyEntry = null;
    close();
  }

  late AnimationController _controller;

  void _handleDragDown(DragDownDetails details) {
    _controller.stop();
    _ensureHistoryEntry();
  }

  void _handleDragCancel() {
    if (_controller.isDismissed || _controller.isAnimating) {
      return;
    }
    if (_controller.value < 0.5) {
      close();
    } else {
      open();
    }
  }

  final GlobalKey _drawerKey = GlobalKey();

  double get _width {
    final RenderBox? box =
        _drawerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.size.width;
    }
    return _kWidth; // drawer not being shown currently
  }

  bool _previouslyOpened = false;

  void _move(DragUpdateDetails details) {
    double delta = details.primaryDelta! / _width;
    switch (widget.alignment) {
      case DrawerAlignment.start:
        break;
      case DrawerAlignment.end:
        delta = -delta;
    }
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        _controller.value -= delta;
      case TextDirection.ltr:
        _controller.value += delta;
    }

    final bool opened = _controller.value > 0.5;
    if (opened != _previouslyOpened && widget.drawerCallback != null) {
      widget.drawerCallback!(opened);
    }
    _previouslyOpened = opened;
  }

  void _settle(DragEndDetails details) {
    if (_controller.isDismissed) {
      return;
    }
    if (details.velocity.pixelsPerSecond.dx.abs() >= _kMinFlingVelocity) {
      double visualVelocity = details.velocity.pixelsPerSecond.dx / _width;
      switch (widget.alignment) {
        case DrawerAlignment.start:
          break;
        case DrawerAlignment.end:
          visualVelocity = -visualVelocity;
      }
      switch (Directionality.of(context)) {
        case TextDirection.rtl:
          _controller.fling(velocity: -visualVelocity);
          widget.drawerCallback?.call(visualVelocity < 0.0);
        case TextDirection.ltr:
          _controller.fling(velocity: visualVelocity);
          widget.drawerCallback?.call(visualVelocity > 0.0);
      }
    } else if (_controller.value < 0.5) {
      close();
    } else {
      open();
    }
  }

  /// Starts an animation to open the drawer.
  ///
  /// Typically called by [ScaffoldState.openDrawer].
  void open() {
    _controller.fling();
    widget.drawerCallback?.call(true);
  }

  /// Starts an animation to close the drawer.
  void close() {
    _controller.fling(velocity: -1.0);
    widget.drawerCallback?.call(false);
  }

  late ColorTween _scrimColorTween;
  final GlobalKey _gestureDetectorKey = GlobalKey();

  ColorTween _buildScrimColorTween() {
    return ColorTween(
      begin: Colors.transparent,
      end: widget.scrimColor ??
          DrawerTheme.of(context).scrimColor ??
          Colors.black54,
    );
  }

  AlignmentDirectional get _drawerOuterAlignment {
    switch (widget.alignment) {
      case DrawerAlignment.start:
        return AlignmentDirectional.centerStart;
      case DrawerAlignment.end:
        return AlignmentDirectional.centerEnd;
    }
  }

  AlignmentDirectional get _drawerInnerAlignment {
    switch (widget.alignment) {
      case DrawerAlignment.start:
        return AlignmentDirectional.centerEnd;
      case DrawerAlignment.end:
        return AlignmentDirectional.centerStart;
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final bool drawerIsStart = widget.alignment == DrawerAlignment.start;
    final TextDirection textDirection = Directionality.of(context);
    final bool isDesktop;
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        isDesktop = false;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        isDesktop = true;
    }

    double? dragAreaWidth = widget.edgeDragWidth;
    if (widget.edgeDragWidth == null) {
      final EdgeInsets padding = MediaQuery.paddingOf(context);
      switch (textDirection) {
        case TextDirection.ltr:
          dragAreaWidth =
              _kEdgeDragWidth + (drawerIsStart ? padding.left : padding.right);
        case TextDirection.rtl:
          dragAreaWidth =
              _kEdgeDragWidth + (drawerIsStart ? padding.right : padding.left);
      }
    }

    if (_controller.status == AnimationStatus.dismissed) {
      if (widget.enableOpenDragGesture && !isDesktop) {
        return Align(
          alignment: _drawerOuterAlignment,
          child: GestureDetector(
            key: _gestureDetectorKey,
            onHorizontalDragUpdate: _move,
            onHorizontalDragEnd: _settle,
            behavior: HitTestBehavior.deferToChild,
            excludeFromSemantics: true,
            dragStartBehavior: widget.dragStartBehavior,
            child: Container(width: dragAreaWidth),
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    } else {
      final bool platformHasBackButton;
      switch (Theme.of(context).platform) {
        case TargetPlatform.android:
          platformHasBackButton = true;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          platformHasBackButton = false;
      }

      final Widget child = _DrawerControllerScope(
        controller: widget,
        child: RepaintBoundary(
          child: Stack(
            children: <Widget>[
              BlockSemantics(
                child: ExcludeSemantics(
                  // On Android, the back button is used to dismiss a modal.
                  excluding: platformHasBackButton,
                  child: GestureDetector(
                    onTap: close,
                    child: Semantics(
                      label: MaterialLocalizations.of(context)
                          .modalBarrierDismissLabel,
                      child: Container(
                        // The drawer's "scrim"
                        color: _scrimColorTween.evaluate(_controller),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: _drawerOuterAlignment,
                child: Align(
                  alignment: _drawerInnerAlignment,
                  widthFactor: _controller.value,
                  child: RepaintBoundary(
                    child: FocusScope(
                      key: _drawerKey,
                      node: _focusScopeNode,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (isDesktop) {
        return child;
      }

      return GestureDetector(
        key: _gestureDetectorKey,
        onHorizontalDragDown: _handleDragDown,
        onHorizontalDragUpdate: _move,
        onHorizontalDragEnd: _settle,
        onHorizontalDragCancel: _handleDragCancel,
        excludeFromSemantics: true,
        dragStartBehavior: widget.dragStartBehavior,
        child: child,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return ListTileTheme.merge(
      style: ListTileStyle.drawer,
      child: _buildDrawer(context),
    );
  }
}

class _DrawerDefaultsM2 extends DrawerThemeData {
  const _DrawerDefaultsM2(this.context) : super(elevation: 16.0);

  final BuildContext context;

  @override
  Color? get shadowColor => Theme.of(context).shadowColor;
}

// BEGIN GENERATED TOKEN PROPERTIES - Drawer

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _DrawerDefaultsM3 extends DrawerThemeData {
  _DrawerDefaultsM3(this.context) : super(elevation: 1.0);

  final BuildContext context;
  late final TextDirection direction = Directionality.of(context);

  @override
  Color? get backgroundColor => Theme.of(context).colorScheme.surface;

  @override
  Color? get surfaceTintColor => Theme.of(context).colorScheme.surfaceTint;

  @override
  Color? get shadowColor => Colors.transparent;

  // There isn't currently a token for this value, but it is shown in the spec,
  // so hard coding here for now.
  @override
  ShapeBorder? get shape => RoundedRectangleBorder(
        borderRadius: const BorderRadiusDirectional.horizontal(
          end: Radius.circular(16.0),
        ).resolve(direction),
      );

  // There isn't currently a token for this value, but it is shown in the spec,
  // so hard coding here for now.
  @override
  ShapeBorder? get endShape => RoundedRectangleBorder(
        borderRadius: const BorderRadiusDirectional.horizontal(
          start: Radius.circular(16.0),
        ).resolve(direction),
      );
}

// END GENERATED TOKEN PROPERTIES - Drawer
