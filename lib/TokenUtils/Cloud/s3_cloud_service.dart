import 'dart:typed_data';

import 'package:cloudotp/Models/s3_cloud_file_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:s3_storage/models.dart';
import 'package:s3_storage/s3_storage.dart';

import '../../Models/cloud_service_config.dart';
import '../../Utils/hive_util.dart';
import '../export_token_util.dart';
import 'cloud_service.dart';

class S3CloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.S3Cloud;
  static const String _s3CloudPath = 'CloudOTP';
  final CloudServiceConfig _config;
  late S3Storage s3Storage;
  late BuildContext context;
  Function(CloudServiceConfig)? onConfigChanged;

  String get bucket => _config.account!;

  String get accessKey => _config.token!;

  String get secretKey => _config.secret!;

  String? get region => _config.email;

  String get endpoint =>
      _config.endpoint!.replaceAll("https://", "").replaceAll("http://", "");

  S3CloudService(
    this._config, {
    this.onConfigChanged,
  }) {
    init();
  }

  @override
  Future<void> init() async {
    s3Storage = S3Storage(
      endPoint: endpoint,
      accessKey: accessKey,
      secretKey: secretKey,
      region: region,
    );
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    try {
      bool isAuthorized = await s3Storage.bucketExists(bucket);
      if (!isAuthorized) {
        return CloudServiceStatus.connectionError;
      } else {
        return CloudServiceStatus.success;
      }
    } catch (e) {
      return CloudServiceStatus.unknownError;
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      bool connected = await s3Storage.bucketExists(bucket);
      return connected;
    } catch (e, t) {
      print("$e $t");
      return false;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      await s3Storage.removeObject(
        bucket,
        path,
      );
      return true;
    } catch (e, t) {
      print("$e $t");
      return false;
    }
  }

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    try {
      maxCount ??= HiveUtil.getMaxBackupsCount();
      List<S3CloudFileInfo>? list = await listBackups();
      if (list == null) return false;
      list.sort((a, b) {
        return a.modifyTimestamp.compareTo(b.modifyTimestamp);
      });
      while (list.length > maxCount) {
        var file = list.removeAt(0);
        await deleteFile(file.path);
      }
      return true;
    } catch (e, t) {
      print("$e $t");
      return false;
    }
  }

  @override
  Future<Uint8List?> downloadFile(
    String path, {
    Function(int p1, int p2)? onProgress,
  }) async {
    try {
      StorageByteStream response = await s3Storage.getObject(
        bucket,
        path,
      );
      return await response.toBytes();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups())?.length ?? 0;
  }

  @override
  Future<List<S3CloudFileInfo>?> listBackups() async {
    var list = await listFiles();
    if (list == null) return null;
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.name))
        .toList();
    return list;
  }

  @override
  Future<List<S3CloudFileInfo>?> listFiles() async {
    try {
      ListObjectsResult res = await s3Storage.listAllObjects(
        bucket,
        prefix: _s3CloudPath,
        recursive: true,
      );
      List<S3CloudFileInfo> files = res.objects
          .map((e) => S3CloudFileInfo(
                id: e.eTag,
                path: e.key ?? "",
                name: (e.key ?? "").replaceAll("$_s3CloudPath/", ""),
                modifyTimestamp: e.lastModified?.millisecondsSinceEpoch ?? 0,
                size: e.size ?? 0,
                createTimestamp: e.lastModified?.millisecondsSinceEpoch ?? 0,
              ))
          .toList();
      return files;
    } catch (e, t) {
      print("$e\n$t");
      return null;
    }
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int p1, int p2)? onProgress,
  }) async {
    try {
      String response = await s3Storage.putObject(
          bucket, join(_s3CloudPath, fileName), Stream.value(fileData),
          onProgress: (bytes) {
        onProgress?.call(bytes, fileData.length);
      });
      deleteOldBackup();
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
