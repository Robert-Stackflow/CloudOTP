import 'dart:convert';

import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/TokenUtils/Cloud/googledrive_cloud_service.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/cache_util.dart';

import '../TokenUtils/Cloud/dropbox_cloud_service.dart';
import '../TokenUtils/Cloud/huawei_cloud_service.dart';
import '../TokenUtils/Cloud/onedrive_cloud_service.dart';
import '../TokenUtils/Cloud/s3_cloud_service.dart';
import '../TokenUtils/Cloud/webdav_cloud_service.dart';
import '../Utils/utils.dart';
import '../generated/l10n.dart';

enum CloudServiceType {
  Webdav,
  OneDrive,
  GoogleDrive,
  Dropbox,
  S3Cloud,HuaweiCloud;

  String get label {
    switch (this) {
      case CloudServiceType.Webdav:
        return S.current.cloudTypeWebDav;
      case CloudServiceType.GoogleDrive:
        return S.current.cloudTypeGoogleDrive;
      case CloudServiceType.OneDrive:
        return S.current.cloudTypeOneDrive;
      case CloudServiceType.Dropbox:
        return S.current.cloudTypeDropbox;
      case CloudServiceType.S3Cloud:
        return S.current.cloudTypeS3Cloud;
      case CloudServiceType.HuaweiCloud:
        return S.current.cloudTypeHuaweiCloud;
    }
  }

  static List<String> toStrings() {
    return CloudServiceType.values.map((e) => e.label).toList();
  }
}

extension CloudServiceTypeExtensionOnint on int {
  CloudServiceType get toCloudServiceType {
    switch (this) {
      case 0:
        return CloudServiceType.Webdav;
      case 1:
        return CloudServiceType.GoogleDrive;
      case 2:
        return CloudServiceType.OneDrive;
      case 3:
        return CloudServiceType.Dropbox;
      case 4:
        return CloudServiceType.S3Cloud;
      case 5:
        return CloudServiceType.HuaweiCloud;
      default:
        throw Exception('Invalid CloudServiceType');
    }
  }
}

class CloudServiceConfig {
  int id;
  CloudServiceType type;
  String? endpoint;
  String? email; // email or region
  String? account; //account or bucket
  String? secret; //secret or secretKey
  String? token; //token or accessKey
  bool enabled;
  int totalSize;
  int usedSize;
  int remainingSize;
  int createTimestamp;
  int editTimestamp;
  int lastFetchTimestamp;
  int lastBackupTimestamp;
  Map<String, dynamic> remark;
  bool configured;
  bool connected = false;

  Future<bool> isValid() async {
    switch (type) {
      case CloudServiceType.Webdav:
        return Utils.isNotEmpty(endpoint) &&
            Utils.isNotEmpty(account) &&
            Utils.isNotEmpty(secret);
      case CloudServiceType.GoogleDrive:
      case CloudServiceType.OneDrive:
      case CloudServiceType.Dropbox:
      case CloudServiceType.HuaweiCloud:
        return configured;
      case CloudServiceType.S3Cloud:
        return Utils.isNotEmpty(endpoint) &&
            Utils.isNotEmpty(account) &&
            Utils.isNotEmpty(secret) &&
            Utils.isNotEmpty(token);
    }
  }

  CloudService toCloudService() {
    switch (type) {
      case CloudServiceType.Webdav:
        return WebDavCloudService(this);
      case CloudServiceType.GoogleDrive:
        return GoogleDriveCloudService(rootContext, this);
      case CloudServiceType.OneDrive:
        return OneDriveCloudService(rootContext, this);
      case CloudServiceType.Dropbox:
        return DropboxCloudService(rootContext, this);
      case CloudServiceType.HuaweiCloud:
        return HuaweiCloudService(rootContext, this);
      case CloudServiceType.S3Cloud:
        return S3CloudService(this);
    }
  }

  String get size {
    return totalSize < 0
        ? ""
        : '${CacheUtil.renderSize(usedSize.toDouble())}/${CacheUtil.renderSize(totalSize.toDouble())}';
  }

  CloudServiceConfig({
    required this.id,
    required this.type,
    this.endpoint,
    this.account,
    this.secret,
    this.token,
    this.email,
    this.enabled = true,
    this.configured = false,
    required this.createTimestamp,
    required this.editTimestamp,
    required this.lastFetchTimestamp,
    required this.lastBackupTimestamp,
    required this.remark,
    required this.totalSize,
    required this.usedSize,
    required this.remainingSize,
  });

  CloudServiceConfig.init({
    required this.type,
    this.endpoint,
    this.account,
    this.secret,
    this.token,
  })  : id = 0,
        enabled = true,
        totalSize = -1,
        usedSize = -1,
        email = "",
        remainingSize = -1,
        configured = false,
        createTimestamp = DateTime.now().millisecondsSinceEpoch,
        editTimestamp = DateTime.now().millisecondsSinceEpoch,
        lastFetchTimestamp = DateTime.now().millisecondsSinceEpoch,
        lastBackupTimestamp = DateTime.now().millisecondsSinceEpoch,
        remark = {};

  factory CloudServiceConfig.fromMap(Map<String, dynamic> map) {
    return CloudServiceConfig(
      id: map['id'],
      type: CloudServiceType.values[map['type']],
      endpoint: map['endpoint'],
      account: map['account'],
      secret: map['secret'],
      token: map['token'],
      email: map['email'],
      createTimestamp: map['create_timestamp'],
      editTimestamp: map['edit_timestamp'],
      lastFetchTimestamp: map['last_fetch_timestamp'],
      lastBackupTimestamp: map['last_backup_timestamp'],
      remark: jsonDecode(map['remark']),
      enabled: map['enabled'] == 1,
      totalSize: map['total_size'] ?? -1,
      remainingSize: map['remaining_size'] ?? -1,
      usedSize: map['used_size'] ?? -1,
      configured: map['configured'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'endpoint': endpoint,
      'account': account,
      'secret': secret,
      'token': token,
      'configured': configured ? 1 : 0,
      'create_timestamp': createTimestamp,
      'edit_timestamp': editTimestamp,
      'last_fetch_timestamp': lastFetchTimestamp,
      'last_backup_timestamp': lastBackupTimestamp,
      'remark': jsonEncode(remark),
      'enabled': enabled ? 1 : 0,
      'total_size': totalSize,
      'remaining_size': remainingSize,
      'used_size': usedSize,
      "email": email,
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory CloudServiceConfig.fromJson(String source) {
    return CloudServiceConfig.fromMap(jsonDecode(source));
  }
}
