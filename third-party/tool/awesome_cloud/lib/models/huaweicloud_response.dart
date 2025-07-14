import 'base_response.dart';

typedef HuaweiCloudResponse
    = BaseCloudResponse<HuaweiCloudUserInfo, HuaweiCloudFileInfo>;

class HuaweiCloudUserInfo extends BaseCloudUserInfo {
  final String? email;
  final String? displayName;
  final int? total;
  final int? used;
  final String? state;

  HuaweiCloudUserInfo(
      {this.email, this.displayName, this.total, this.used, this.state});

  factory HuaweiCloudUserInfo.fromJson(Map<String, dynamic> json) {
    return HuaweiCloudUserInfo(
      email: "",
      displayName: json['user'] != null ? json['user']['displayName'] : "",
      total: json['storageQuota'] != null &&
              json['storageQuota']['userCapacity'] != null
          ? int.tryParse(json['storageQuota']['userCapacity']) ?? 0
          : 0,
      used: json['storageQuota'] != null &&
              json['storageQuota']['usedSpace'] != null
          ? int.tryParse(json['storageQuota']['usedSpace']) ?? 0
          : 0,
    );
  }

  @override
  String toString() {
    return "HuaweiCloudUserInfo("
        "email: $email, "
        "displayName: $displayName, "
        "total: $total, "
        "used: $used, "
        "state: $state"
        ")";
  }
}

class HuaweiCloudFileInfo extends BaseCloudFileInfo {
  final String id;
  final String name;
  final int size;
  final int createdDateTime;
  final int lastModifiedDateTime;
  final String description;
  final String fileMimeType;

  HuaweiCloudFileInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.createdDateTime,
    required this.lastModifiedDateTime,
    required this.description,
    required this.fileMimeType,
  });

  factory HuaweiCloudFileInfo.fromJson(Map<String, dynamic> json) {
    return HuaweiCloudFileInfo(
      id: json['id'],
      name: json['fileName'],
      size: json['size'] ?? 0,
      createdDateTime:
          DateTime.parse(json['createdTime']).millisecondsSinceEpoch,
      lastModifiedDateTime:
          DateTime.parse(json['editedTime']).millisecondsSinceEpoch,
      description: json['description'] ?? "",
      fileMimeType: json['mimeType'] ?? "",
    );
  }
}
