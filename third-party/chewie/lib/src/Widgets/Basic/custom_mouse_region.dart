import 'package:flutter/cupertino.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class CustomMouseRegion extends StatefulWidget {
  final Widget child;

  const CustomMouseRegion({
    super.key,
    required this.child,
  });

  @override
  CustomMouseRegionState createState() => CustomMouseRegionState();
}

class CustomMouseRegionState extends State<CustomMouseRegion> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        chewieProvider.mousePosition = event.position;
      },
      child: GenericContextMenuOverlay(child: widget.child),
    );
  }
}
