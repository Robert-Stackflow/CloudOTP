import 'dart:async';

import 'package:flutter/material.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class ToggleIconButton extends StatefulWidget {
  final Duration resetDuration;
  final Icon iconA;
  final Icon iconB;
  final String? tooltip;
  final VoidCallback? onPressed;

  const ToggleIconButton({
    super.key,
    this.tooltip,
    this.onPressed,
    this.resetDuration = const Duration(seconds: 2),
    this.iconA = const Icon(Icons.access_alarm),
    this.iconB = const Icon(Icons.access_time),
  });

  @override
  State<ToggleIconButton> createState() => _ToggleIconButtonState();
}

class _ToggleIconButtonState extends State<ToggleIconButton> {
  bool _isA = true;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handlePress() {
    widget.onPressed?.call();
    _timer?.cancel();
    setState(() => _isA = false);

    _timer = Timer(widget.resetDuration, () {
      if (mounted) {
        setState(() => _isA = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !_isA,
      child: PressableAnimation(
        onTap: _handlePress,
        child: HoverIconButton(
          tooltip: widget.tooltip,
          icon: _isA ? widget.iconA : widget.iconB,
          onPressed: _handlePress,
        ),
      ),
    );
  }
}
