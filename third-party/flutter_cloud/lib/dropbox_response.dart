import 'dart:typed_data';

import 'package:flutter_cloud/status.dart';
import 'package:http/http.dart' as http;

class DropboxResponse {
  final ResponseStatus status;
  final int? statusCode;
  final String? body;
  final String? message;
  final String? accessToken;
  final bool isSuccess;
  final Uint8List? bodyBytes;
  final DropboxUserInfo? userInfo;
  final List<DropboxFileInfo> files;

  DropboxResponse({
    this.status = ResponseStatus.success,
    this.statusCode,
    this.body,
    this.bodyBytes,
    this.accessToken,
    this.userInfo,
    this.message,
    this.files = const [],
    this.isSuccess = false,
  });

  DropboxResponse.fromResponse({
    required http.Response response,
    this.userInfo,
    this.message,
    this.files = const [],
  })  : body = response.body,
        accessToken = "",
        statusCode = response.statusCode,
        bodyBytes = response.bodyBytes,
        isSuccess = response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 204,
        status = ResponseStatus.values.firstWhere(
            (element) => element.code == response.statusCode,
            orElse: () => ResponseStatus.success);

  @override
  String toString() {
    return "DropboxResponse("
        "statusCode: $statusCode, "
        "body: $body, "
        "bodyBytes: $bodyBytes, "
        "message: $message, "
        "isSuccess: $isSuccess"
        ")";
  }
}

class DropboxUserInfo {
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

class DropboxFileInfo {
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
