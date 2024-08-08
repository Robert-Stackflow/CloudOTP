import 'dart:convert';

import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Widgets/Custom/loading_icon.dart';

enum AutoBackupStatus {
  pending,
  encrypting,
  encryptFailed,
  saving,
  saveFailed,
  uploading,
  uploadFailed,
  success,
  failed,
}

enum AutoBackupType {
  local,
  cloud,
  localAndCloud,
}

class AutoBackupLog {
  int id;
  int startTimestamp;
  int endTimestamp;
  AutoBackupType type;
  bool isAutoBackup;
  Map<int, AutoBackupStatus> status;

  AutoBackupLog({
    required this.id,
    required this.startTimestamp,
    required this.endTimestamp,
    required this.status,
    required this.type,
    this.isAutoBackup = true,
  });

  AutoBackupLog.init({
    required this.type,
    this.isAutoBackup = true,
  })  : id = 0,
        startTimestamp = 0,
        endTimestamp = 0,
        status = {
          DateTime.now().millisecondsSinceEpoch: AutoBackupStatus.pending
        };

  addStatus(AutoBackupStatus status) {
    this.status[DateTime.now().millisecondsSinceEpoch] = status;
    switch (status) {
      case AutoBackupStatus.encrypting:
      case AutoBackupStatus.saving:
      case AutoBackupStatus.uploading:
        appProvider.autoBackupStatus = LoadingStatus.loading;
        break;
      case AutoBackupStatus.success:
        appProvider.autoBackupStatus = LoadingStatus.success;
      case AutoBackupStatus.failed:
        if (appProvider.autoBackupStatus == LoadingStatus.failed) {
          appProvider.autoBackupStatus = LoadingStatus.failedAndLoading;
        } else {
          appProvider.autoBackupStatus = LoadingStatus.failed;
        }
        break;
      default:
        break;
    }
  }

  factory AutoBackupLog.fromMap(Map<String, dynamic> map) {
    return AutoBackupLog(
      id: map['id'],
      startTimestamp: map['start_timestamp'],
      endTimestamp: map['end_timestamp'],
      status: jsonDecode(map['status'])
          .map((key, value) => MapEntry(key, AutoBackupStatus.values[value])),
      type: AutoBackupType.values[map['type']],
      isAutoBackup: map['is_auto_backup'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_timestamp': startTimestamp,
      'end_timestamp': endTimestamp,
      'status':
          jsonEncode(status.map((key, value) => MapEntry(key, value.index))),
      'type': type.index,
      'is_auto_backup': isAutoBackup ? 1 : 0,
    };
  }
}
