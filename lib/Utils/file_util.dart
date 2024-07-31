import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudotp/Models/github_response.dart';
import 'package:cloudotp/Utils/uri_util.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../Widgets/Item/item_builder.dart';
import '../generated/l10n.dart';
import 'iprint.dart';
import 'itoast.dart';
import 'notification_util.dart';

class FileUtil {
  static Future<String> getApplicationDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final appName = (await PackageInfo.fromPlatform()).appName;
    String path = join(dir.path, appName);
    Directory directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return path;
  }

  static Future<String> getBackupDir() async {
    Directory directory = Directory(join(await getApplicationDir(), "Backup" ));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<String> getScreenshotDir() async {
    Directory directory = Directory(join(await getApplicationDir(), "Screenshots"));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<String> getLogDir() async {
    Directory directory = Directory(join(await getApplicationDir(), "Log"));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<String> getHiveDir() async {
    Directory directory = Directory(join(await getApplicationDir(), "Hive"));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
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
    Function(double)? onReceiveProgress,
  }) async {
    await Permission.storage.onDeniedCallback(() {
      IToast.showTop(S.current.pleaseGrantFilePermission);
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
                  title: S.current.downloadingNewVersionPackage,
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
                S.current.downloadComplete,
                S.current.downloadSuccessClickToInstall,
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
            S.current.downloadFailedAndRetry,
            S.current.downloadFailedAndRetryTip,
          );
        }
      } else {
        UriUtil.openExternal(htmlUrl);
      }
    }).onPermanentlyDeniedCallback(() {
      IToast.showTop(S.current.hasRejectedFilePermission);
      UriUtil.openExternal(apkUrl);
    }).onRestrictedCallback(() {
      IToast.showTop(S.current.pleaseGrantFilePermission);
    }).onLimitedCallback(() {
      IToast.showTop(S.current.pleaseGrantFilePermission);
    }).onProvisionalCallback(() {
      IToast.showTop(S.current.pleaseGrantFilePermission);
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
    final shareResult =
        await Share.shareXFiles([XFile(file.path)], text: message);
    if (shareResult.status == ShareResultStatus.success) {
      IToast.showTop(S.current.shareSuccess);
    } else if (shareResult.status == ShareResultStatus.dismissed) {
      IToast.showTop(S.current.cancelShare);
    } else {
      IToast.showTop(S.current.shareFailed);
    }
    return shareResult.status;
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
