import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/System/hive_util.dart';
import 'package:awesome_chewie/src/Utils/System/route_util.dart';
import 'package:awesome_chewie/src/Utils/ilogger.dart';
import 'package:awesome_chewie/src/Utils/itoast.dart';
import 'package:awesome_chewie/src/Widgets/Dialog/custom_dialog.dart';
import 'package:awesome_chewie/src/l10n/l10n.dart';
import 'package:awesome_chewie/src/Screens/webview_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UriUtil {
  static final _urlRegex = RegExp(
    r"^https?://(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,63}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*$)",
    caseSensitive: false,
  );

  static bool isUrl(String url) => _urlRegex.hasMatch(url.trim());

  static String getDomainWithScheme(String url) {
    Uri uri = Uri.parse(url);
    return "${uri.scheme}://${uri.host}";
  }

  static String getRootDomainWithScheme(String url) {
    Uri uri = Uri.parse(url);
    return "${uri.scheme}://${uri.host.split('.').reversed.take(2).toList().reversed.join('.')}";
  }

  static Future<String?> fetchFavicon(String originUrl,
      {bool forceRoot = false}) async {
    try {
      debugPrint("Fetching favicon for $originUrl");
      var baseUrl = forceRoot
          ? getRootDomainWithScheme(originUrl)
          : getDomainWithScheme(originUrl);
      var uri = Uri.parse(baseUrl);

      var response = await http.get(uri);
      if (response.statusCode != 200) {
        debugPrint("Failed to fetch HTML for $originUrl");
      }

      var dom = parse(response.body);
      var links = dom.getElementsByTagName("link");
      String? faviconUrl;

      for (var link in links) {
        var rel = link.attributes["rel"];
        var href = link.attributes["href"];
        if (href != null && (rel == "icon" || rel == "shortcut icon")) {
          faviconUrl = href.startsWith("//")
              ? "${uri.scheme}:$href"
              : href.startsWith("/")
                  ? "$baseUrl$href"
                  : href;
          break;
        }
      }

      if (faviconUrl == null && !forceRoot) {
        faviconUrl = await fetchFavicon(originUrl, forceRoot: true);
      }

      faviconUrl ??= "$baseUrl/favicon.ico";

      if (await validateFavicon(faviconUrl)) {
        debugPrint("Favicon found for $originUrl: $faviconUrl");
        return faviconUrl;
      } else {
        debugPrint("Favicon not valid for $originUrl");
        return forceRoot
            ? null
            : await fetchFavicon(originUrl, forceRoot: true);
      }
    } catch (e, t) {
      debugPrint("Failed to fetch favicon for $originUrl \n $e $t");
      return null;
    }
  }

  static Future<bool> validateFavicon(String url) async {
    var flag = false;
    var uri = Uri.parse(url);
    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var contentType =
          result.headers["Content-Type"] ?? result.headers["content-type"];
      if (contentType != null && contentType.startsWith("image")) flag = true;
    }
    return flag;
  }

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
        mode: LaunchMode.externalApplication,
      )) {
        if (ResponsiveUtil.isIOS()) {
          IToast.showTop(chewieLocalizations.noEmailClient);
        }
        Clipboard.setData(ClipboardData(text: email));
      }
    } catch (e, t) {
      ILogger.error("Failed to launch email app", e, t);
      IToast.showTop(chewieLocalizations.noEmailClient);
    }
    return true;
  }

  static share(String str) {
    Share.share(str).then((shareResult) {
      if (shareResult.status == ShareResultStatus.success) {
        IToast.showTop(chewieLocalizations.shareSuccess);
      } else if (shareResult.status == ShareResultStatus.dismissed) {
        IToast.showTop(chewieLocalizations.cancelShare);
      } else {
        IToast.showTop(chewieLocalizations.shareFailed);
      }
    });
  }

  static void launchUrlUri(BuildContext context, String url) async {
    if (ChewieHiveUtil.getBool(ChewieHiveUtil.inappWebviewKey)) {
      openInternal(context, url);
    } else {
      openExternal(url);
    }
    // if (!await launchUrl(Uri.parse(url),
    //     mode: LaunchMode.externalApplication)) {
    //   Clipboard.setData(ClipboardData(text: url));
    // }
  }

  static Future<bool> canLaunchUri(Uri uri) async {
    return await canLaunchUrl(uri);
  }

  static void launchUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<Uri> getGooglePlayStoreUrl() async {
    String packageName = (await PackageInfo.fromPlatform()).packageName;
    final Uri playStoreUri =
        Uri.parse("https://play.google.com/store/apps/details?id=$packageName");
    return playStoreUri;
  }

  static Future<dynamic> getRedirectUrl(String url) async {
    Response res = await Dio().get(
      url,
      options: Options(
        headers: {
          "Connection": "keep-alive",
          "Referer": url,
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0",
        },
      ),
    );
    ILogger.info("Get Redirects: ${res.redirects}");
    if (res.redirects.isNotEmpty) {
      List<String> redirects =
          res.redirects.map((e) => e.location.toString()).toList();
      redirects = redirects.where((e) => !e.contains("front/login")).toList();
      if (redirects.isNotEmpty) url = redirects.last;
    } else {
      url = res.realUri.toString();
    }
    return url;
  }

  static Future<bool> processUrl(
    BuildContext context,
    String url, {
    bool pass = true,
    bool quiet = false,
  }) async {
    try {
      if (!quiet)
        CustomLoadingDialog.showLoading(title: chewieLocalizations.loading);
      try {
        url = Uri.decodeComponent(url);
      } catch (e) {}
      if (url == "") {
        return true;
      } else {
        if (!quiet) await CustomLoadingDialog.dismissLoading();
        if (!quiet) {
          if (pass) {
            if (ChewieHiveUtil.getBool(ChewieHiveUtil.inappWebviewKey,
                defaultValue: true)) {
              UriUtil.openInternal(context, url);
            } else {
              UriUtil.openExternal(url);
            }
          } else {
            IToast.showTop("不支持的URI：$url");
            ILogger.info("不支持的URI：$url");
          }
        }
        return false;
      }
    } catch (e, t) {
      ILogger.error("Failed to resolve url $url", e, t);
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
      RouteUtil.pushDialogRoute(
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
}
