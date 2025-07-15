/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:convert';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/TokenUtils/Cloud/googledrive_cloud_service.dart';

import '../TokenUtils/Cloud/aliyundrive_cloud_service.dart';
import '../TokenUtils/Cloud/box_cloud_service.dart';
import '../TokenUtils/Cloud/dropbox_cloud_service.dart';
import '../TokenUtils/Cloud/huawei_cloud_service.dart';
import '../TokenUtils/Cloud/onedrive_cloud_service.dart';
import '../TokenUtils/Cloud/s3_cloud_service.dart';
import '../TokenUtils/Cloud/webdav_cloud_service.dart';
import '../generated/l10n.dart';

enum CloudServiceType {
  Webdav,
  OneDrive,
  GoogleDrive,
  Dropbox,
  S3Cloud,
  HuaweiCloud,
  Box,
  AliyunDrive;

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
      case CloudServiceType.Box:
        return S.current.cloudTypeBox;
      case CloudServiceType.AliyunDrive:
        return S.current.cloudTypeAliyunDrive;
    }
  }

  static List<String> toStrings() {
    return CloudServiceType.values.map((e) => e.label).toList();
  }

  static List<String> toEnableStrings() {
    return [
      CloudServiceType.OneDrive.label,
      CloudServiceType.Dropbox.label,
      CloudServiceType.Webdav.label,
      CloudServiceType.S3Cloud.label,
      CloudServiceType.GoogleDrive.label,
      CloudServiceType.Box.label,
      CloudServiceType.AliyunDrive.label,
      CloudServiceType.HuaweiCloud.label,
    ];
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
      case 6:
        return CloudServiceType.Box;
      case 7:
        return CloudServiceType.AliyunDrive;
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
        return endpoint.notNullOrEmpty &&
            account.notNullOrEmpty &&
            secret.notNullOrEmpty;
      case CloudServiceType.GoogleDrive:
      case CloudServiceType.OneDrive:
      case CloudServiceType.Dropbox:
      case CloudServiceType.HuaweiCloud:
      case CloudServiceType.Box:
      case CloudServiceType.AliyunDrive:
        return configured;
      case CloudServiceType.S3Cloud:
        return endpoint.notNullOrEmpty &&
            account.notNullOrEmpty &&
            secret.notNullOrEmpty &&
            token.notNullOrEmpty;
    }
  }

  CloudService toCloudService() {
    switch (type) {
      case CloudServiceType.Webdav:
        return WebDavCloudService(this);
      case CloudServiceType.GoogleDrive:
        return GoogleDriveCloudService(this);
      case CloudServiceType.OneDrive:
        return OneDriveCloudService(this);
      case CloudServiceType.Dropbox:
        return DropboxCloudService(this);
      case CloudServiceType.HuaweiCloud:
        return HuaweiCloudService(this);
      case CloudServiceType.S3Cloud:
        return S3CloudService(this);
      case CloudServiceType.Box:
        return BoxCloudService(this);
      case CloudServiceType.AliyunDrive:
        return AliyunDriveCloudService(this);
    }
  }

  String get size {
    return totalSize < 0
        ? ""
        : '${CacheUtil.renderSize(usedSize.toDouble())}B / ${CacheUtil.renderSize(totalSize.toDouble())}B';
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
      "email": email ?? "",
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory CloudServiceConfig.fromJson(String source) {
    return CloudServiceConfig.fromMap(jsonDecode(source));
  }
}
