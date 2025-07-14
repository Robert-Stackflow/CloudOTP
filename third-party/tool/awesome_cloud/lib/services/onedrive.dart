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

import 'dart:async';
import 'dart:convert';

import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:awesome_cloud/services/base_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class OneDrive extends BaseCloudService {
  @override
  String get serviceId => "Onedrive";

  @override
  String get serviceName => "Onedrive";

  @override
  String get authEndpoint =>
      "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize";

  @override
  String get tokenEndpoint =>
      "https://login.microsoftonline.com/consumers/oauth2/v2.0/token";

  @override
  String get revokeEndpoint =>
      "https://login.microsoftonline.com/consumers/oauth2/v2.0/revoke";

  @override
  String get apiEndpoint => "https://graph.microsoft.com/v1.0";

  @override
  String get permission => "Files.ReadWrite.All offline_access";

  @override
  String get expireInKey => "__onedrive_tokenExpire";

  @override
  String get accessTokenKey => "__onedrive_accessToken";

  @override
  String get refreshTokenKey => "__onedrive_refreshToken";

  @override
  String get idTokenKey => "__onedrive_idToken";

  @override
  String get rawRespKey => "__onedrive_rawResp";

  static const _appRootFolder = "special/approot";
  static const _defaultRootFolder = "root";

  OneDrive({
    required super.clientId,
    required super.callbackUrl,
    String scopes = "",
    ITokenManager? tokenManager,
  });

  String _getRootFolder([bool isAppFolder = false]) {
    return isAppFolder ? _appRootFolder : _defaultRootFolder;
  }

  @override
  Future<OneDriveResponse> getInfo() async {
    try {
      final getInfoUri = Uri.parse("$apiEndpoint/drive?select=owner,quota");

      final resp = await get(getInfoUri);

      if (isSuccess(resp)) {
        OneDriveUserInfo userInfo =
            OneDriveUserInfo.fromJson(jsonDecode(resp.body));
        CloudLogger.infoResponse(
            serviceName, "Get info successfully: $userInfo", resp);
        return OneDriveResponse.fromResponse(
          response: resp,
          userInfo: userInfo,
          message: "Get Info successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "Get info failed: ", resp);
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Error when getting info.",
        );
      }
    } catch (e, t) {
      CloudLogger.error(serviceName, "Get info error", e, t);
      return OneDriveResponse.error(message: "List files error: $e");
    }
  }

  @override
  Future<OneDriveResponse> list(String remotePath) async {
    try {
      await checkFolder(remotePath);

      final listUri = Uri.parse(
          "$apiEndpoint/me/drive/${_getRootFolder()}:$remotePath:/children?select=id,name,size,createdDateTime,lastModifiedDateTime,file,description");

      final resp = await get(listUri);

      if (isSuccess(resp)) {
        Map body = jsonDecode(resp.body);
        List<OneDriveFileInfo> files = [];
        for (var item in body['value']) {
          files.add(OneDriveFileInfo.fromJson(item));
        }
        CloudLogger.infoResponse(
            serviceName, "List files successfully: $files", resp);
        return OneDriveResponse.fromResponse(
          response: resp,
          files: files,
          message: "List files successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "List files failed: ", resp);
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Error when listing files.",
        );
      }
    } catch (e, t) {
      CloudLogger.error(serviceName, "List files error", e, t);
      return OneDriveResponse.error(message: "List files error: $e");
    }
  }

  @override
  Future<OneDriveResponse> pullById(String id) async {
    try {
      final pullUri = Uri.parse("$apiEndpoint/me/drive/items/$id/content");

      final resp = await get(pullUri);

      if (isSuccess(resp)) {
        CloudLogger.info(serviceName, "Pull file successfully");
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Pull file successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "Pull file failed", resp);
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Error when pulling file.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(serviceName, "Pull file error", err, trace);
      return OneDriveResponse.error(message: "Pull file error: $err");
    }
  }

  @override
  Future<OneDriveResponse> deleteById(
    String id, {
    bool isAppFolder = false,
  }) async {
    try {
      final deleteUri = Uri.parse("$apiEndpoint/me/drive/items/$id");

      final resp = await delete(deleteUri);

      if (isSuccess(resp)) {
        CloudLogger.infoResponse(serviceName, "Delete file successfully", resp);
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Delete file successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "Delete file failed", resp);
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Error when deleting file.",
        );
      }
    } catch (e, t) {
      CloudLogger.error(serviceName, "Delete file error", e, t);
      return OneDriveResponse.error(message: "Delete file error: $e");
    }
  }

  @override
  Future<OneDriveResponse> push(
    Uint8List bytes,
    String remotePath, {
    Function(int p1, int p2)? onProgress,
  }) async {
    try {
      await checkFolder(remotePath);

      const int pageSize = 1024 * 1024;
      final int maxPage = (bytes.length / pageSize.toDouble()).ceil();

      var now = DateTime.now();
      var pushUri = Uri.parse(
          "$apiEndpoint/me/drive/${_getRootFolder()}:$remotePath:/createUploadSession");

      var resp = await post(pushUri);

      if (isSuccess(resp)) {
        CloudLogger.infoResponse(
            serviceName,
            "Created upload session: ${DateTime.now().difference(now).inMilliseconds} ms",
            resp);

        final Uri uploadUri = Uri.parse(jsonDecode(resp.body)["uploadUrl"]);

        for (var pageIndex = 0; pageIndex < maxPage; pageIndex++) {
          now = DateTime.now();
          final int start = pageIndex * pageSize;
          int end = start + pageSize;
          if (end > bytes.length) {
            end = bytes.length; // cannot exceed max length
          }
          final range = "bytes $start-${end - 1}/${bytes.length}";
          final pageData = bytes.getRange(start, end).toList();
          final contentLength = pageData.length.toString();

          resp = await http.put(
            uploadUri,
            headers: {
              "Content-Length": contentLength,
              "Content-Range": range,
            },
            body: pageData,
          );

          CloudLogger.infoResponse(
              serviceName,
              "Upload [${pageIndex + 1}/$maxPage]: ${DateTime.now().difference(now).inMilliseconds} ms, start: $start, end: $end, contentLength: $contentLength, range: $range",
              resp);

          if (resp.statusCode == 202) {
            onProgress?.call(pageIndex + 1, maxPage);
            continue;
          } else if (isSuccess(resp)) {
            onProgress?.call(pageIndex + 1, maxPage);
            CloudLogger.infoResponse(
                serviceName, "Upload finished successfully", resp);
            return OneDriveResponse.fromResponse(
              response: resp,
              message: "Upload finished successfully.",
            );
          } else {
            CloudLogger.errorResponse(serviceName, "Upload failed", resp);
            return OneDriveResponse.fromResponse(
              response: resp,
              message: "Upload failed.",
            );
          }
        }
      } else {
        CloudLogger.errorResponse(
            serviceName, "Create upload session failed", resp);
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Error when creating upload session.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(serviceName, "Upload error", err, trace);
      return OneDriveResponse.error(message: "Unexpected exception: $err");
    }

    return OneDriveResponse.error(message: "Unexpected error.");
  }

  @override
  Future<void> checkFolder(String remotePath) async {
    try {
      final checkFolderUri =
          Uri.parse("$apiEndpoint/me/drive/${_getRootFolder()}/children");

      final resp = await post(
        checkFolderUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": remotePath.replaceAll("/", ""),
          "folder": {},
          "@microsoft.graph.conflictBehavior": "replace",
        }),
      );

      if (isSuccess(resp)) {
        CloudLogger.infoResponse(serviceName, "create folder success", resp);
      } else {
        CloudLogger.errorResponse(serviceName, "create folder failed", resp);
      }
    } catch (err, trace) {
      CloudLogger.error(serviceName, "create folder error", err, trace);
    }
  }
}
