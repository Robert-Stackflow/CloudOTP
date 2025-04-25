import 'dart:typed_data';

class GoogleDriveResponse {
  final int? statusCode;
  final String? body;
  final String? message;
  final bool isSuccess;
  final Uint8List? bodyBytes;
  final GoogleDriveUserInfo? userInfo;
  final List<GoogleDriveFileInfo> files;
  final String? parentId;

  GoogleDriveResponse({
    this.statusCode,
    this.body,
    this.message,
    this.bodyBytes,
    this.parentId,
    this.userInfo,
    this.files = const [],
    this.isSuccess = false,
  });

  @override
  String toString() {
    return "GoogleDriveResponse("
        "statusCode: $statusCode, "
        "body: $body, "
        "bodyBytes: $bodyBytes, "
        "message: $message, "
        "isSuccess: $isSuccess"
        ")";
  }
}

class GoogleDriveUserInfo {
  final String? email;
  final String? displayName;
  final int? total;
  final int? used;

  GoogleDriveUserInfo({
    this.email,
    this.displayName,
    this.total,
    this.used,
  });

  factory GoogleDriveUserInfo.fromJson(Map<String, dynamic> json) {
    return GoogleDriveUserInfo(
      email: json['user']['emailAddress'],
      displayName: json['user']['displayName'],
      total: int.tryParse(json['storageQuota']['limit']),
      used: int.tryParse(json['storageQuota']['usageInDrive']),
    );
  }

  @override
  String toString() {
    return "GoogleDriveUserInfo("
        "email: $email, "
        "displayName: $displayName, "
        "total: $total, "
        "used: $used, "
        ")";
  }
}

class GoogleDriveFileInfo {
  final String id;
  final String name;
  final int size;
  final int createdDateTime;
  final int lastModifiedDateTime;
  final String description;
  final String fileMimeType;

  GoogleDriveFileInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.createdDateTime,
    required this.lastModifiedDateTime,
    required this.description,
    required this.fileMimeType,
  });

  factory GoogleDriveFileInfo.fromJson(Map<String, dynamic> json) {
    return GoogleDriveFileInfo(
      id: json['id'],
      name: json['name'],
      size: json['size'] ?? 0,
      createdDateTime:
          DateTime.parse(json['createdDateTime'] ?? "").millisecondsSinceEpoch,
      lastModifiedDateTime: DateTime.parse(json['lastModifiedDateTime'] ?? "")
          .millisecondsSinceEpoch,
      description: json['description'] ?? "",
      fileMimeType: json['mimeType'] ?? "",
    );
  }

  @override
  String toString() {
    return "GoogleDriveFileInfo("
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
