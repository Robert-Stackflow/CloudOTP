import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:flutter/material.dart';

class AnimatedSidebarController extends ChangeNotifier {
  bool _isCollapsed = false;

  bool get isCollapsed => _isCollapsed;

  void toggle() {
    _isCollapsed = !_isCollapsed;
    notifyListeners();
  }

  void expand() {
    _isCollapsed = false;
    notifyListeners();
  }

  void collapse() {
    _isCollapsed = true;
    notifyListeners();
  }
}

class AnimatedSidebarContainer extends StatefulWidget {
  const AnimatedSidebarContainer({
    super.key,
    required this.sidebar,
    required this.content,
    this.collapsedWidth = 0,
    this.expandedWidth = 240,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    required this.controller,
  });

  final Widget sidebar;
  final Widget content;
  final double collapsedWidth;
  final double expandedWidth;
  final Duration duration;
  final Curve curve;
  final AnimatedSidebarController controller;

  @override
  State<AnimatedSidebarContainer> createState() =>
      _AnimatedSidebarContainerState();
}

class _AnimatedSidebarContainerState extends State<AnimatedSidebarContainer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCollapsed = widget.controller.isCollapsed;

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
              border: isCollapsed ? null : ChewieTheme.rightDivider),
          child: ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.centerLeft,
              widthFactor: isCollapsed ? 0.0 : 1.0,
              duration: widget.duration,
              curve: widget.curve,
              child: SizedBox(
                width: widget.expandedWidth,
                child: widget.sidebar,
              ),
            ),
          ),
        ),
        Expanded(child: widget.content),
      ],
    );
  }
}
