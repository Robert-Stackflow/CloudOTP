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
import 'package:http_parser/http_parser.dart';

class HuaweiCloud extends BaseCloudService {
  @override
  String get serviceId => "HuaweiCloud";

  @override
  String get serviceName => "HuaweiCloud";

  @override
  String get authEndpoint => "https://$authHost/oauth2/v3/authorize";

  @override
  String get revokeEndpoint => "https://$authHost/oauth2/v3/revoke";

  @override
  String get tokenEndpoint => "https://$authHost/oauth2/v3/token";

  @override
  String get apiEndpoint => "https://driveapis.cloud.huawei.com.cn/drive/v1";

  @override
  String get permission => "openid https://www.huawei.com/auth/drive.file";

  @override
  String get expireInKey => "__huaweicloud_tokenExpire";

  @override
  String get accessTokenKey => "__huaweicloud_accessToken";

  @override
  String get refreshTokenKey => "__huaweicloud_refreshToken";

  @override
  String get idTokenKey => "__huaweicloud_idToken";

  @override
  String get rawRespKey => "__huaweicloud_rawResp";

  String get authHost => "oauth-login.cloud.huawei.com";

  String get uploadApiEndpoint =>
      "https://driveapis.cloud.huawei.com.cn/upload/drive/v1/files";

  HuaweiCloud({
    required super.clientId,
    required super.callbackUrl,
    String scopes = "",
    ITokenManager? tokenManager,
  });

  HuaweiCloud.server({
    required super.clientId,
    required super.callbackUrl,
    required super.customAuthEndpoint,
    required super.customTokenEndpoint,
    required super.customRevokeEndpoint,
    String scopes = "",
    ITokenManager? tokenManager,
  }) : super.server();

  @override
  Future<HuaweiCloudResponse> getInfo() async {
    CloudLogger.info(serviceName, "Start get info");
    try {
      final getInfoUri = Uri.parse("$apiEndpoint/about?fields=*");
      final resp = await get(getInfoUri);

      if (isSuccess(resp)) {
        HuaweiCloudUserInfo userInfo =
            HuaweiCloudUserInfo.fromJson(jsonDecode(resp.body));
        CloudLogger.infoResponse(serviceName, "Get info successfully", resp);
        return HuaweiCloudResponse.fromResponse(
          response: resp,
          userInfo: userInfo,
          message: "Get Info successfully.",
        );
      } else {
        await disconnect();
        CloudLogger.errorResponse(serviceName, "Get info failed", resp);
        return HuaweiCloudResponse.fromResponse(
          response: resp,
          message: "Failed to get info.",
        );
      }
    } catch (err) {
      CloudLogger.error(serviceName, "Get info error: $err", err);
      return HuaweiCloudResponse.error(message: "Unexpected exception: $err");
    }
  }

  String buildQueryParam({
    String? parentId,
    bool? onlyFile,
    bool? onlyFolder,
    String? fileName,
    String? nameContains,
    bool? favorite,
    bool? recycled,
    bool? directlyRecycled,
    DateTime? editedAfter,
    DateTime? editedBefore,
    List<String>? extraConditions,
    String? q,
  }) {
    final List<String> conditions = [];

    if (parentId != null && parentId.isNotEmpty) {
      conditions.add("'$parentId' in parentFolder");
    }

    if (onlyFile == true) {
      conditions.add("mimeType != 'application/vnd.huawei-apps.folder'");
    }

    if (onlyFolder == true) {
      conditions.add("mimeType = 'application/vnd.huawei-apps.folder'");
    }

    if (fileName != null) {
      conditions.add("fileName = '$fileName'");
    } else if (nameContains != null) {
      conditions.add("fileName contains '$nameContains'");
    }

    if (favorite != null) {
      conditions.add("favorite = ${favorite.toString()}");
    }

    if (recycled != null) {
      conditions.add("recycled = ${recycled.toString()}");
    }

    if (directlyRecycled != null) {
      conditions.add("directlyRecycled = ${directlyRecycled.toString()}");
    }

    if (editedAfter != null) {
      conditions
          .add("editedTime >= '${editedAfter.toUtc().toIso8601String()}'");
    }

    if (editedBefore != null) {
      conditions
          .add("editedTime <= '${editedBefore.toUtc().toIso8601String()}'");
    }

    if (extraConditions != null && extraConditions.isNotEmpty) {
      conditions.addAll(extraConditions);
    }

    if (q != null && q.trim().isNotEmpty) {
      conditions.add("($q)");
    }

    return conditions.join(" and ");
  }

