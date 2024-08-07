import 'dart:typed_data';

import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../Models/cloud_service_config.dart';
import 'cloud_service.dart';

enum CloudServiceStatus {
  success,
  connectionError,
  unauthorized,
  unknownError,
}

class WebDavCloudService extends CloudService {
  static const String _webdavPath = '/cloudotp';
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
    // CloudServiceStatus status = await ping();
    // if (status == CloudServiceStatus.success) {
    //   await client.mkdir(_webdavPath);
    // }
  }

  Future<CloudServiceStatus> ping() async {
    try {
      await client.ping();
      return CloudServiceStatus.success;
    } catch (e) {
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
  Future<dynamic> listFiles() async {
    var list = await client.readDir(_webdavPath);
    return list;
  }

  @override
  Future<dynamic> listBackups() async {
    var list = await listFiles();
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.path ?? ""))
        .toList();
    return list;
  }

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups()).length;
  }

  @override
  Future<void> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int, int)? onProgress,
  }) async {
    CancelToken c = CancelToken();
    await client.write(
      join(_webdavPath, fileName),
      fileData,
      onProgress: (c, t) {
        onProgress?.call(c, t);
      },
      cancelToken: c,
    );
    deleteOldBackup();
  }

  @override
  Future<Uint8List> downloadFile(
    String path, {
    Function(int, int)? onProgress,
  }) async {
    if (!path.startsWith(_webdavPath)) {
      path = join(_webdavPath, path);
    }
    return Uint8List.fromList(
      await client.read(
        path,
        onProgress: (c, t) {
          onProgress?.call(c, t);
        },
      ),
    );
  }

  @override
  Future<void> deleteFile(String path) async {
    if (!path.startsWith(_webdavPath)) {
      path = join(_webdavPath, path);
    }
    await client.remove(path);
  }

  @override
  Future<void> authenticate() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteOldBackup([int? maxCount]) async {
    maxCount ??= HiveUtil.getMaxBackupsCount();
    List<WebDavFile> list = await listBackups();
    list.sort((a, b) {
      if (a.mTime == null || b.mTime == null) return 0;
      return a.mTime!.compareTo(b.mTime!);
    });
    while (list.length > maxCount) {
      var file = list.removeAt(0);
      await deleteFile(file.path!);
    }
  }
}
