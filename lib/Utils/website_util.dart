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

import 'package:flutter/cupertino.dart';

import 'constant.dart';

class WebsiteUtil {
  static String getPrivacyPolicyWebsite(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    if (websiteSupportLocales.contains(locale)) {
      return privacyPolicyWebsite + locale.languageCode;
    } else {
      return "${privacyPolicyWebsite}en";
    }
  }

  static String getServiceTermWebsite(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    if (websiteSupportLocales.contains(locale)) {
      return serviceTermWebsite + locale.languageCode;
    } else {
      return "${serviceTermWebsite}en";
    }
  }

  static String getDownloadsWebsite(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    if (websiteSupportLocales.contains(locale)) {
      return downloadsWebsite.replaceAll("{locale}", locale.toString());
    } else {
      return defaultDownloadsWebsite;
    }
  }
}
