/*
 * Copyright (c) 2025 Robert-Stackflow.
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

import 'package:awesome_cloud/models/base_response.dart';

typedef AliyunDriveResponse
    = BaseCloudResponse<AliyunDriveUserInfo, AliyunDriveFileInfo>;

class AliyunDriveUserInfo extends BaseCloudUserInfo {
  final String? id;
  final String? name;
  final String? avatarUrl;
  final String? phone;

  final String? defaultDriveId;
  final String? resourceDriveId;
  final String? backupDriveId;
  final String? folderId;

  final int? spaceUsed;
  final int? spaceAmount;

  AliyunDriveUserInfo({
    this.id,
    this.name,
    this.avatarUrl,
    this.phone,
    this.defaultDriveId,
    this.resourceDriveId,
    this.backupDriveId,
    this.folderId,
    this.spaceUsed,
    this.spaceAmount,
  });

  factory AliyunDriveUserInfo.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final drive = json['drive'] ?? {};
    final space = json['space']?['personal_space_info'] ?? {};

    return AliyunDriveUserInfo(
      id: user['id']?.toString(),
      name: (user['name'] as String?)?.isNotEmpty == true
          ? user['name']
          : 'Default',
      avatarUrl: user['avatar'] as String?,
      phone: user['phone'] as String?,
      defaultDriveId: drive['default_drive_id'] as String?,
      resourceDriveId: drive['resource_drive_id'] as String?,
      backupDriveId: drive['backup_drive_id'] as String?,
      folderId: drive['folder_id'] as String?,
      spaceUsed: space['used_size'] as int?,
      spaceAmount: space['total_size'] as int?,
    );
  }

  @override
  String toString() {
    return 'AliyunDriveUserInfo{'
        'id: $id, '
        'name: $name, '
        'avatarUrl: $avatarUrl, '
        'phone: $phone, '
        'defaultDriveId: $defaultDriveId, '
        'resourceDriveId: $resourceDriveId, '
        'backupDriveId: $backupDriveId, '
        'folderId: $folderId, '
        'spaceUsed: $spaceUsed, '
        'spaceAmount: $spaceAmount, '
        '}';
  }
}

class AliyunDriveFileInfo extends BaseCloudFileInfo {
  final String id;
  final String name;
  final int size;
  final int createdDateTime;
  final int lastModifiedDateTime;
  final String description;
  final String fileMimeType;

  AliyunDriveFileInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.createdDateTime,
    required this.lastModifiedDateTime,
    required this.description,
    required this.fileMimeType,
  });

  factory AliyunDriveFileInfo.fromJson(Map<String, dynamic> json) {
    return AliyunDriveFileInfo(
      id: json['id'],
      name: json['name'],
      size: json['size'] ?? 0,
      createdDateTime: json['created_at'] != null
          ? DateTime.parse(json['created_at']).millisecondsSinceEpoch
          : 0,
      lastModifiedDateTime: json['modified_at'] != null
          ? DateTime.parse(json['modified_at']).millisecondsSinceEpoch
          : 0,
      description: "",
      fileMimeType: json['type'] ?? "file",
    );
  }

  @override
  String toString() {
    return "AliyunDriveFileInfo("
        "id: $id, "
        "name: $name, "
        "size: $size, "
        "createdDateTime: $createdDateTime, "
        "lastModifiedDateTime: $lastModifiedDateTime, "
        "description: $description, "
        "fileMimeType: $fileMimeType"
        ")";
  }
}
