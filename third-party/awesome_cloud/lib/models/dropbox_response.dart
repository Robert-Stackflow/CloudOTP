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

typedef DropboxResponse = BaseCloudResponse<DropboxUserInfo, DropboxFileInfo>;

class DropboxUserInfo extends BaseCloudUserInfo {
  final String? email;
  final String? displayName;
  final int? total;
  final int? used;

  DropboxUserInfo({
    this.email,
    this.displayName,
    this.total,
    this.used,
  });

  factory DropboxUserInfo.fromJson(
      Map<String, dynamic> json, Map<String, dynamic> usageJson) {
    return DropboxUserInfo(
      email: json['email'],
      displayName: json['name']['display_name'],
      total: usageJson['allocation']['allocated'],
      used: usageJson['used'],
    );
  }

  @override
  String toString() {
    return "DropboxUserInfo("
        "email: $email, "
        "displayName: $displayName, "
        "total: $total, "
        "used: $used, "
        ")";
  }
}

class DropboxFileInfo extends BaseCloudFileInfo {
  final String id;
  final String name;
  final int size;
  final int createdDateTime;
  final int lastModifiedDateTime;

  DropboxFileInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.createdDateTime,
    required this.lastModifiedDateTime,
  });

  factory DropboxFileInfo.fromJson(Map<String, dynamic> json) {
    return DropboxFileInfo(
      id: json['id'],
      name: json['name'],
      size: json['size'] ?? 0,
      createdDateTime: json['file_lock_info'] != null
          ? DateTime.parse(json['file_lock_info']['created'])
              .millisecondsSinceEpoch
          : 0,
      lastModifiedDateTime:
          DateTime.parse(json['client_modified']).millisecondsSinceEpoch,
    );
  }
}
