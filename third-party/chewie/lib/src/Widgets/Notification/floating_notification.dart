import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

enum NotificationType {
  normal,
  info,
  success,
  warning,
  error,
}

class NotificationStyle {
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final Color? iconColor;
  final BorderRadius borderRadius;
  final Border? border;
  final EdgeInsets padding;
  final bool enableBlur;
  final double blurSigma;
  final int blurAlpha;

  const NotificationStyle({
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.iconColor,
    this.borderRadius = ChewieDimens.borderRadius8,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.enableBlur = true,
    this.blurSigma = 4,
    this.blurAlpha = 200,
  });
}

class FloatingNotification extends StatefulWidget {
  final String? description;
  final String message;
  final Duration duration;
  final VoidCallback onDismissed;
  final NotificationStyle? style;
  final NotificationType type;

  const FloatingNotification({
    super.key,
    required this.description,
    required this.message,
    required this.duration,
    required this.onDismissed,
    required this.style,
    required this.type,
  });

  @override
  State<FloatingNotification> createState() => _FloatingNotificationState();
}

class _FloatingNotificationState extends State<FloatingNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _isDisposed = false;

  bool get hasDesc => widget.description?.notNullOrEmpty ?? false;

  bool _hovering = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();
    _startDismissTimer();
  }

  void _startDismissTimer() {
    _dismissTimer = Timer(widget.duration, () async {
      if (_isDisposed) return;
      await _controller.reverse();
      if (!_isDisposed) widget.onDismissed();
    });
  }

  void _cancelTimer() {
    _dismissTimer?.cancel();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelTimer();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<NotificationType, Color> defaultLightColors = {
      NotificationType.normal: ChewieTheme.scaffoldBackgroundColor,
      NotificationType.info: Colors.blue.shade50,
      NotificationType.success: Colors.green.shade50,
      NotificationType.warning: Colors.orange.shade50,
      NotificationType.error: Colors.red.shade50,
    };

    final Map<NotificationType, Color> defaultDarkColors = {
      NotificationType.normal: ChewieTheme.scaffoldBackgroundColor,
      NotificationType.info: Colors.blue.shade900.withOpacity(0.2),
      NotificationType.success: Colors.green.shade900.withOpacity(0.2),
      NotificationType.warning: Colors.orange.shade900.withOpacity(0.2),
      NotificationType.error: Colors.red.shade900.withOpacity(0.2),
    };

    final bool isDark = ColorUtil.isDark(context);

    final backgroundColor = widget.style?.backgroundColor ??
        (isDark
            ? defaultDarkColors[widget.type]!
            : defaultLightColors[widget.type]!);
    final textColor = widget.style?.textColor;

    final Map<NotificationType, IconData?> defaultIcons = {
      NotificationType.normal: null,
      NotificationType.info: LucideIcons.info,
      NotificationType.success: LucideIcons.circleCheck,
      NotificationType.warning: LucideIcons.triangleAlert,
      NotificationType.error: LucideIcons.circleX,
    };

    final IconData? icon = widget.style?.icon ?? defaultIcons[widget.type];

    Widget content = Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: ChewieTheme.defaultDecoration.copyWith(
        color: backgroundColor.withAlpha((widget.style?.enableBlur ?? false)
            ? (widget.style?.blurAlpha ?? 200)
            : 255),
        borderRadius: widget.style?.borderRadius ?? ChewieDimens.borderRadius8,
        border: widget.style?.border,
      ),
      child: Padding(
        padding: widget.style?.padding ?? EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      icon,
                      color: widget.style?.iconColor,
                      size: 20,
                    ),
                  ),
                Flexible(
                  child: Text(
                    widget.message,
                    style: ChewieTheme.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight:
                            hasDesc ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
              ],
            ),
            if (hasDesc) ...[
              const SizedBox(height: 8),
              Text(
                widget.description!,
                style: ChewieTheme.bodySmall.copyWith(color: textColor),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.style?.enableBlur ?? false) {
      content = ClipRRect(
        borderRadius: widget.style?.borderRadius ?? ChewieDimens.borderRadius8,
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: widget.style?.blurSigma ?? 4,
              sigmaY: widget.style?.blurSigma ?? 4),
          child: content,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) {
        _hovering = true;
        _cancelTimer();
      },
      onExit: (_) {
        if (!_isDisposed) _startDismissTimer();
      },
      child: Dismissible(
        key: widget.key!,
        direction: DismissDirection.startToEnd,
        onDismissed: (_) => widget.onDismissed(),
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: content,
          ),
        ),
      ),
    );
  }
}
