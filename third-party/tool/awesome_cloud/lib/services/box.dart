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

import 'dart:convert';
import 'dart:typed_data';

import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:http/http.dart' as http;

import 'base_service.dart';

class BoxCloud extends BaseCloudService {
  @override
  String get serviceId => "Box";

  @override
  String get serviceName => "Box";

  @override
  String get authEndpoint => "https://account.box.com/api/oauth2/authorize";

  @override
  String get tokenEndpoint => "https://api.box.com/oauth2/token";

  @override
  String get revokeEndpoint => "https://api.box.com/oauth2/revoke";

  @override
  String get apiEndpoint => "https://api.box.com/2.0";

  @override
  String get permission => "";

  @override
  String get expireInKey => "__box_tokenExpire";

  @override
  String get accessTokenKey => "__box_accessToken";

  @override
  String get refreshTokenKey => "__box_refreshToken";

  @override
  String get idTokenKey => "__box_idToken";

  @override
  String get rawRespKey => "__box_rawResp";

  BoxCloud({
    required super.clientId,
    required super.callbackUrl,
    String scopes = "",
    ITokenManager? tokenManager,
  });

  BoxCloud.server({
    required super.clientId,
    required super.callbackUrl,
    required super.customAuthEndpoint,
    required super.customTokenEndpoint,
    required super.customRevokeEndpoint,
    String scopes = "",
    ITokenManager? tokenManager,
  }) : super.server();

