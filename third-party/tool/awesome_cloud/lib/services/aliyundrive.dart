import 'dart:convert';
import 'dart:typed_data';

import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:http/http.dart' as http;

import 'base_service.dart';

class AliyunDriveCloud extends BaseCloudService {
  @override
  String get serviceId => "AliyunDrive";

  @override
  String get serviceName => "AliyunDrive";

  @override
  String get authEndpoint => "https://openapi.alipan.com/oauth/authorize";

  @override
  String get tokenEndpoint => "https://openapi.alipan.com/oauth/access_token";

  @override
  String get revokeEndpoint => "";

  @override
  String get apiEndpoint => "https://openapi.alipan.com";

  @override
  String get permission => "user:base,file:all:read,file:all:write";

  @override
  String get expireInKey => "__aliyundrive_tokenExpire";

  @override
  String get accessTokenKey => "__aliyundrive_accessToken";

  @override
  String get refreshTokenKey => "__aliyundrive_refreshToken";

  @override
  String get idTokenKey => "__aliyundrive_idToken";

  @override
  String get rawRespKey => "__aliyundrive_rawResp";

  @override
  bool get keepPadding => true;

  AliyunDriveCloud({
    required super.clientId,
    required super.callbackUrl,
    String scopes = "",
    ITokenManager? tokenManager,
  });

  AliyunDriveCloud.server({
    required super.clientId,
    required super.callbackUrl,
    required super.customAuthEndpoint,
    required super.customTokenEndpoint,
    required super.customRevokeEndpoint,
    String scopes = "",
    ITokenManager? tokenManager,
  }) : super.server();

