import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/cupertino.dart';

class ErrorWidget extends StatefulWidget {
  final String? text;
  final String? buttonText;
  final Function()? onTap;

  const ErrorWidget({
    super.key,
    this.text,
    this.buttonText,
    this.onTap,
  });

  @override
  ErrorWidgetState createState() => ErrorWidgetState();
}

class ErrorWidgetState extends State<ErrorWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.text ?? chewieLocalizations.loadFailed,
            style: ChewieTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          RoundIconTextButton(
            text: widget.buttonText ?? chewieLocalizations.retry,
            onPressed: widget.onTap,
          ),
        ],
      ),
    );
  }
}
