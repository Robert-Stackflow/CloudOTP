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

/// A class that work as a enum. It overloads the operator `*` saving the double as a multiplier.
///
/// ```
/// PhotoViewComputedScale.contained * 2
/// ```
///
class PhotoViewComputedScale {
  const PhotoViewComputedScale._internal(this._value, [this.multiplier = 1.0]);

  final String _value;
  final double multiplier;

  @override
  String toString() => 'Enum.$_value';

  static const contained = PhotoViewComputedScale._internal('contained');
  static const covered = PhotoViewComputedScale._internal('covered');

  PhotoViewComputedScale operator *(double multiplier) {
    return PhotoViewComputedScale._internal(_value, multiplier);
  }

  PhotoViewComputedScale operator /(double divider) {
    return PhotoViewComputedScale._internal(_value, 1 / divider);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoViewComputedScale &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}
