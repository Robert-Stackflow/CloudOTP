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

import '../l10n/l10n.dart';
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
        return appLocalizations.backupToLocal;
      case AutoBackupType.cloud:
        return appLocalizations.backupToCloud;
      case AutoBackupType.localAndCloud:
        return appLocalizations.backupToLocalAndCloud;
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
        return appLocalizations.triggerAutoBackupByManual;
      case AutoBackupTriggerType.other:
        return appLocalizations.triggerAutoBackupByOther;
      case AutoBackupTriggerType.configInited:
        return appLocalizations.triggerAutoBackupByConfigInited;
      case AutoBackupTriggerType.configUpdated:
        return appLocalizations.triggerAutoBackupByConfigUpdated;
      case AutoBackupTriggerType.tokenInserted:
        return appLocalizations.triggerAutoBackupByTokenInserted;
      case AutoBackupTriggerType.tokensInserted:
        return appLocalizations.triggerAutoBackupByTokensInserted;
      case AutoBackupTriggerType.tokenUpdated:
        return appLocalizations.triggerAutoBackupByTokenUpdated;
      case AutoBackupTriggerType.tokensUpdated:
        return appLocalizations.triggerAutoBackupByTokensUpdated;
      case AutoBackupTriggerType.tokenDeleted:
        return appLocalizations.triggerAutoBackupByTokenDeleted;
      case AutoBackupTriggerType.categoryInserted:
        return appLocalizations.triggerAutoBackupByCategoryInserted;
      case AutoBackupTriggerType.categoriesInserted:
        return appLocalizations.triggerAutoBackupByCategoriesInserted;
      case AutoBackupTriggerType.categoryUpdated:
        return appLocalizations.triggerAutoBackupByCategoryUpdated;
      case AutoBackupTriggerType.categoriesUpdated:
        return appLocalizations.triggerAutoBackupByCategoriesUpdated;
      case AutoBackupTriggerType.categoryDeleted:
        return appLocalizations.triggerAutoBackupByCategoryDeleted;
      case AutoBackupTriggerType.categoriesUpdatedForToken:
        return appLocalizations.triggerAutoBackupByCategoriesUpdatedForToken;
      case AutoBackupTriggerType.cloudServiceConfigInserted:
        return appLocalizations.triggerAutoBackupByCloudServiceConfigInserted;
      case AutoBackupTriggerType.cloudServiceConfigUpdated:
        return appLocalizations.triggerAutoBackupByCloudServiceConfigUpdated;
      case AutoBackupTriggerType.cloudServiceConfigDeleted:
        return appLocalizations.triggerAutoBackupByCloudServiceConfigDeleted;
      default:
        return appLocalizations.triggerAutoBackupByOther;
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
        return appLocalizations.pendingBackupShort;
      case AutoBackupStatus.encrypting:
        return appLocalizations.encryptingBackupFileShort;
      case AutoBackupStatus.encryptFailed:
        return appLocalizations.encryptBackupFileFailedShort;
      case AutoBackupStatus.encrpytSuccess:
        return appLocalizations.encryptBackupFileSuccessShort;
      case AutoBackupStatus.saving:
        return appLocalizations.savingBackupFileShort;
      case AutoBackupStatus.saveFailed:
        return appLocalizations.saveBackupFileFailedShort;
      case AutoBackupStatus.saveSuccess:
        return appLocalizations.saveBackupFileSuccessShort;
      case AutoBackupStatus.uploading:
        return appLocalizations.uploadingBackupFileShort;
      case AutoBackupStatus.uploadFailed:
        return appLocalizations.uploadBackupFileFailedShort;
      case AutoBackupStatus.uploadSuccess:
        return appLocalizations.uploadBackupFileSuccessShort;
      case AutoBackupStatus.complete:
        return appLocalizations.autoBackupCompleteShort;
      case AutoBackupStatus.failed:
        return appLocalizations.autoBackupFailedShort;
      default:
        return appLocalizations.pendingBackupShort;
    }
  }

  String label(AutoBackupLog log) {
    switch (status) {
      case AutoBackupStatus.pending:
        return appLocalizations.pendingBackup(log.type.label);
      case AutoBackupStatus.encrypting:
        return appLocalizations.encryptingBackupFile;
      case AutoBackupStatus.encryptFailed:
        return appLocalizations.encryptBackupFileFailed;
      case AutoBackupStatus.encrpytSuccess:
        return appLocalizations.encryptBackupFileSuccess;
      case AutoBackupStatus.saving:
        return appLocalizations.savingBackupFile;
      case AutoBackupStatus.saveFailed:
        return appLocalizations.saveBackupFileFailed;
      case AutoBackupStatus.saveSuccess:
        return appLocalizations.saveBackupFileSuccess(log.backupPath);
      case AutoBackupStatus.uploading:
        if (cloudServiceType == null) {
          return appLocalizations.uploadBackupFileFailed;
        } else {
          return appLocalizations
              .uploadingBackupFileTo(cloudServiceType!.label);
        }
      case AutoBackupStatus.uploadFailed:
        return appLocalizations.uploadBackupFileFailed;
      case AutoBackupStatus.uploadSuccess:
        if (cloudServiceType == null) {
          return appLocalizations.uploadBackupFileFailed;
        } else {
          return appLocalizations
              .uploadBackupFileSuccess(cloudServiceType!.label);
        }
      case AutoBackupStatus.complete:
        return appLocalizations.autoBackupComplete;
      case AutoBackupStatus.failed:
        return appLocalizations.autoBackupFailed;
      default:
        return appLocalizations.pendingBackup(log.type.label);
    }
  }
}
