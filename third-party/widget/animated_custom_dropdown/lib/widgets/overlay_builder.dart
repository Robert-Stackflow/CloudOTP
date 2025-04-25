part of '../custom_dropdown.dart';

class _OverlayBuilder extends StatefulWidget {
  final Widget Function(Size, VoidCallback hide) overlay;
  final Widget Function(VoidCallback show) child;
  final OverlayPortalController? overlayPortalController;
  final Function(bool)? visibility;

  const _OverlayBuilder({
    required this.overlay,
    required this.child,
    this.overlayPortalController,
    this.visibility,
  });

  @override
  _OverlayBuilderState createState() => _OverlayBuilderState();
}

class _OverlayBuilderState extends State<_OverlayBuilder> {
  late OverlayPortalController overlayController;

  @override
  void initState() {
    super.initState();
    overlayController =
        widget.overlayPortalController ?? OverlayPortalController();
  }

  void showOverlay() {
    overlayController.show();

    if (widget.visibility != null) {
      widget.visibility!(true);
    }
  }

  void hideOverlay() {
    overlayController.hide();

    if (widget.visibility != null) {
      widget.visibility!(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: overlayController,
      overlayChildBuilder: (_) {
        final renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;
        return widget.overlay(size, hideOverlay);
      },
      child: widget.child(showOverlay),
    );
  }
}