  @override
  Future<HuaweiCloudResponse> list(
    String remotePath, {
    bool onlyFile = true,
    bool onlyFolder = false,
    String? q,
  }) async {
    try {
      String folderId = "";
      if (remotePath.isNotEmpty) {
        final folderResp = await checkFolder(remotePath);
        if (!folderResp.isSuccess || folderResp.parentId == null) {
          return HuaweiCloudResponse.error(message: "Folder not found.");
        }
        folderId = folderResp.parentId!;
      }

      final query = buildQueryParam(
        parentId: folderId,
        onlyFile: onlyFile,
        onlyFolder: onlyFolder,
        q: q,
      );

      CloudLogger.info(serviceName,
          "Listing files from folder $folderId with query: $query");

      final listUri = Uri.parse('$apiEndpoint/files').replace(queryParameters: {
        "fields": "*",
        "queryParam": query,
      });

      final resp = await get(listUri);
      if (isSuccess(resp)) {
        Map body = jsonDecode(resp.body);
        List<HuaweiCloudFileInfo> files = [];
        for (var item in body['files']) {
          files.add(HuaweiCloudFileInfo.fromJson(item));
        }
        CloudLogger.infoResponse(serviceName, "List files successfully", resp);
        return HuaweiCloudResponse.fromResponse(
          response: resp,
          files: files,
          message: "List files successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "List files failed", resp);
        return HuaweiCloudResponse.fromResponse(
          response: resp,
          message: "Error while listing files.",
        );
      }
    } catch (err) {
      CloudLogger.error(serviceName, "List files error: $err", err);
      return HuaweiCloudResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<HuaweiCloudResponse> pullById(String id) async {
    CloudLogger.info(serviceName, "Start pull file by ID: $id");
    try {
      final pullUri = Uri.parse("$apiEndpoint/files/$id?form=content");
      final resp = await get(pullUri);

      if (isSuccess(resp)) {
        CloudLogger.infoResponse(serviceName, "Pull file success", resp);
        return HuaweiCloudResponse.fromResponse(
          message: "Download successfully.",
          response: resp,
        );
      } else {
        CloudLogger.errorResponse(serviceName, "Pull file failed", resp);
        return HuaweiCloudResponse.fromResponse(
          response: resp,
          message: "Error when pulling file.",
        );
      }
    } catch (err) {
      CloudLogger.error(serviceName, "Pull file error: $err", err);
      return HuaweiCloudResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<HuaweiCloudResponse> deleteById(String id) async {
    CloudLogger.info(serviceName, "Start delete file by ID: $id");
    try {
      final deleteUri = Uri.parse("$apiEndpoint/files/$id");
      final resp = await delete(deleteUri);

      CloudLogger.infoResponse(serviceName, "Delete file response", resp);

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return HuaweiCloudResponse.fromResponse(
          response: resp,
          message: "Delete successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "Delete file failed", resp);
        return HuaweiCloudResponse.fromResponse(
          response: resp,
          message: "Error while deleting file.",
        );
      }
    } catch (err) {
      CloudLogger.error(serviceName, "Delete file error: $err", err);
      return HuaweiCloudResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<HuaweiCloudResponse> push(
    Uint8List bytes,
    String remotePath,
    String fileName, {
    Function(int, int)? onProgress,
  }) async {
    CloudLogger.info(
        serviceName, "Start uploading file: $fileName to $remotePath");

    try {
      String parentId = (await checkFolder(remotePath)).parentId ?? "";
      var pushUri =
          Uri.parse("$uploadApiEndpoint?uploadType=multipart&fields=*");

      var boundary = 'OP8XTaXZ0UZs-Sjlefcj2OWskqXWwVQO';
      final accessToken = await checkToken();
      var headers = {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "multipart/related; boundary=$boundary",
        'Cache-Control': 'no-cache',
      };

      var request = MyMultipartRequest('POST', pushUri, boundary);
      request.headers.addAll(headers);

      var jsonPart = jsonEncode({
        "fileName": fileName,
        "parentFolder": [parentId],
      });

      request.files.add(http.MultipartFile.fromString(
        "",
        jsonPart,
        contentType: MediaType("application", "json"),
      ));

      request.files.add(http.MultipartFile.fromBytes(
        '',
        bytes,
        contentType: MediaType('application', 'octet-stream'),
      ));

      http.StreamedResponse resp = (await request.send());
      Uint8List bodyBytes = await resp.stream.toBytes();
      String body = utf8.decode(bodyBytes);

      if (isStreamSuccess(resp)) {
        onProgress?.call(1, 1);
        CloudLogger.info(serviceName, "Upload finished: $fileName");
        return HuaweiCloudResponse.success(
          statusCode: resp.statusCode,
          body: body,
          bodyBytes: bodyBytes,
          message: "Upload finished.",
        );
      } else {
        CloudLogger.error(serviceName, "Upload failed: $body");
        return HuaweiCloudResponse.error(
          statusCode: resp.statusCode,
          body: body,
          bodyBytes: bodyBytes,
          message: "Upload failed.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(serviceName, "Upload error: $err\n$trace", err);
      return HuaweiCloudResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<HuaweiCloudResponse> checkFolder(String remotePath) async {
    CloudLogger.info(serviceName, "Start checking folder: $remotePath");

    try {
      HuaweiCloudResponse res =
          await list("", onlyFile: false, onlyFolder: true);

      if (!res.isSuccess) {
        CloudLogger.error(serviceName, "Failed to list folders");
        return res;
      }

      for (var file in res.files) {
        if (file.name == remotePath &&
            file.fileMimeType == "application/vnd.huawei-apps.folder") {
          CloudLogger.info(
              serviceName, "Folder exists: $remotePath -> ${file.id}");
          return HuaweiCloudResponse.success(
            parentId: file.id,
            message: "Directory already exists.",
          );
        }
      }

      final url = Uri.parse("$apiEndpoint/files?fields=*");

      final resp = await post(
        url,
        body: jsonEncode({
          "fileName": remotePath,
          "mimeType": "application/vnd.huawei-apps.folder",
        }),
      );

      if (isSuccess(resp)) {
        CloudLogger.infoResponse(
            serviceName, "Created folder: $remotePath", resp);
        return HuaweiCloudResponse.fromResponse(
          response: resp,
          parentId: jsonDecode(resp.body)["id"],
          message: "Create directory successfully.",
        );
      } else {
        CloudLogger.errorResponse(serviceName, "Create folder failed", resp);
        return HuaweiCloudResponse.fromResponse(
          response: resp,
          message: "Error while creating directory.",
        );
      }
    } catch (err) {
      CloudLogger.error(serviceName, "Check/create folder error: $err", err);
      return HuaweiCloudResponse.error(message: "Unexpected exception.");
    }
  }
}
