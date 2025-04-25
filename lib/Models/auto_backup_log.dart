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
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:flutter/material.dart';

import '../generated/l10n.dart';
import 'cloud_service_config.dart';

enum AutoBackupStatus {
  pending,
  encrypting,
  encryptFailed,
  encrpytSuccess,
  saving,
  saveFailed,
  saveSuccess,
  uploading,
  uploadFailed,
  uploadSuccess,
  complete,
  failed;

  bool get isCompleted {
    return this == AutoBackupStatus.complete ||
        this == AutoBackupStatus.failed ||
        this == AutoBackupStatus.saveFailed ||
        this == AutoBackupStatus.uploadFailed ||
        this == AutoBackupStatus.encryptFailed;
  }

  bool get isFailed {
    return this == AutoBackupStatus.failed ||
        this == AutoBackupStatus.saveFailed ||
        this == AutoBackupStatus.uploadFailed ||
        this == AutoBackupStatus.encryptFailed;
  }

  Color get color {
    switch (this) {
      case AutoBackupStatus.pending:
        return Colors.grey;
      case AutoBackupStatus.encrypting:
        return ChewieTheme.primaryColor;
      case AutoBackupStatus.encryptFailed:
        return Colors.red;
      case AutoBackupStatus.saving:
        return ChewieTheme.primaryColor;
      case AutoBackupStatus.saveFailed:
        return Colors.red;
      case AutoBackupStatus.uploading:
        return ChewieTheme.primaryColor;
      case AutoBackupStatus.uploadFailed:
        return Colors.red;
      case AutoBackupStatus.complete:
        return Colors.green;
      case AutoBackupStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

enum AutoBackupType {
  local,
  cloud,
  localAndCloud;

  String get label {
    switch (this) {
      case AutoBackupType.local:
        return S.current.backupToLocal;
      case AutoBackupType.cloud:
        return S.current.backupToCloud;
      case AutoBackupType.localAndCloud:
        return S.current.backupToLocalAndCloud;
    }
  }
}

enum AutoBackupTriggerType {
  manual,
  other,
  configInited,
  configUpdated,
  tokenInserted,
  tokensInserted,
  tokenUpdated,
  tokensUpdated,
  tokenDeleted,
  categoryInserted,
  categoriesInserted,
  categoryUpdated,
  categoriesUpdated,
  categoryDeleted,
  categoriesUpdatedForToken,
  cloudServiceConfigInserted,
  cloudServiceConfigUpdated,
  cloudServiceConfigDeleted;

  String get label {
    switch (this) {
      case AutoBackupTriggerType.manual:
        return S.current.triggerAutoBackupByManual;
      case AutoBackupTriggerType.other:
        return S.current.triggerAutoBackupByOther;
      case AutoBackupTriggerType.configInited:
        return S.current.triggerAutoBackupByConfigInited;
      case AutoBackupTriggerType.configUpdated:
        return S.current.triggerAutoBackupByConfigUpdated;
      case AutoBackupTriggerType.tokenInserted:
        return S.current.triggerAutoBackupByTokenInserted;
      case AutoBackupTriggerType.tokensInserted:
        return S.current.triggerAutoBackupByTokensInserted;
      case AutoBackupTriggerType.tokenUpdated:
        return S.current.triggerAutoBackupByTokenUpdated;
      case AutoBackupTriggerType.tokensUpdated:
        return S.current.triggerAutoBackupByTokensUpdated;
      case AutoBackupTriggerType.tokenDeleted:
        return S.current.triggerAutoBackupByTokenDeleted;
      case AutoBackupTriggerType.categoryInserted:
        return S.current.triggerAutoBackupByCategoryInserted;
      case AutoBackupTriggerType.categoriesInserted:
        return S.current.triggerAutoBackupByCategoriesInserted;
      case AutoBackupTriggerType.categoryUpdated:
        return S.current.triggerAutoBackupByCategoryUpdated;
      case AutoBackupTriggerType.categoriesUpdated:
        return S.current.triggerAutoBackupByCategoriesUpdated;
      case AutoBackupTriggerType.categoryDeleted:
        return S.current.triggerAutoBackupByCategoryDeleted;
      case AutoBackupTriggerType.categoriesUpdatedForToken:
        return S.current.triggerAutoBackupByCategoriesUpdatedForToken;
      case AutoBackupTriggerType.cloudServiceConfigInserted:
        return S.current.triggerAutoBackupByCloudServiceConfigInserted;
      case AutoBackupTriggerType.cloudServiceConfigUpdated:
        return S.current.triggerAutoBackupByCloudServiceConfigUpdated;
      case AutoBackupTriggerType.cloudServiceConfigDeleted:
        return S.current.triggerAutoBackupByCloudServiceConfigDeleted;
      default:
        return S.current.triggerAutoBackupByOther;
    }
  }
}

class AutoBackupLog {
  int id;
  int startTimestamp;
  int endTimestamp;
  AutoBackupType type;
  List<AutoBackupLogStatusItem> status;
  AutoBackupTriggerType triggerType;
  String backupPath;

  AutoBackupLogStatusItem get lastStatusItem {
    return status.last;
  }

  AutoBackupStatus get lastStatus {
    return lastStatusItem.status;
  }

  AutoBackupLog({
    required this.id,
    required this.startTimestamp,
    required this.endTimestamp,
    required this.status,
    required this.type,
    required this.backupPath,
    this.triggerType = AutoBackupTriggerType.manual,
  });

  AutoBackupLog.init({
    required this.type,
    required this.triggerType,
  })  : id = 0,
        startTimestamp = DateTime.now().millisecondsSinceEpoch,
        endTimestamp = 0,
        backupPath = "",
        status = [
          AutoBackupLogStatusItem(
            status: AutoBackupStatus.pending,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            remark: "",
          )
        ];

  bool get haveFailed {
    return status.any((element) => element.status.isFailed);
  }

  addStatus(
    AutoBackupStatus status, {
    CloudServiceType? type,
  }) {
    this.status.add(AutoBackupLogStatusItem(
          status: status,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          cloudServiceType: type,
          remark: '',
        ));
    switch (status) {
      case AutoBackupStatus.encrypting:
      case AutoBackupStatus.saving:
      case AutoBackupStatus.uploading:
        appProvider.autoBackupLoadingStatus = LoadingStatus.loading;
        break;
      case AutoBackupStatus.complete:
        appProvider.autoBackupLoadingStatus = LoadingStatus.success;
      case AutoBackupStatus.uploadFailed:
      case AutoBackupStatus.saveFailed:
      case AutoBackupStatus.encryptFailed:
      case AutoBackupStatus.failed:
        if (appProvider.autoBackupLoadingStatus == LoadingStatus.failed) {
          appProvider.autoBackupLoadingStatus = LoadingStatus.failedAndLoading;
        } else {
          appProvider.autoBackupLoadingStatus = LoadingStatus.failed;
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
          .map<AutoBackupLogStatusItem>(
              (e) => AutoBackupLogStatusItem.fromMap(e))
          .toList(),
      type: AutoBackupType.values[map['type']],
      triggerType: AutoBackupTriggerType.values[map['trigger_type']],
      backupPath: map['backup_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_timestamp': startTimestamp,
      'end_timestamp': endTimestamp,
      'status': jsonEncode(
        status.map((e) => e.toMap()).toList(),
      ),
      'type': type.index,
      'trigger_type': triggerType.index,
      'backup_path': backupPath,
    };
  }
}

class AutoBackupLogStatusItem {
  final AutoBackupStatus status;
  final int timestamp;
  final String remark;
  final CloudServiceType? cloudServiceType;

  AutoBackupLogStatusItem({
    required this.status,
    required this.timestamp,
    required this.remark,
    this.cloudServiceType,
  });

  factory AutoBackupLogStatusItem.fromMap(Map<String, dynamic> map) {
    return AutoBackupLogStatusItem(
      status: AutoBackupStatus.values[map['status']],
      timestamp: map['timestamp'],
      remark: map['remark'],
      cloudServiceType: map['cloud_service_type'] == null
          ? null
          : CloudServiceType.values[map['cloud_service_type']],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.index,
      'timestamp': timestamp,
      'remark': remark,
      'cloud_service_type': cloudServiceType?.index,
    };
  }

  String get labelShort {
    switch (status) {
      case AutoBackupStatus.pending:
        return S.current.pendingBackupShort;
      case AutoBackupStatus.encrypting:
        return S.current.encryptingBackupFileShort;
      case AutoBackupStatus.encryptFailed:
        return S.current.encryptBackupFileFailedShort;
      case AutoBackupStatus.encrpytSuccess:
        return S.current.encryptBackupFileSuccessShort;
      case AutoBackupStatus.saving:
        return S.current.savingBackupFileShort;
      case AutoBackupStatus.saveFailed:
        return S.current.saveBackupFileFailedShort;
      case AutoBackupStatus.saveSuccess:
        return S.current.saveBackupFileSuccessShort;
      case AutoBackupStatus.uploading:
        return S.current.uploadingBackupFileShort;
      case AutoBackupStatus.uploadFailed:
        return S.current.uploadBackupFileFailedShort;
      case AutoBackupStatus.uploadSuccess:
        return S.current.uploadBackupFileSuccessShort;
      case AutoBackupStatus.complete:
        return S.current.autoBackupCompleteShort;
      case AutoBackupStatus.failed:
        return S.current.autoBackupFailedShort;
      default:
        return S.current.pendingBackupShort;
    }
  }

  String label(AutoBackupLog log) {
    switch (status) {
      case AutoBackupStatus.pending:
        return S.current.pendingBackup(log.type.label);
      case AutoBackupStatus.encrypting:
        return S.current.encryptingBackupFile;
      case AutoBackupStatus.encryptFailed:
        return S.current.encryptBackupFileFailed;
      case AutoBackupStatus.encrpytSuccess:
        return S.current.encryptBackupFileSuccess;
      case AutoBackupStatus.saving:
        return S.current.savingBackupFile;
      case AutoBackupStatus.saveFailed:
        return S.current.saveBackupFileFailed;
      case AutoBackupStatus.saveSuccess:
        return S.current.saveBackupFileSuccess(log.backupPath);
      case AutoBackupStatus.uploading:
        if (cloudServiceType == null) {
          return S.current.uploadBackupFileFailed;
        } else {
          return S.current.uploadingBackupFileTo(cloudServiceType!.label);
        }
      case AutoBackupStatus.uploadFailed:
        return S.current.uploadBackupFileFailed;
      case AutoBackupStatus.uploadSuccess:
        if (cloudServiceType == null) {
          return S.current.uploadBackupFileFailed;
        } else {
          return S.current.uploadBackupFileSuccess(cloudServiceType!.label);
        }
      case AutoBackupStatus.complete:
        return S.current.autoBackupComplete;
      case AutoBackupStatus.failed:
        return S.current.autoBackupFailed;
      default:
        return S.current.pendingBackup(log.type.label);
    }
  }
}
