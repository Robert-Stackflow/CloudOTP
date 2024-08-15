import 'dart:convert';

import '../generated/l10n.dart';

enum CloudServiceType {
  Webdav,
  OneDrive,
  GoogleDrive,
  Dropbox,
  S3Cloud;

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
      default:
        throw Exception('Invalid CloudServiceType');
    }
  }
}

class CloudServiceConfig {
  int id;
  CloudServiceType type;
  String? endpoint;
  String? account;
  String? secret;
  String? token;
  bool enabled;
  int createTimestamp;
  int editTimestamp;
  int lastFetchTimestamp;
  int lastBackupTimestamp;
  Map<String, dynamic> remark;
  bool connected = false;

  bool get isValid {
    switch (type) {
      case CloudServiceType.Webdav:
        return endpoint != null && account != null && secret != null;
      case CloudServiceType.GoogleDrive:
      case CloudServiceType.OneDrive:
      case CloudServiceType.Dropbox:
      case CloudServiceType.S3Cloud:
        return true;
    }
  }

  CloudServiceConfig({
    required this.id,
    required this.type,
    this.endpoint,
    this.account,
    this.secret,
    this.token,
    this.enabled = true,
    required this.createTimestamp,
    required this.editTimestamp,
    required this.lastFetchTimestamp,
    required this.lastBackupTimestamp,
    required this.remark,
  });

  CloudServiceConfig.init({
    required this.type,
    this.endpoint,
    this.account,
    this.secret,
    this.token,
  })  : id = 0,
        enabled = true,
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
      createTimestamp: map['create_timestamp'],
      editTimestamp: map['edit_timestamp'],
      lastFetchTimestamp: map['last_fetch_timestamp'],
      lastBackupTimestamp: map['last_backup_timestamp'],
      remark: jsonDecode(map['remark']),
      enabled: map['enabled'] == 1,
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
      'create_timestamp': createTimestamp,
      'edit_timestamp': editTimestamp,
      'last_fetch_timestamp': lastFetchTimestamp,
      'last_backup_timestamp': lastBackupTimestamp,
      'remark': jsonEncode(remark),
      'enabled': enabled ? 1 : 0,
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory CloudServiceConfig.fromJson(String source) {
    return CloudServiceConfig.fromMap(jsonDecode(source));
  }
}
