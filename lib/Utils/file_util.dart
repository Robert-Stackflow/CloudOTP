import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudotp/Models/github_response.dart';
import 'package:cloudotp/Utils/uri_util.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../Widgets/Item/item_builder.dart';
import 'iprint.dart';
import 'itoast.dart';
import 'notification_util.dart';

class FileUtil {
  static Future<String> getApplicationDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final appName = (await PackageInfo.fromPlatform()).appName;
    String path = '${dir.path}/$appName';
    Directory directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create();
    }
    return path;
  }

  static String extractFileNameFromUrl(String imageUrl) {
    return Uri.parse(imageUrl).pathSegments.last;
  }

  static String extractFileExtensionFromUrl(String imageUrl) {
    return extractFileNameFromUrl(imageUrl).split('.').last;
  }

  static Future<void> downloadAndUpdate(
    BuildContext context,
    String apkUrl,
    String htmlUrl, {
    String? version,
    bool isUpdate = true,
    Function(double)? onReceiveProgress,
  }) async {
    await Permission.storage.onDeniedCallback(() {
      IToast.showTop("请授予文件存储权限");
    }).onGrantedCallback(() async {
      if (Utils.isNotEmpty(apkUrl)) {
        double progressValue = 0.0;
        var appDocDir = await getTemporaryDirectory();
        String savePath =
            "${appDocDir.path}/${FileUtil.extractFileNameFromUrl(apkUrl)}";
        try {
          await Dio().download(
            apkUrl,
            savePath,
            onReceiveProgress: (count, total) {
              final value = count / total;
              if (progressValue != value) {
                if (progressValue < 1.0) {
                  progressValue = count / total;
                } else {
                  progressValue = 0.0;
                }
                NotificationUtil.sendProgressNotification(
                  0,
                  (progressValue * 100).toInt(),
                  title: isUpdate
                      ? '正在下载新版本安装包...'
                      : '正在下载版本${version ?? ""}的安装包...',
                  payload: version ?? "",
                );
                onReceiveProgress?.call(progressValue);
              }
            },
          ).then((response) async {
            if (response.statusCode == 200) {
              NotificationUtil.closeNotification(0);
              NotificationUtil.sendInfoNotification(
                1,
                "下载完成",
                isUpdate
                    ? "新版本安装包已经下载完成，点击立即安装"
                    : "版本${version ?? ""}的安装包已经下载完成，点击立即安装",
                payload: savePath,
              );
            } else {
              UriUtil.openExternal(htmlUrl);
            }
          });
        } catch (e) {
          IPrint.debug(e);
          NotificationUtil.closeNotification(0);
          NotificationUtil.sendInfoNotification(
            2,
            "下载失败，请重试",
            "新版本安装包下载失败，请重试",
          );
        }
      } else {
        UriUtil.openExternal(htmlUrl);
      }
    }).onPermanentlyDeniedCallback(() {
      IToast.showTop("已拒绝文件存储权限，将跳转到浏览器下载");
      UriUtil.openExternal(apkUrl);
    }).onRestrictedCallback(() {
      IToast.showTop("请授予文件存储权限");
    }).onLimitedCallback(() {
      IToast.showTop("请授予文件存储权限");
    }).onProvisionalCallback(() {
      IToast.showTop("请授予文件存储权限");
    }).request();
  }

  static Future<ShareResultStatus> shareImage(
    BuildContext context,
    String imageUrl, {
    bool showToast = true,
    String? message,
  }) async {
    CachedNetworkImage image =
        ItemBuilder.buildCachedImage(imageUrl: imageUrl, context: context);
    BaseCacheManager manager = image.cacheManager ?? DefaultCacheManager();
    Map<String, String> headers = image.httpHeaders ?? {};
    File file = await manager.getSingleFile(
      image.imageUrl,
      headers: headers,
    );
    final result = await Share.shareXFiles([XFile(file.path)], text: message);
    if (result.status == ShareResultStatus.success) {
      IToast.showTop("分享成功");
    } else if (result.status == ShareResultStatus.dismissed) {
      IToast.showTop("取消分享");
    } else {
      IToast.showTop("分享失败");
    }
    return result.status;
  }

  static Future<File> getImageFile(
    BuildContext context,
    String imageUrl, {
    bool showToast = true,
  }) async {
    CachedNetworkImage image =
        ItemBuilder.buildCachedImage(imageUrl: imageUrl, context: context);
    BaseCacheManager manager = image.cacheManager ?? DefaultCacheManager();
    Map<String, String> headers = image.httpHeaders ?? {};
    return await manager.getSingleFile(
      image.imageUrl,
      headers: headers,
    );
  }

  static Future<File> copyAndRenameFile(File file, String newFileName) async {
    String dir = file.parent.path;
    String newPath = '$dir/$newFileName';
    File copiedFile = await file.copy(newPath);
    await copiedFile.rename(newPath);
    return copiedFile;
  }

  static ReleaseAsset getAndroidAsset(ReleaseItem item) {
    return item.assets.firstWhere((element) =>
        element.contentType == "application/vnd.android.package-archive" &&
        element.name.endsWith(".zip"));
  }

  static ReleaseAsset getWindowsPortableAsset(ReleaseItem item) {
    return item.assets.firstWhere((element) =>
        element.contentType == "application/x-zip-compressed" &&
        element.name.endsWith(".zip"));
  }

  static ReleaseAsset getWindowsInstallerAsset(ReleaseItem item) {
    return item.assets.firstWhere((element) =>
        element.contentType == "application/x-msdownload" &&
        element.name.endsWith(".exe"));
  }
}