  @override
  Future<AliyunDriveResponse> getInfo() async {
    try {
      final userInfoResp =
          await get(Uri.parse("$apiEndpoint/oauth/users/info"));
      if (!isSuccess(userInfoResp)) {
        return AliyunDriveResponse.fromResponse(
          response: userInfoResp,
          message: "Failed to get basic user info.",
        );
      }
      final userInfo = jsonDecode(userInfoResp.body);

      final driveResp =
          await post(Uri.parse("$apiEndpoint/adrive/v1.0/user/getDriveInfo"));
      if (!isSuccess(driveResp)) {
        return AliyunDriveResponse.fromResponse(
          response: driveResp,
          message: "Failed to get drive info.",
        );
      }
      final driveInfo = jsonDecode(driveResp.body);

      Map<String, dynamic>? spaceInfo;
      final spaceResp =
          await post(Uri.parse("$apiEndpoint/adrive/v1.0/user/getSpaceInfo"));
      if (isSuccess(spaceResp)) {
        spaceInfo = jsonDecode(spaceResp.body);
      }

      final fullInfo = {
        "user": userInfo,
        "drive": driveInfo,
        "space": spaceInfo,
      };

      CloudLogger.info(serviceName, "AliyunDrive full user info: $fullInfo");

      return AliyunDriveResponse.success(
        userInfo: AliyunDriveUserInfo.fromJson(fullInfo),
        message: "Get user info successfully.",
      );
    } catch (e) {
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<AliyunDriveResponse> list(
    String remotePath, {
    String driveId = "",
  }) async {
    try {
      final folderResp = await checkFolder(remotePath, driveId: driveId);
      if (!folderResp.isSuccess || folderResp.parentId == null) {
        return AliyunDriveResponse.error(message: "Folder not found.");
      }

      final resp = await post(
        Uri.parse("$apiEndpoint/adrive/v1.0/openFile/list"),
        body: jsonEncode({
          "drive_id": driveId,
          "parent_file_id": folderResp.parentId,
          "limit": 100,
          "order_by": "name_enhanced",
          "order_direction": "ASC",
          "fields": "*"
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (isSuccess(resp)) {
        final items = jsonDecode(resp.body)['items'] as List;
        final files =
            items.map((e) => AliyunDriveFileInfo.fromJson(e)).toList();
        CloudLogger.infoResponse(
            serviceName, "Listed files successfully.", resp);
        return AliyunDriveResponse.success(
          files: files,
          message: "Listed files successfully.",
        );
      }

      CloudLogger.errorResponse(serviceName, "Failed to list files.", resp);
      return AliyunDriveResponse.fromResponse(
        response: resp,
        message: "Failed to list files.",
      );
    } catch (e) {
      CloudLogger.error(serviceName, "Failed to list files: $e");
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<AliyunDriveResponse> pullById(
    String id, {
    String remotePath = "",
    String driveId = "",
  }) async {
    try {
      final resp = await post(
        Uri.parse("$apiEndpoint/adrive/v1.0/openFile/getDownloadUrl"),
        body: jsonEncode({"file_id": id, "drive_id": driveId}),
        headers: {"Content-Type": "application/json"},
      );

      if (isSuccess(resp)) {
        CloudLogger.infoResponse(serviceName, "Get download url", resp);
        final url = jsonDecode(resp.body)["url"];
        final binary = await http.get(Uri.parse(url));

        if (binary.statusCode == 200) {
          CloudLogger.info(serviceName, "Downloaded file successfully.");
          return AliyunDriveResponse.success(
            bodyBytes: binary.bodyBytes,
            message: "Downloaded file successfully.",
          );
        } else {
          CloudLogger.error(serviceName, "Failed to download file.");
          return AliyunDriveResponse.error(message: "Failed to download file.");
        }
      }

      CloudLogger.errorResponse(
          serviceName, "Failed to get download url", resp);
      return AliyunDriveResponse.fromResponse(
        response: resp,
        message: "Failed to get download url.",
      );
    } catch (e) {
      CloudLogger.error(serviceName, "Failed to download file: $e");
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }

  Future<String?> findFileIdByName(
    String remotePath,
    String fileName, {
    String driveId = "",
  }) async {
    final folderResp = await checkFolder(remotePath, driveId: driveId);
    if (!folderResp.isSuccess || folderResp.parentId == null) {
      return null;
    }

    final listResp = await post(
      Uri.parse("$apiEndpoint/adrive/v1.0/openFile/list"),
      body: jsonEncode({
        "drive_id": driveId,
        "parent_file_id": folderResp.parentId,
        "limit": 100,
        "fileds": "*"
      }),
      headers: {"Content-Type": "application/json"},
    );

    CloudLogger.infoResponse(serviceName, "list files", listResp);
    if (!isSuccess(listResp)) return null;

    final items = jsonDecode(listResp.body)['items'] as List;
    for (final item in items) {
      if (item['name'] == fileName && item['type'] == 'file') {
        return item['file_id'];
      }
    }

    return null;
  }

  Future<bool> checkAsyncTaskComplete(
    String taskId, {
    int maxRetries = 10,
    Duration interval = const Duration(seconds: 1),
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final resp = await post(
        Uri.parse("$apiEndpoint/adrive/v1.0/openFile/async_task/get"),
        body: jsonEncode({"async_task_id": taskId}),
        headers: {"Content-Type": "application/json"},
      );

      if (!isSuccess(resp)) return false;

      final data = jsonDecode(resp.body);
      // Possible values: "Succeed", "Running", "Failed"
      final status = data["state"];
      CloudLogger.info("AliyunDrive", "Async task [$taskId] status: $status");

      if (status == "Succeed") return true;
      if (status == "Failed") return false;

      await Future.delayed(interval);
    }
    return false;
  }

  @override
  Future<AliyunDriveResponse> deleteById(
    String id, {
    String remotePath = "",
    String driveId = "",
  }) async {
    try {
      final resp = await post(
        Uri.parse("$apiEndpoint/adrive/v1.0/openFile/recyclebin/trash"),
        body: jsonEncode({
          "drive_id": driveId,
          "file_id": id,
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (isSuccess(resp)) {
        final data = jsonDecode(resp.body);
        final asyncTaskId = data["async_task_id"];
        if (asyncTaskId != null) {
          CloudLogger.info(
              serviceName, "Delete triggered async task: $asyncTaskId");
          final success = await checkAsyncTaskComplete(asyncTaskId);
          if (!success) {
            CloudLogger.error(
                serviceName, "Async delete task failed or timed out.");
            return AliyunDriveResponse.error(
                message: "Async delete task failed or timed out.");
          }
        }
        CloudLogger.infoResponse(serviceName, "File deleted.", resp);
        return AliyunDriveResponse.success(message: "File deleted.");
      }
      CloudLogger.errorResponse(serviceName, "Failed to delete file.", resp);
      return AliyunDriveResponse.fromResponse(
        response: resp,
        message: "Failed to delete file.",
      );
    } catch (e) {
      CloudLogger.error(serviceName, "Failed to delete file: $e");
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<AliyunDriveResponse> push(
    Uint8List bytes,
    String remotePath,
    String fileName, {
    String driveId = "",
    Function(int p1, int p2)? onProgress,
  }) async {
    try {
      final folderResp = await checkFolder(remotePath, driveId: driveId);
      if (!folderResp.isSuccess || folderResp.parentId == null) {
        return AliyunDriveResponse.error(message: "Folder unavailable.");
      }

      final parentId = folderResp.parentId!;

      final createResp = await post(
        Uri.parse("$apiEndpoint/adrive/v1.0/openFile/create"),
        body: jsonEncode({
          "drive_id": driveId,
          "name": fileName,
          "parent_file_id": parentId,
          "type": "file",
          "check_name_mode": "auto_rename",
          "size": bytes.length,
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (!isSuccess(createResp)) {
        CloudLogger.errorResponse(
            serviceName, "Failed to initiate file creation.", createResp);
        return AliyunDriveResponse.fromResponse(
          response: createResp,
          message: "Failed to initiate file creation.",
        );
      }

      CloudLogger.infoResponse(
          serviceName, "Start upload with creation: ", createResp);

      final createData = jsonDecode(createResp.body);
      final uploadUrl = createData["part_info_list"][0]["upload_url"];
      final uploadResp = await http.put(
        Uri.parse(uploadUrl),
        body: bytes,
      );

      if (uploadResp.statusCode != 200) {
        CloudLogger.errorResponse(
            serviceName, "Failed to upload file part.", uploadResp);
        return AliyunDriveResponse.error(
            message: "Failed to upload file part.");
      }

      final completeResp = await post(
        Uri.parse("$apiEndpoint/adrive/v1.0/openFile/complete"),
        body: jsonEncode(
          {
            "drive_id": driveId,
            "file_id": createData["file_id"],
            "upload_id": createData["upload_id"],
          },
        ),
        headers: {"Content-Type": "application/json"},
      );

      if (isSuccess(completeResp)) {
        CloudLogger.infoResponse(serviceName, "File uploaded.", completeResp);
        return AliyunDriveResponse.success(message: "File uploaded.");
      }

      CloudLogger.errorResponse(
          serviceName, "Failed to complete upload.", completeResp);
      return AliyunDriveResponse.fromResponse(
        response: completeResp,
        message: "Failed to complete upload.",
      );
    } catch (e) {
      CloudLogger.error(serviceName, "Failed to upload file: $e");
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<AliyunDriveResponse> checkFolder(
    String remotePath, {
    String driveId = "",
  }) async {
    try {
      final listResp = await post(
        Uri.parse("$apiEndpoint/adrive/v1.0/openFile/list"),
        body: jsonEncode(
          {
            "drive_id": driveId,
            "parent_file_id": "root",
            "limit": 100,
            "fields": "*"
          },
        ),
        headers: {"Content-Type": "application/json"},
      );
      CloudLogger.infoResponse(serviceName, "list files", listResp);

      if (isSuccess(listResp)) {
        final items = jsonDecode(listResp.body)['items'] as List;
        for (final item in items) {
          if (item['type'] == 'folder' && item['name'] == remotePath) {
            CloudLogger.info(serviceName, "Folder exists");
            return AliyunDriveResponse.success(
              parentId: item['file_id'],
              message: "Folder exists.",
            );
          }
        }
      }

      final createResp = await post(
        Uri.parse("$apiEndpoint/adrive/v1.0/openFile/create"),
        body: jsonEncode({
          "drive_id": driveId,
          "name": remotePath,
          "parent_file_id": "root",
          "type": "folder",
          "check_name_mode": "refuse",
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (isSuccess(createResp)) {
        final id = jsonDecode(createResp.body)['file_id'];
        CloudLogger.infoResponse(serviceName, "Folder created", createResp);
        return AliyunDriveResponse.success(
          parentId: id,
          message: "Folder created.",
        );
      } else {
        CloudLogger.errorResponse(
            serviceName, "Failed to create folder.", createResp);
        return AliyunDriveResponse.fromResponse(
          response: createResp,
          message: "Failed to create folder.",
        );
      }
    } catch (e) {
      CloudLogger.error(serviceName, "Failed to create folder: $e");
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }
}