  @override
  Future<BoxResponse> getInfo() async {
    try {
      final url = Uri.parse("$apiEndpoint/users/me");
      final resp = await get(url);

      if (isSuccess(resp)) {
        final data = jsonDecode(resp.body);
        CloudLogger.info(
          serviceName,
          "Get info successfully: ${data.toString()}",
        );
        return BoxResponse.success(
          userInfo: BoxUserInfo.fromJson(data),
          message: "Get info successfully.",
        );
      }
      return BoxResponse.fromResponse(
        response: resp,
        message: "Failed to get user info.",
      );
    } catch (e) {
      CloudLogger.error(serviceName, "Exception: $e");
      return BoxResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<BoxResponse> list(String remotePath) async {
    try {
      final folderCheckResp = await checkFolder(remotePath);
      if (!folderCheckResp.isSuccess || folderCheckResp.parentId == null) {
        return BoxResponse.error(message: "Folder not found.");
      }

      final folderId = folderCheckResp.parentId!;
      final url = Uri.parse("$apiEndpoint/folders/$folderId/items"
          "?limit=1000"
          "&fields=id,name,type,size,created_at,modified_at");

      CloudLogger.info(
          serviceName, "Listing files at $remotePath (ID: $folderId)");
      final resp = await get(url);

      if (isSuccess(resp)) {
        final items = jsonDecode(resp.body)['entries'] as List;
        final files = items.map((item) => BoxFileInfo.fromJson(item)).toList();

        CloudLogger.infoResponse(
          serviceName,
          "Listed ${files.length} items in $remotePath.",
          resp,
        );
        return BoxResponse.success(
          files: files,
          message: "Listed files successfully.",
        );
      }

      CloudLogger.errorResponse(serviceName, "Failed to list files", resp);
      return BoxResponse.fromResponse(
        response: resp,
        message: "Failed to list files.",
      );
    } catch (e) {
      CloudLogger.error(serviceName, "Exception while listing: $e");
      return BoxResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<BoxResponse> pullById(String id) async {
    try {
      final url = Uri.parse("https://api.box.com/2.0/files/$id/content");
      CloudLogger.info(serviceName, "Pulling file by ID: $id");
      final resp = await get(url);

      if (resp.statusCode == 302 && resp.headers['location'] != null) {
        final downloadUrl = Uri.parse(resp.headers['location']!);
        CloudLogger.info(
          serviceName,
          "Redirected to download URL: $downloadUrl",
        );
        final binary = await http.get(downloadUrl);
        if (binary.statusCode != 200) {
          CloudLogger.error(
            serviceName,
            "Failed to download file: ${binary.statusCode} ${binary.reasonPhrase}",
          );
          return BoxResponse.error(
            message: "Failed to download file: ${binary.reasonPhrase}",
          );
        }
        CloudLogger.info(
          serviceName,
          "File downloaded successfully: ${binary.bodyBytes.length} bytes.",
        );
        return BoxResponse.success(
          message: "Download success.",
          bodyBytes: binary.bodyBytes,
        );
      } else if (isSuccess(resp)) {
        CloudLogger.info(serviceName, "Downloaded file");
        return BoxResponse.fromResponse(
          response: resp,
          message: "Downloaded file.",
        );
      }
      CloudLogger.errorResponse(
          serviceName, "Failed to get file download URL", resp);
      return BoxResponse.fromResponse(
        response: resp,
        message: "Failed to get file download URL.",
      );
    } catch (e) {
      CloudLogger.error(serviceName, "Exception: $e");
      return BoxResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<BoxResponse> deleteById(String id) async {
    try {
      final url = Uri.parse("$apiEndpoint/files/$id");
      CloudLogger.info(serviceName, "Deleting file by ID: $id");
      final resp = await delete(url);

      if (resp.statusCode == 204) {
        CloudLogger.infoResponse(serviceName, "File deleted.", resp);
        return BoxResponse.success(message: "File deleted.");
      }
      CloudLogger.errorResponse(serviceName, "Failed to delete file", resp);
      return BoxResponse.fromResponse(
        response: resp,
        message: "Failed to delete file.",
      );
    } catch (e) {
      CloudLogger.error(serviceName, "Exception: $e");
      return BoxResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<BoxResponse> push(
    Uint8List bytes,
    String remotePath,
    String fileName, {
    Function(int p1, int p2)? onProgress,
  }) async {
    try {
      final folderResp = await checkFolder(remotePath);
      if (!folderResp.isSuccess || folderResp.parentId == null) {
        return BoxResponse.error(message: "Target folder not available.");
      }

      final folderId = folderResp.parentId!;
      final url = Uri.parse("https://upload.box.com/api/2.0/files/content");

      CloudLogger.info(
        serviceName,
        "Uploading file: $fileName to $remotePath (ID: $folderId)",
      );

      final request = http.MultipartRequest("POST", url)
        ..headers["Authorization"] =
            "Bearer ${await tokenManager.getAccessToken()}"
        ..fields["attributes"] = jsonEncode({
          "name": fileName,
          "parent": {"id": folderId},
        })
        ..files.add(
          http.MultipartFile.fromBytes(
            "file",
            bytes,
            filename: fileName,
          ),
        );

      final streamedResp = await request.send();
      final resp = await http.Response.fromStream(streamedResp);

      if (isSuccess(resp)) {
        CloudLogger.infoResponse(
            serviceName, "File uploaded successfully: ${resp.body}", resp);
        return BoxResponse.success(message: "File uploaded.");
      }

      CloudLogger.errorResponse(serviceName, "Failed to upload file", resp);
      return BoxResponse.fromResponse(
        response: resp,
        message: "Upload failed.",
      );
    } catch (e) {
      CloudLogger.error(serviceName, "Exception: $e");
      return BoxResponse.error(message: "Unexpected error: $e");
    }
  }

  @override
  Future<BoxResponse> checkFolder(String remotePath) async {
    try {
      final searchResp = await get(Uri.parse(
          "$apiEndpoint/folders/0/items?limit=1000&fields=id,name,type"));

      if (isSuccess(searchResp)) {
        final entries = jsonDecode(searchResp.body)['entries'] as List;
        for (final item in entries) {
          if (item['type'] == 'folder' && item['name'] == remotePath) {
            CloudLogger.info(
              serviceName,
              "Folder already exists: ${item['name']} (ID: ${item['id']})",
            );
            return BoxResponse.success(
              parentId: item['id'],
              message: "Folder already exists.",
            );
          }
        }
      }

      final url = Uri.parse("$apiEndpoint/folders");
      final body = jsonEncode({
        "name": remotePath,
        "parent": {"id": "0"}
      });

      final createResp = await post(url, body: body);

      if (isSuccess(createResp)) {
        final id = jsonDecode(createResp.body)['id'];
        CloudLogger.info(
          serviceName,
          "Folder created successfully: $remotePath (ID: $id)",
        );
        return BoxResponse.success(
          parentId: id,
          message: "Folder created successfully.",
        );
      } else {
        CloudLogger.errorResponse(
          serviceName,
          "Failed to create folder",
          createResp,
        );
        return BoxResponse.fromResponse(
          response: createResp,
          message: "Failed to create folder.",
        );
      }
    } catch (e) {
      CloudLogger.error(serviceName, "Exception while checking folder: $e");
      return BoxResponse.error(message: "Unexpected exception: $e");
    }
  }
}
