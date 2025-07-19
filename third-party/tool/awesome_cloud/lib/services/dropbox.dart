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
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import 'base_service.dart';

class Dropbox extends BaseCloudService {
  @override
  String get serviceId => "Dropbox";

  @override
  String get serviceName => "Dropbox";

  @override
  String get authEndpoint => "https://www.dropbox.com/oauth2/authorize";

  @override
  String get tokenEndpoint =>
      "https://${BaseCloudService.proxyEndpoint}api.dropbox.com/oauth2/token";

  @override
  String get revokeEndpoint =>
      "https://${BaseCloudService.proxyEndpoint}api.dropboxapi.com/2/auth/token/revoke";

  @override
  String get apiEndpoint =>
      "https://${BaseCloudService.proxyEndpoint}api.dropboxapi.com/2";

  @override
  String get permission =>
      "account_info.read files.metadata.write files.metadata.read files.content.write files.content.read file_requests.write file_requests.read";

  @override
  String get expireInKey => "__dropbox_tokenExpire";

  @override
  String get accessTokenKey => "__dropbox_accessToken";

  @override
  String get refreshTokenKey => "__dropbox_refreshToken";

  @override
  String get idTokenKey => "__dropbox_idToken";

  @override
  String get rawRespKey => "__dropbox_rawResp";

  String get apiContentEndpoint => "https://content.dropboxapi.com/2";

  Dropbox({
    required super.clientId,
    required super.callbackUrl,
    String scopes = "",
    ITokenManager? tokenManager,
  });

  @override
  Future<void> disconnect() async {
    try {
      final accessToken = await checkToken();
      Uri uri = Uri.parse(revokeEndpoint);
      final resp = await http.post(
        uri,
        headers: {"Authorization": "Bearer $accessToken"},
      );
      CloudLogger.infoResponse(serviceName, "Revoke access token", resp);
    } catch (err, trace) {
      CloudLogger.error(serviceName, "Error while disconnect:", err, trace);
    } finally {
      await tokenManager.clearToken();
      notifyListeners();
    }
  }

  @override
  Future<DropboxResponse> getInfo() async {
    try {
      final url = Uri.parse("$apiEndpoint/users/get_current_account");
      final storageUrl = Uri.parse("$apiEndpoint/users/get_space_usage");

      final resp = await post(url);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        CloudLogger.infoResponse(serviceName, "Get info success", resp);
        final usageResp = await post(storageUrl);

        if (usageResp.statusCode == 200 || usageResp.statusCode == 201) {
          CloudLogger.infoResponse(
              serviceName, "Get storage info success", usageResp);
          return DropboxResponse.fromResponse(
            response: usageResp,
            userInfo: DropboxUserInfo.fromJson(
                jsonDecode(resp.body), jsonDecode(usageResp.body)),
            message: "Get Info successfully.",
          );
        } else {
          CloudLogger.errorResponse(
              serviceName, "Get storage info failed", usageResp);
          return DropboxResponse.fromResponse(
            response: usageResp,
            message: "Error while get storage info.",
          );
        }
      } else {
        CloudLogger.error(serviceName, "Get info failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while get info.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(serviceName, "Get info error", err, trace);
      return DropboxResponse.error(message: "Unexpected exception: $err");
    }
  }

  String removeLeadingSlash(String str) {
    return str.replaceFirst(RegExp(r'^/+'), '');
  }

  @override
  Future<DropboxResponse> list(String remotePath) async {
    try {
      final url = Uri.parse("$apiEndpoint/files/list_folder");
      final resp = await post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "include_deleted": false,
          "include_has_explicit_shared_members": false,
          "include_media_info": false,
          "include_mounted_folders": true,
          "include_non_downloadable_files": true,
          "path": removeLeadingSlash(remotePath),
          "recursive": false
        }),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Map body = jsonDecode(resp.body);
        List<DropboxFileInfo> files = [];
        for (var item in body['entries']) {
          if (item['.tag'] == "folder") continue;
          files.add(DropboxFileInfo.fromJson(item));
        }
        CloudLogger.infoResponse(serviceName, "List files success", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          files: files,
          message: "List files successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "List files failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while listing files.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(serviceName, "List files error", err, trace);
      return DropboxResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<DropboxResponse> pullById(String id) async {
    try {
      final url = Uri.parse("$apiContentEndpoint/files/download");

      final resp = await get(
        url,
        headers: {
          "Dropbox-API-Arg": jsonEncode({
            "path": id,
          }),
        },
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        CloudLogger.infoResponse(serviceName, "pull successfully", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Download successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "pull failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while downloading file.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(serviceName, "pull error", err, trace);
      return DropboxResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<DropboxResponse> deleteById(String id) async {
    try {
      final deleteUri = Uri.parse("$apiEndpoint/files/delete_v2");

      final resp = await post(
        deleteUri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"path": id}),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        CloudLogger.infoResponse(serviceName, "delete successfully", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Delete successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "delete failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while deleting file.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(serviceName, "delete error", err, trace);
      return DropboxResponse.error(message: "Unexpected exception: $err");
    }
  }

  Future<DropboxResponse> deleteBatch(List<String> paths) async {
    try {
      final url = Uri.parse("$apiEndpoint/files/delete_batch");

      final resp = await post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(
          {
            "entries": paths.map((e) => {"path": e}).toList()
          },
        ),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        CloudLogger.infoResponse(serviceName, "deleteBatch successfully", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Delete batch successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "deleteBatch failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while deleting file.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(serviceName, "deleteBatch error", err, trace);
      return DropboxResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<DropboxResponse> push(
    Uint8List bytes,
    String remotePath,
    String fileName, {
    Function(int p1, int p2)? onProgress,
  }) async {
    try {
      var url = Uri.parse("$apiContentEndpoint/files/upload");

      var resp = await post(
        url,
        headers: {
          "Dropbox-API-Arg": jsonEncode({
            "autorename": false,
            "mode": "add",
            "mute": false,
            "path": join(remotePath, fileName),
            "strict_conflict": false
          }),
          "Content-Type": "application/octet-stream",
        },
        body: bytes,
      );

      if (isSuccess(resp)) {
        onProgress?.call(1, 1);
        CloudLogger.infoResponse(serviceName, "Upload successfully", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Upload finished.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "Upload failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Upload failed.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(serviceName, "Upload error", err, trace);
      return DropboxResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<void> checkFolder(String remotePath) async {}
}
