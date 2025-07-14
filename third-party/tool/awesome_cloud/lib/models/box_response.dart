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

typedef BoxResponse = BaseCloudResponse<BoxUserInfo, BoxFileInfo>;

class BoxUserInfo extends BaseCloudUserInfo {
  final String? id;
  final String? name;
  final String? login;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final String? language;
  final String? timezone;
  final int? spaceAmount;
  final int? spaceUsed;
  final int? maxUploadSize;
  final String? status;
  final String? jobTitle;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String? notificationEmail;

  BoxUserInfo({
    this.id,
    this.name,
    this.login,
    this.createdAt,
    this.modifiedAt,
    this.language,
    this.timezone,
    this.spaceAmount,
    this.spaceUsed,
    this.maxUploadSize,
    this.status,
    this.jobTitle,
    this.phone,
    this.address,
    this.avatarUrl,
    this.notificationEmail,
  });

  /// 从JSON构造函数
  factory BoxUserInfo.fromJson(Map<String, dynamic> json) {
    return BoxUserInfo(
      id: json['id']?.toString(),
      // 确保ID为字符串类型
      name: json['name'] as String?,
      login: json['login'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'] as String)
          : null,
      language: json['language'] as String?,
      timezone: json['timezone'] as String?,
      spaceAmount: json['space_amount'] as int?,
      spaceUsed: json['space_used'] as int?,
      maxUploadSize: json['max_upload_size'] as int?,
      status: json['status'] as String?,
      jobTitle: json['job_title'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      notificationEmail: json['notification_email'] as String?,
    );
  }

  @override
  String toString() {
    return 'BoxUserInfo{'
        'id: $id, '
        'name: $name, '
        'login: $login, '
        'createdAt: ${createdAt?.toIso8601String()}, '
        'modifiedAt: ${modifiedAt?.toIso8601String()}, '
        'language: $language, '
        'timezone: $timezone, '
        'spaceAmount: $spaceAmount, '
        'spaceUsed: $spaceUsed, '
        'maxUploadSize: $maxUploadSize, '
        'status: $status, '
        'jobTitle: $jobTitle, '
        'phone: $phone, '
        'address: $address, '
        'avatarUrl: $avatarUrl, '
        'notificationEmail: $notificationEmail'
        '}';
  }
}

class BoxFileInfo extends BaseCloudFileInfo {
  final String id;
  final String name;
  final int size;
  final int createdDateTime;
  final int lastModifiedDateTime;
  final String description;
  final String fileMimeType;

  BoxFileInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.createdDateTime,
    required this.lastModifiedDateTime,
    required this.description,
    required this.fileMimeType,
  });

  factory BoxFileInfo.fromJson(Map<String, dynamic> json) {
    return BoxFileInfo(
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
    return "BoxFileInfo("
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
