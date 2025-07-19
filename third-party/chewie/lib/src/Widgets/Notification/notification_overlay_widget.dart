import 'package:flutter/material.dart';

import 'floating_notification.dart';
import 'notification_manager.dart';

class NotificationOverlayWidget extends StatefulWidget {
  const NotificationOverlayWidget({super.key});

  @override
  State<NotificationOverlayWidget> createState() =>
      NotificationOverlayWidgetState();
}

class NotificationOverlayWidgetState extends State<NotificationOverlayWidget> {
  final List<NotificationEntry> _notifications = [];

  void addNotification(NotificationEntry entry) {
    if (mounted) {
      setState(() {
        _notifications.add(entry);
      });
    }
  }

  void removeNotification(NotificationEntry entry) {
    if (mounted) {
      setState(() {
        _notifications.remove(entry);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    NotificationManager().attachOverlayState(this);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      right: 20,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _notifications.map((entry) {
            return Padding(
              key: entry.key,
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => removeNotification(entry),
                child: FloatingNotification(
                  key: entry.key,
                  description: entry.description,
                  message: entry.message,
                  duration: entry.duration,
                  style: entry.style,
                  type: entry.type,
                  onDismissed: () => removeNotification(entry),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
