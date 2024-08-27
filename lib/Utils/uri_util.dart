import 'package:cloudotp/Screens/webview_screen.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Widgets/Dialog/custom_dialog.dart';
import '../generated/l10n.dart';
import './ilogger.dart';

class UriUtil {
  static String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  static Future<bool> launchEmailUri(BuildContext context, String email,
      {String subject = "", String body = ""}) async {
    try {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: email,
        query: encodeQueryParameters(<String, String>{
          'subject': subject,
          'body': body,
        }),
      );
      if (!await launchUrl(
        emailLaunchUri,
      )) {
        Clipboard.setData(ClipboardData(text: email));
      }
    } catch (e, t) {
      ILogger.error("Failed to launch email app", e, t);
      IToast.showTop(S.current.noEmailClient);
    }
    return true;
  }

  static share(BuildContext context, String str) {
    Share.share(str).then((shareResult) {
      if (shareResult.status == ShareResultStatus.success) {
        IToast.showTop(S.current.shareSuccess);
      } else if (shareResult.status == ShareResultStatus.dismissed) {
        IToast.showTop(S.current.cancelShare);
      } else {
        IToast.showTop(S.current.shareFailed);
      }
    });
  }

  static void launchUrlUri(BuildContext context, String url) async {
    if (HiveUtil.getBool(HiveUtil.inappWebviewKey)) {
      openInternal(context, url);
    } else {
      openExternal(url);
    }
  }

  static Future<bool> canLaunchUri(Uri uri) async {
    return await canLaunchUrl(uri);
  }

  static void launchUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> processUrl(
    BuildContext context,
    String url, {
    bool pass = true,
    bool quiet = false,
  }) async {
    try {
      if (!quiet) CustomLoadingDialog.showLoading(title: S.current.loading);
      url = Uri.decodeComponent(url);
      if (!quiet) await CustomLoadingDialog.dismissLoading();
      if (!quiet) {
        if (pass) {
          if (HiveUtil.getBool(HiveUtil.inappWebviewKey, defaultValue: true)) {
            UriUtil.openInternal(context, url);
          } else {
            UriUtil.openExternal(url);
          }
        } else {
          IToast.showTop(S.current.notSupportedUri(url));
        }
      }
      return false;
    } catch (e, t) {
      ILogger.error("Failed to process url", e, t);
      if (!quiet) await CustomLoadingDialog.dismissLoading();
      if (!quiet) Share.share(url);
      return false;
    }
  }

  static void openInternal(
    BuildContext context,
    String url, {
    bool processUri = true,
  }) {
    if (ResponsiveUtil.isMobile()) {
      RouteUtil.pushCupertinoRoute(
          context, WebviewScreen(url: url, processUri: processUri));
    } else {
      openExternal(url);
    }
  }

  static Future<void> openExternal(String url) async {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalNonBrowserApplication,
    );
  }

  static Future<void> openExternalUri(Uri uri) async {
    await launchUrl(
      uri,
      mode: LaunchMode.externalNonBrowserApplication,
    );
  }
}
