import 'dart:convert';
import 'dart:typed_data';

import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:http/http.dart' as http;

import '../models/aliyundrive_response.dart';
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
      final userInfoResp = await get(Uri.parse("$apiEndpoint/oauth/users/info"));
      if (!isSuccess(userInfoResp)) {
        return AliyunDriveResponse.fromResponse(
          response: userInfoResp,
          message: "Failed to get basic user info.",
        );
      }
      final userInfo = jsonDecode(userInfoResp.body);

      final driveResp = await post(Uri.parse("$apiEndpoint/adrive/v1.0/user/getDriveInfo"));
      if (!isSuccess(driveResp)) {
        return AliyunDriveResponse.fromResponse(
          response: driveResp,
          message: "Failed to get drive info.",
        );
      }
      final driveInfo = jsonDecode(driveResp.body);

      Map<String, dynamic>? spaceInfo;
      final spaceResp = await post(Uri.parse("$apiEndpoint/adrive/v1.0/user/getSpaceInfo"));
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
  Future<AliyunDriveResponse> list(String remotePath) async {
    try {
      final folderResp = await checkFolder(remotePath);
      if (!folderResp.isSuccess || folderResp.parentId == null) {
        return AliyunDriveResponse.error(message: "Folder not found.");
      }

      final resp = await post(
        Uri.parse("$apiEndpoint/v2/file/list"),
        body: jsonEncode({
          "drive_id": "default",
          "parent_file_id": folderResp.parentId,
          "limit": 100,
          "all": false,
          "image_thumbnail_process": "image/resize,w_400/format,jpeg",
          "image_url_process": "image/resize,w_1920/format,jpeg",
          "video_thumbnail_process": "video/snapshot,t_0,f_jpg,ar_auto,w_300",
        }),
      );

      if (isSuccess(resp)) {
        final items = jsonDecode(resp.body)['items'] as List;
        final files =
            items.map((e) => AliyunDriveFileInfo.fromJson(e)).toList();
        return AliyunDriveResponse.success(
          files: files,
          message: "Listed files successfully.",
        );
      }

      return AliyunDriveResponse.fromResponse(
        response: resp,
        message: "Failed to list files.",
      );
    } catch (e) {
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<AliyunDriveResponse> pullById(String fileId) async {
    try {
      final resp = await post(
        Uri.parse("$apiEndpoint/v2/file/get_download_url"),
        body: jsonEncode({"file_id": fileId, "drive_id": "default"}),
      );

      if (isSuccess(resp)) {
        final url = jsonDecode(resp.body)["url"];
        final binary = await http.get(Uri.parse(url));

        if (binary.statusCode == 200) {
          return AliyunDriveResponse.success(
            bodyBytes: binary.bodyBytes,
            message: "Downloaded file successfully.",
          );
        } else {
          return AliyunDriveResponse.error(message: "Failed to download file.");
        }
      }

      return AliyunDriveResponse.fromResponse(
        response: resp,
        message: "Failed to get download url.",
      );
    } catch (e) {
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<AliyunDriveResponse> deleteById(String id) async {
    try {
      final resp = await post(
        Uri.parse("$apiEndpoint/v2/recyclebin/trash"),
        body: jsonEncode({
          "drive_id": "default",
          "file_id": id,
        }),
      );

      if (isSuccess(resp)) {
        return AliyunDriveResponse.success(message: "File deleted.");
      }
      return AliyunDriveResponse.fromResponse(
        response: resp,
        message: "Failed to delete file.",
      );
    } catch (e) {
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<AliyunDriveResponse> push(
    Uint8List bytes,
    String remotePath, {
    String fileName = "",
    Function(int p1, int p2)? onProgress,
  }) async {
    try {
      final folderResp = await checkFolder(remotePath);
      if (!folderResp.isSuccess || folderResp.parentId == null) {
        return AliyunDriveResponse.error(message: "Folder unavailable.");
      }

      final parentId = folderResp.parentId!;

      final createResp = await post(
        Uri.parse("$apiEndpoint/v2/file/create"),
        body: jsonEncode({
          "drive_id": "default",
          "name": fileName,
          "parent_file_id": parentId,
          "type": "file",
          "check_name_mode": "auto_rename",
          "size": bytes.length,
        }),
      );

      if (!isSuccess(createResp)) {
        return AliyunDriveResponse.fromResponse(
          response: createResp,
          message: "Failed to initiate file creation.",
        );
      }

      final createData = jsonDecode(createResp.body);
      final uploadUrl = createData["part_info_list"][0]["upload_url"];
      final uploadResp = await http.put(
        Uri.parse(uploadUrl),
        body: bytes,
        headers: {"Content-Type": "application/octet-stream"},
      );

      if (uploadResp.statusCode != 200) {
        return AliyunDriveResponse.error(
            message: "Failed to upload file part.");
      }

      final completeResp = await post(
        Uri.parse("$apiEndpoint/v2/file/complete"),
        body: jsonEncode({
          "drive_id": "default",
          "file_id": createData["file_id"],
          "upload_id": createData["upload_id"],
        }),
      );

      if (isSuccess(completeResp)) {
        return AliyunDriveResponse.success(message: "File uploaded.");
      }

      return AliyunDriveResponse.fromResponse(
        response: completeResp,
        message: "Failed to complete upload.",
      );
    } catch (e) {
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<AliyunDriveResponse> checkFolder(String remotePath) async {
    try {
      // Step 1: list root to find folder
      final listResp = await post(
        Uri.parse("$apiEndpoint/v2/file/list"),
        body: jsonEncode({
          "drive_id": "default",
          "parent_file_id": "root",
          "limit": 100,
        }),
      );

      if (isSuccess(listResp)) {
        final items = jsonDecode(listResp.body)['items'] as List;
        for (final item in items) {
          if (item['type'] == 'folder' && item['name'] == remotePath) {
            return AliyunDriveResponse.success(
              parentId: item['file_id'],
              message: "Folder exists.",
            );
          }
        }
      }

      // Step 2: create folder
      final createResp = await post(
        Uri.parse("$apiEndpoint/v2/file/create"),
        body: jsonEncode({
          "drive_id": "default",
          "name": remotePath,
          "parent_file_id": "root",
          "type": "folder",
          "check_name_mode": "refuse",
        }),
      );

      if (isSuccess(createResp)) {
        final id = jsonDecode(createResp.body)['file_id'];
        return AliyunDriveResponse.success(
          parentId: id,
          message: "Folder created.",
        );
      } else {
        return AliyunDriveResponse.fromResponse(
          response: createResp,
          message: "Failed to create folder.",
        );
      }
    } catch (e) {
      return AliyunDriveResponse.error(message: "Unexpected error: $e");
    }
  }
}
