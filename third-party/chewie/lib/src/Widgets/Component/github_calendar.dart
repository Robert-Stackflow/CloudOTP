import 'dart:math';

import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';

class GithubCalendar extends StatelessWidget {
  const GithubCalendar({
    super.key,
    required this.color,
    required this.data,
    this.initialColor = const Color.fromARGB(255, 235, 237, 240),
    this.boxSize = 12,
    this.boxPadding = 5,
    this.height = 119,
    this.style = const TextStyle(),
  });

  final Color color;

  final List<int> data;

  final Color initialColor;

  final double boxPadding;

  final double boxSize;

  final double height;

  final TextStyle style;

  final _monthsHeight = 15.0;

  final _days = const [
    'Mon',
    'Tues',
    'Wed',
    'Thur',
    'Fri',
    'Sat',
    'Sun',
  ];

  final _months = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final boxSizeAndPadding = boxSize + boxPadding;
    final now = DateTime.now();
    var days = now.weekday + 16 * 7;
    final dr = Duration(days: days);
    final yy = now.subtract(dr);
    final listM = <int>[];

    var lastM = yy.month;
    var lastP = 0;

    for (var i = 0; i <= 16; i++) {
      final cM = yy.add(Duration(days: 7 * i)).month;
      if (cM != lastM) {
        listM.add(i - lastP);
        lastP = i;
        lastM = cM;
      }
    }

    listM.add((now.day.toDouble() / 7).ceil());

    days = 0;
    for (var element in listM) {
      days += element;
    }
    days *= 7;

    return DefaultTextStyle(
      style: style,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 25,
            child: Column(
              children: <Widget>[
                SizedBox(height: _monthsHeight),
                SizedBox(
                    height: boxSizeAndPadding,
                    child: Text(_days[(now.weekday - 7 + 7) % 7])),
                SizedBox(height: boxSizeAndPadding * 2 + 2),
                SizedBox(
                    height: boxSizeAndPadding,
                    child: Text(_days[(now.weekday - 4 + 7) % 7])),
                SizedBox(height: boxSizeAndPadding * 2 + 2),
                SizedBox(
                    height: boxSizeAndPadding,
                    child: Text(_days[(now.weekday - 1 + 7) % 7])),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Row(
                  children: List.generate(
                    listM.length,
                    (index) {
                      final m = ((now.month - (listM.length - index)) % 12);
                      final int width =
                          listM[index] * boxSizeAndPadding.toInt();
                      return Container(
                        alignment: Alignment.centerLeft,
                        height: _monthsHeight,
                        width: width.toDouble() + 2.0,
                        child: Text(_months[m]),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: boxSizeAndPadding * 7,
                  child: SquareWall(
                    color: color,
                    initialColor: initialColor,
                    boxSize: boxSize,
                    days: days,
                    data: data,
                    max: data.reduce(max),
                    boxPadding: boxPadding,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SquareWall extends StatelessWidget {
  const SquareWall({
    super.key,
    required this.days,
    required this.initialColor,
    required this.boxSize,
    required this.boxPadding,
    required this.color,
    required this.data,
    required this.max,
  });

  final int days;
  final Color initialColor;
  final double boxSize;
  final double boxPadding;
  final Color color;
  final List<int> data;
  final int max;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      crossAxisSpacing: boxPadding,
      mainAxisSpacing: boxPadding,
      crossAxisCount: 7,
      children: List.generate(
        days,
        (index) {
          final curColor = index >= data.length
              ? initialColor
              : Color.lerp(initialColor, color, data[index] / max * 1.5);
          return Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              border: index == days - 1
                  ? Border.all(
                      color: ChewieTheme.primaryColor,
                      width: 1,
                      style: BorderStyle.solid)
                  : Border.all(style: BorderStyle.none),
              borderRadius: BorderRadius.circular(3),
              color: curColor,
            ),
          );
        },
      ),
    );
  }
}
