import 'dart:convert';

enum CloudServiceType {
  Webdav,
  GoogleDrive,
  OneDrive,
  Dropbox,
}

extension CloudServiceTypeExtension on CloudServiceType {
  String get name {
    switch (this) {
      case CloudServiceType.Webdav:
        return 'WebDAV';
      case CloudServiceType.GoogleDrive:
        return 'Google Drive';
      case CloudServiceType.OneDrive:
        return 'OneDrive';
      case CloudServiceType.Dropbox:
        return 'Dropbox';
    }
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
  int createTimestamp;
  int editTimestamp;
  int lastFetchTimestamp;
  int lastBackupTimestamp;
  Map<String, dynamic> remark;

  CloudServiceConfig({
    required this.id,
    required this.type,
    this.endpoint,
    this.account,
    this.secret,
    this.token,
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
    };
  }
}
