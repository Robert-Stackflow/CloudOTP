/*
 * Copyright (c) 2025 Robert-Stackflow.
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

abstract class BaseDynamicState<T extends StatefulWidget> extends State<T> {
  Brightness? _oldBrightness;
  Locale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentBrightness = Theme.of(context).brightness;
    final currentLocale = Localizations.localeOf(context);
    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      onLocaleChanged(currentLocale);
      setState(() {});
    }
    if (_oldBrightness != currentBrightness) {
      _oldBrightness = currentBrightness;
      onBrightnessChanged(currentBrightness);
      setState(() {});
    }
  }

  @protected
  void onBrightnessChanged(Brightness newBrightness) {}

  @protected
  void onLocaleChanged(Locale newLocale) {}
}
