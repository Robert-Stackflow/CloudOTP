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

import 'dart:async';

import 'package:flutter/cupertino.dart';

class TimeText extends StatefulWidget {
  final DateTime date;
  final TextStyle style;

  const TimeText(this.date, {required this.style, super.key});

  @override
  TimeTextState createState() => TimeTextState();
}

class TimeTextState extends State<TimeText> {
  Timer? _timer;
  Duration? _duration;

  int diffMinutes() {
    final now = DateTime.now();
    return now.difference(widget.date).inMinutes;
  }

  @override
  void initState() {
    super.initState();
    updateTimer();
  }

  void updateTimer() {
    final diff = diffMinutes();
    Duration duration;
    if (diff < 60) {
      duration = const Duration(minutes: 1);
    } else if (diff < 60 * 24) {
      duration = Duration(minutes: 60 - diff % 60);
    } else {
      duration = Duration(minutes: (60 * 24) - diff % (60 * 24));
    }
    if (_duration == null || duration.compareTo(_duration!) != 0) {
      _duration = duration;
      var timer = _timer;
      if (timer != null) timer.cancel();
      timer = Timer.periodic(duration, (_) {
        if (mounted) setState(() {});
        updateTimer();
      });
    }
  }

  @override
  void dispose() {
    final timer = _timer;
    if (timer != null) timer.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TimeText oldWidget) {
    if (oldWidget.date.compareTo(widget.date) != 0) updateTimer();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final diff = diffMinutes();
    String label;
    if (diff < 60) {
      label = "${diff}m";
    } else if (diff < 60 * 24) {
      label = "${diff ~/ 60}h";
    } else {
      label = "${diff ~/ (60 * 24)}d";
    }
    return Text(label, style: widget.style);
  }
}
