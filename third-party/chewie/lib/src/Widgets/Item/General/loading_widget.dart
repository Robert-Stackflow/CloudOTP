import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:flutter/cupertino.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/l10n/l10n.dart';

class LoadingWidget extends StatefulWidget {
  final double size;
  final bool showText;
  final double topPadding;
  final double bottomPadding;
  final String? text;
  final bool forceDark;
  final Color? background;

  const LoadingWidget({
    super.key,
    this.size = 50,
    this.showText = true,
    this.topPadding = 0,
    this.bottomPadding = 100,
    this.text,
    this.forceDark = false,
    this.background,
  });

  @override
  LoadingWidgetState createState() => LoadingWidgetState();
}

class LoadingWidgetState extends State<LoadingWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        color: widget.background ?? ChewieTheme.cardColor.withAlpha(127),
        padding: EdgeInsets.only(
            top: widget.topPadding, bottom: widget.bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            chewieProvider.loadingWidgetBuilder(widget.size, widget.forceDark),
            if (widget.showText) const SizedBox(height: 10),
            if (widget.showText)
              Text(widget.text ?? chewieLocalizations.loading,
                  style: ChewieTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
