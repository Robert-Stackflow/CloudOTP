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
  AutoBackupStatus status;
  AutoBackupType type;
  bool isAutoBackup;

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
        status = AutoBackupStatus.pending;

  factory AutoBackupLog.fromMap(Map<String, dynamic> map) {
    return AutoBackupLog(
      id: map['id'],
      startTimestamp: map['start_timestamp'],
      endTimestamp: map['end_timestamp'],
      status: AutoBackupStatus.values[map['status']],
      type: AutoBackupType.values[map['type']],
      isAutoBackup: map['is_auto_backup'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_timestamp': startTimestamp,
      'end_timestamp': endTimestamp,
      'status': status.index,
      'type': type.index,
      'is_auto_backup': isAutoBackup ? 1 : 0,
    };
  }
}
