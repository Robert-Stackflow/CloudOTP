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

import 'package:dio/dio.dart';

import '../Models/github_response.dart';
import '../Utils/ilogger.dart';

class GithubApi {
  static Future<List<ReleaseItem>> getReleases(String user, String repo) async {
    try {
      ILogger.info("CloudOTP","Getting releases for $user/$repo");
      final response =
          await Dio().get("https://api.github.com/repos/$user/$repo/releases");
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          final List<ReleaseItem> items =
              (data).map((e) => ReleaseItem.fromJson(e)).toList();
          return items;
        }
      }
    } catch (e, t) {
      ILogger.error("CloudOTP","Failed to get releases", e, t);
    }
    return [];
  }
}
