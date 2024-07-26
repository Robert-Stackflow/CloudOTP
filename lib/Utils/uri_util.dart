import 'package:cloudotp/Screens/webview_screen.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Widgets/Dialog/custom_dialog.dart';
import 'iprint.dart';

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
    } on PlatformException catch (_) {
      IToast.showTop("尚未安装邮箱程序，已复制Email地址到剪贴板");
    }
    return true;
  }

  static share(BuildContext context, String str) {
    Share.share(str).then((shareResult) {
      if (shareResult.status == ShareResultStatus.success) {
        IToast.showTop("分享成功");
      } else if (shareResult.status == ShareResultStatus.dismissed) {
        IToast.showTop("取消分享");
      } else {
        IToast.showTop("分享失败");
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
      if (!quiet) CustomLoadingDialog.showLoading(title: "加载中...");
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
          IToast.showTop("不支持的URI：$url");
          IPrint.debug("不支持的URI：$url");
        }
      }
      return false;
    } catch (e) {
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

  static Future<void> openExternalUri(WebUri uri) async {
    await launchUrl(
      uri,
      mode: LaunchMode.externalNonBrowserApplication,
    );
  }

  static String getPostUrlByPermalink(String blogName, String permalink) {
    return "https://$blogName.lofter.com/post/$permalink";
  }

  static String getPostUrlById(String blogName, int postId, int blogId) {
    return "https://$blogName.lofter.com/post/${Utils.intToHex(blogId)}_${Utils.intToHex(postId)}";
  }

  static String getTagUrlByTagName(String tagName, {bool isNew = true}) {
    return "https://www.lofter.com/${isNew ? "front/blog/" : ""}tag/$tagName";
  }

  static String getCollectionUrlByCollectionInfo(
      String blogName, int collectionId) {
    return "https://www.lofter.com/collection/$blogName?op=collectionDetail&collectionId=$collectionId";
  }
}
