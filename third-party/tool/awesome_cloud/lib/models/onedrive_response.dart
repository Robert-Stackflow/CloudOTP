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

import 'base_response.dart';

typedef OneDriveResponse
    = BaseCloudResponse<OneDriveUserInfo, OneDriveFileInfo>;

class OneDriveUserInfo extends BaseCloudUserInfo {
  final String? email;
  final String? displayName;
  final int? total;
  final int? used;
  final int? deleted;
  final int? remaining;
  final String? state;

  OneDriveUserInfo({
    this.email,
    this.displayName,
    this.total,
    this.used,
    this.deleted,
    this.remaining,
    this.state,
  });

  factory OneDriveUserInfo.fromJson(Map<String, dynamic> json) {
    return OneDriveUserInfo(
        email: json['owner']['user']['email'],
        displayName: json['owner']['user']['displayName'],
        total: json['quota']['total'],
        used: json['quota']['used'],
        deleted: json['quota']['deleted'],
        remaining: json['quota']['remaining'],
        state: json['quota']['state']);
  }

  @override
  String toString() {
    return "OneDriveUserInfo("
        "email: $email, "
        "displayName: $displayName, "
        "total: $total, "
        "used: $used, "
        "deleted: $deleted, "
        "remaing: $remaining, "
        "state: $state"
        ")";
  }
}

class OneDriveFileInfo extends BaseCloudFileInfo {
  final String id;
  final String name;
  final int size;
  final int createdDateTime;
  final int lastModifiedDateTime;
  final String description;
  final String fileMimeType;

  OneDriveFileInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.createdDateTime,
    required this.lastModifiedDateTime,
    required this.description,
    required this.fileMimeType,
  });

  factory OneDriveFileInfo.fromJson(Map<String, dynamic> json) {
    return OneDriveFileInfo(
      id: json['id'],
      name: json['name'],
      size: json['size'] ?? 0,
      createdDateTime:
          DateTime.parse(json['createdDateTime']).millisecondsSinceEpoch,
      lastModifiedDateTime:
          DateTime.parse(json['lastModifiedDateTime']).millisecondsSinceEpoch,
      description: json['description'] ?? "",
      fileMimeType: json['file'] != null ? json['file']['mimeType'] ?? "" : "",
    );
  }

  @override
  String toString() {
    return "OneDriveFileInfo("
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
