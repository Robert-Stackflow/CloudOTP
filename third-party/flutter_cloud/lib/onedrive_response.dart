import 'dart:typed_data';
import 'package:flutter_cloud/status.dart';
import 'package:http/http.dart' as http;

class OneDriveResponse {
  final ResponseStatus status;
  final int? statusCode;
  final String? body;
  final String? message;
  final bool isSuccess;
  final Uint8List? bodyBytes;
  final String? accessToken;
  final OneDriveUserInfo? userInfo;
  final List<OneDriveFileInfo> files;

  OneDriveResponse({
    this.status = ResponseStatus.success,
    this.statusCode,
    this.body,
    this.message,
    this.accessToken,
    this.bodyBytes,
    this.userInfo,
    this.files = const [],
    this.isSuccess = false,
  });

  OneDriveResponse.fromResponse({
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
    return "OneDriveResponse("
        "statusCode: $statusCode, "
        "body: $body, "
        "bodyBytes: $bodyBytes, "
        "message: $message, "
        "isSuccess: $isSuccess"
        ")";
  }
}

class OneDriveUserInfo {
  final String? email;
  final String? displayName;
  final int? total;
  final int? used;
  final int? deleted;
  final int? remaining;
  final String? state;

  OneDriveUserInfo(
      {this.email,
      this.displayName,
      this.total,
      this.used,
      this.deleted,
      this.remaining,
      this.state});

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

class OneDriveFileInfo {
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
}
