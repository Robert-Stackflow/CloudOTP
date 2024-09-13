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

import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:install_plugin/install_plugin.dart';

class NotificationUtil {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static init() async {
    if (ResponsiveUtil.isAndroid()) {
      await initAndroid();
    }
  }

  static initAndroid() async {
    var android = const AndroidInitializationSettings("@mipmap/ic_launcher");
    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (respose) async {
        if (respose.id == 1 && Utils.isNotEmpty(respose.payload)) {
          await InstallPlugin.install(respose.payload!);
        }
      },
    );
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> closeNotification(int id) async {
    if (ResponsiveUtil.isAndroid()) {
      return flutterLocalNotificationsPlugin.cancel(id);
    }
  }

  static Future<void> sendProgressNotification(
    int id,
    int progress, {
    String? title,
    String? payload,
  }) async {
    if (!ResponsiveUtil.isAndroid()) return;
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'progress channel',
      'progress channel',
      channelDescription: 'Notification channel for showing progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      '$progress%',
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<void> sendInfoNotification(
    int id,
    String title,
    String body, {
    String? payload,
  }) async {
    if (!ResponsiveUtil.isAndroid()) return;
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download complete channel',
      'download complete channel',
      channelDescription: 'Notification channel for showing download complete',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}

var notification = NotificationUtil();
