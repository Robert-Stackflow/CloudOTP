import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmptyPlaceholder extends StatelessWidget {
  final String text;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? scrollController;
  final Function()? onTap;
  final double size;
  final double topPadding;
  final double bottomPadding;

  const EmptyPlaceholder({
    super.key,
    required this.text,
    this.physics,
    this.shrinkWrap = true,
    this.scrollController,
    this.onTap,
    this.size = 30,
    this.topPadding = 50,
    this.bottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: physics,
      shrinkWrap: shrinkWrap,
      controller: scrollController,
      children: [
        SizedBox(height: topPadding),
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Icon(
              LucideIcons.inbox,
              size: size,
              color: ChewieTheme.labelLarge.color,
            ),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: ChewieTheme.labelLarge,
            ),
          ],
        ),
      ],
    );
  }
}
