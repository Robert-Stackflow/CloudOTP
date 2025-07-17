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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/cupertino.dart';

class DialogNavigatorHelper {
  static BuildContext? navigatorContext;

  static void init(BuildContext context) {
    navigatorContext = context;
  }

  static void pushPage(Widget page) {
    if (isMounted()) {
      Navigator.of(navigatorContext!).push(RouteUtil.getFadeRoute(page));
    }
  }

  static void popPage() {
    if (isMounted()) {
      if (canPop()) {
        Navigator.of(navigatorContext!).pop();
      } else {
        Navigator.of(chewieProvider.rootContext).pop();
      }
    } else {
      Navigator.of(chewieProvider.rootContext).pop();
    }
  }

  static void responsivePopPage() {
    if (ResponsiveUtil.isLandscape()) {
      DialogNavigatorHelper.popPage();
    } else {
      Navigator.pop(chewieProvider.rootContext);
    }
  }

  static bool canPop() {
    if (isMounted()) {
      return Navigator.of(navigatorContext!).canPop();
    }
    return false;
  }

  static bool isMounted() {
    return navigatorContext != null && navigatorContext!.mounted;
  }
}
