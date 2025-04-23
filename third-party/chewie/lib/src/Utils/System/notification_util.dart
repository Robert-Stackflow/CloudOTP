import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/General/string_util.dart';
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
        if (respose.id == 1 && respose.payload.notNullOrEmpty) {
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
