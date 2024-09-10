import 'dart:typed_data';

import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../Models/cloud_service_config.dart';
import '../../Utils/ilogger.dart';
import 'cloud_service.dart';

class WebDavCloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.Webdav;
  static const String _webdavPath = '/CloudOTP';
  final CloudServiceConfig _config;

  WebDavCloudService(this._config) {
    init();
  }

  Client? _client;

  bool get isInitialized => _client != null;

  Client get client {
    if (_client == null) init();
    return _client!;
  }

  @override
  Future<void> init() async {
    _client = newClient(
      _config.endpoint!,
      user: _config.account!,
      password: _config.secret!,
      debug: false,
    );
    client.setHeaders({'accept-charset': 'utf-8'});
    client.setConnectTimeout(8000);
    client.setSendTimeout(8000);
    client.setReceiveTimeout(8000);
    CloudServiceStatus status = await authenticate();
    if (status == CloudServiceStatus.success) {
      await client.mkdir(_webdavPath);
    }
  }

  @override
  Future<bool> isConnected() async {
    CloudServiceStatus status = await authenticate();
    return status == CloudServiceStatus.success;
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    try {
      await client.ping();
      return CloudServiceStatus.success;
    } catch (e, t) {
      ILogger.error("CloudOTP","Failed to authenticate webdav", e, t);
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.badCertificate:
          case DioExceptionType.connectionError:
            return CloudServiceStatus.connectionError;
          case DioExceptionType.badResponse:
            if (e.response!.statusCode == 401) {
              return CloudServiceStatus.unauthorized;
            } else {
              return CloudServiceStatus.connectionError;
            }
          default:
            break;
        }
      }
      return CloudServiceStatus.unknownError;
    }
  }

  @override
  Future<List<WebDavFileInfo>?> listFiles() async {
    try {
      var list = await client.readDir(_webdavPath);
      return list;
    } catch (e, t) {
      ILogger.error("CloudOTP","Failed to list file from webdav", e, t);
      return null;
    }
  }

  @override
  Future<List<WebDavFileInfo>?> listBackups() async {
    var list = await listFiles();
    if (list == null) return null;
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.path ?? ""))
        .toList();
    return list;
  }

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups())?.length ?? 0;
  }

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int, int)? onProgress,
  }) async {
    try {
      CancelToken c = CancelToken();
      double progress = 0;
      await client.write(
        join(_webdavPath, fileName),
        fileData,
        onProgress: (c, t) {
          onProgress?.call(c, t);
          progress = c / t;
        },
        cancelToken: c,
      );
      deleteOldBackup();
      if (progress >= 1) {
        return true;
      } else {
        return false;
      }
    } catch (e, t) {
      ILogger.error("CloudOTP","Failed to upload file to webdav", e, t);
      return false;
    }
  }

  @override
  Future<Uint8List?> downloadFile(
    String path, {
    Function(int, int)? onProgress,
  }) async {
    if (!path.startsWith(_webdavPath)) {
      path = join(_webdavPath, path);
    }
    try {
      return Uint8List.fromList(
        await client.read(
          path,
          onProgress: (c, t) {
            onProgress?.call(c, t);
          },
        ),
      );
    } catch (e, t) {
      ILogger.error("CloudOTP","Failed to download file from webdav", e, t);
      return null;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    if (!path.startsWith(_webdavPath)) {
      path = join(_webdavPath, path);
    }
    await client.remove(path);
    return true;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    maxCount ??= HiveUtil.getMaxBackupsCount();
    List<WebDavFileInfo>? list = await listBackups();
    if (list == null) return false;
    list.sort((a, b) {
      if (a.mTime == null || b.mTime == null) return 0;
      return a.mTime!.compareTo(b.mTime!);
    });
    while (list.length > maxCount) {
      var file = list.removeAt(0);
      await deleteFile(file.path!);
    }
    return true;
  }

  @override
  Future<bool> hasConfigured() async {
    return _config.isValid();
  }
}
