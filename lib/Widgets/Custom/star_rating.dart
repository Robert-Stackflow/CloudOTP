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

import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final int starCount;
  final double rating;
  final Color color;
  final Color borderColor;
  final double size;
  final bool readonly;
  final bool showFullOnly;
  final bool showRTL;
  final double spacing;
  final Function(double) onRatingChanged;

  const StarRating({
    super.key,
    this.starCount = 5,
    this.rating = 0.0,
    this.color = Colors.amber,
    this.borderColor = Colors.grey,
    this.size = 20,
    required this.onRatingChanged,
    this.readonly = true,
    this.showFullOnly = false,
    this.showRTL = false,
    this.spacing = 0.0,
  });

  @override
  StarRatingState createState() => StarRatingState();
}

class StarRatingState extends State<StarRating> {
  late double _currentRating = widget.rating;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildStar(BuildContext context, int index) {
    IconData iconData = Icons.star_border;
    Color iconColor = widget.borderColor;

    if (index < _currentRating.floor()) {
      iconData = Icons.star;
      iconColor = widget.color;
    } else if (index == _currentRating.floor() &&
        _currentRating - _currentRating.floor() > 0.0) {
      iconData = Icons.star_half;
      iconColor = widget.color;
    }

    return widget.showFullOnly && _currentRating <= index
        ? Container()
        : InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              if (!widget.readonly) {
                setState(() {
                  _currentRating = index + 1.0;
                });
                widget.onRatingChanged.call(_currentRating);
              }
            },
            child: Container(
              margin: widget.showRTL
                  ? EdgeInsets.only(left: widget.spacing)
                  : EdgeInsets.only(right: widget.spacing),
              child: Icon(
                iconData,
                color: iconColor,
                size: widget.size,
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          widget.showRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          widget.starCount, (index) => _buildStar(context, index)),
    );
  }
}
