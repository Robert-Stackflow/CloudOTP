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

import 'package:flutter/widgets.dart';

/// Data class that holds the attributes that are going to be passed to
/// [PhotoViewImageWrapper]'s [Hero].
class PhotoViewHeroAttributes {
  const PhotoViewHeroAttributes({
    required this.tag,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    this.transitionOnUserGestures = false,
  });

  /// Mirror to [Hero.tag]
  final Object tag;

  /// Mirror to [Hero.createRectTween]
  final CreateRectTween? createRectTween;

  /// Mirror to [Hero.flightShuttleBuilder]
  final HeroFlightShuttleBuilder? flightShuttleBuilder;

  /// Mirror to [Hero.placeholderBuilder]
  final HeroPlaceholderBuilder? placeholderBuilder;

  /// Mirror to [Hero.transitionOnUserGestures]
  final bool transitionOnUserGestures;
}
