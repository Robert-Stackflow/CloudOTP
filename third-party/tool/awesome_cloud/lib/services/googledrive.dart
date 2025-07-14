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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'base_service.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDrive extends BaseCloudService {
  @override
  String get serviceId => "GoogleDrive";

  @override
  String get serviceName => "GoogleDrive";

  @override
  String get authEndpoint => "https://accounts.google.com/o/oauth2/v2/auth";

  @override
  String get tokenEndpoint => "https://www.googleapis.com/oauth2/v4/token";

  @override
  String get revokeEndpoint => "https://www.googleapis.com/oauth2/v4/revoke";

  @override
  String get apiEndpoint =>
      "https://proxy.cloudchewie.com/proxy/content.googleapis.com/drive/v3";

  @override
  String get permission => "https://www.googleapis.com/auth/drive.file";

  @override
  String get expireInKey => "__googledrive_tokenExpire";

  @override
  String get accessTokenKey => "__googledrive_accessToken";

  @override
  String get refreshTokenKey => "__googledrive_refreshToken";

  @override
  String get idTokenKey => "__googledrive_idToken";

  @override
  String get rawRespKey => "__googledrive_rawResp";

  String get apiUploadEndpoint =>
      "https://proxy.cloudchewie.com/proxy/www.googleapis.com/upload/drive/v3/files";

  GoogleDrive({
    required super.clientId,
    required super.callbackUrl,
    String scopes = "",
    ITokenManager? tokenManager,
  });

  GoogleDrive.server({
    required super.clientId,
    required super.callbackUrl,
    required super.customAuthEndpoint,
    required super.customTokenEndpoint,
    required super.customRevokeEndpoint,
    String scopes = "",
    ITokenManager? tokenManager,
  }) : super.server();

  Future<drive.DriveApi> getClient() async {
    final accessToken = await tokenManager.getAccessToken();

    final authenticateClient = GoogleAuthClient({
      "Authorization": "Bearer $accessToken",
    });
    final driveApi = drive.DriveApi(authenticateClient,
        rootUrl: "https://proxy.cloudchewie.com/proxy/www.googleapis.com/");
    return driveApi;
  }

  @override
  Future<GoogleDriveResponse> getInfo() async {
    try {
      final getInfoUri =
          Uri.parse("$apiEndpoint/about?fields=user,storageQuota");

      final resp = await get(getInfoUri);

      if (isSuccess(resp)) {
        GoogleDriveUserInfo userInfo =
            GoogleDriveUserInfo.fromJson(jsonDecode(resp.body));
        CloudLogger.infoResponse(
            serviceName, "Get info successfully: $userInfo", resp);
        return GoogleDriveResponse.fromResponse(
          response: resp,
          userInfo: userInfo,
          message: "Get Info successfully.",
        );
      } else if (resp.statusCode == 404) {
        CloudLogger.errorResponse(
          serviceName,
          "Get info failed: ${getInfoUri.toString()} not found.",
          resp,
        );
        return GoogleDriveResponse.fromResponse(
          response: resp,
          message: "${getInfoUri.toString()} not found.",
        );
      } else {
        CloudLogger.errorResponse(
          serviceName,
          "Error while getting info: ${resp.statusCode} ${resp.body}",
          resp,
        );
        return GoogleDriveResponse.fromResponse(
          response: resp,
          message: "Error while get info.",
        );
      }
    } catch (err) {
      CloudLogger.error(serviceName, "Exception while getting info: $err");
      return GoogleDriveResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<GoogleDriveResponse> list(String remotePath) async {
    try {
      drive.DriveApi driveApi = await getClient();

      CloudLogger.info(
        serviceName,
        "Listing files in Google Drive at path: $remotePath",
      );

      drive.FileList fileList = await driveApi.files.list(
        q: "mimeType='application/octet-stream' and trashed=false",
        $fields:
            "files(id,name,description,modifiedTime,createdTime,trashed,size)",
      );

      List<GoogleDriveFileInfo> fileInfos = (fileList.files ?? [])
          .map(
            (e) => GoogleDriveFileInfo(
              id: e.id ?? "",
              name: e.name ?? "",
              size: int.tryParse(e.size ?? "0") ?? 0,
              createdDateTime: e.createdTime?.millisecondsSinceEpoch ?? 0,
              lastModifiedDateTime: e.modifiedTime?.millisecondsSinceEpoch ?? 0,
              description: e.description ?? "",
              fileMimeType: e.mimeType ?? "",
            ),
          )
          .toList();

      if (fileInfos.isEmpty) {
        CloudLogger.info(serviceName, "No files found in Google Drive.");
        return GoogleDriveResponse.success(
          files: [],
          message: "No files found.",
        );
      }
      CloudLogger.info(
        serviceName,
        "List files successfully: ${fileInfos.length} files found.",
      );
      return GoogleDriveResponse.success(
        files: fileInfos,
        message: "List files successfully.",
      );
    } catch (err) {
      CloudLogger.error(serviceName, "Exception while listing files: $err");
      return GoogleDriveResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<GoogleDriveResponse> pullById(String id) async {
    try {
      drive.DriveApi driveApi = await getClient();

      CloudLogger.info(serviceName, "Downloading file with ID: $id");

      drive.Media media = await driveApi.files.get(
        id,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      if (media.length == 0) {
        CloudLogger.error(serviceName, "Media stream is null for file ID: $id");
        return GoogleDriveResponse.error(message: "File not found or empty.");
      }
      CloudLogger.info(serviceName, "Download successfully for file ID: $id");
      return GoogleDriveResponse.success(
        message: "Download successfully.",
        bodyBytes: await (media.stream as http.ByteStream).toBytes(),
      );
    } catch (err) {
      CloudLogger.error(serviceName, "Exception while downloading file: $err");
      return GoogleDriveResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<GoogleDriveResponse> deleteById(String id) async {
    try {
      drive.DriveApi driveApi = await getClient();

      CloudLogger.info(serviceName, "Deleting file with ID: $id");

      await driveApi.files.delete(id);

      return GoogleDriveResponse.success(message: "Delete successfully.");
    } catch (err) {
      CloudLogger.error(serviceName, "Exception while deleting file: $err");
      return GoogleDriveResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<GoogleDriveResponse> push(
    Uint8List bytes,
    String remotePath, {
    String fileName = "",
    Function(int p1, int p2)? onProgress,
  }) async {
    try {
      String parentId = (await checkFolder(remotePath)).parentId ?? "";

      drive.DriveApi driveApi = await getClient();

      CloudLogger.info(
          serviceName, "Uploading file to Google Drive: $fileName");

      drive.File res = await driveApi.files.create(
        drive.File.fromJson({
          "name": fileName,
          "parents": [parentId],
        }),
        uploadMedia: drive.Media(
          Stream.value(bytes.toList()),
          bytes.length,
          contentType: "application/octet-stream",
        ),
      );

      if (res.id == null) {
        CloudLogger.error(serviceName, "Upload failed: ${res.toJson()}");
        return GoogleDriveResponse.error(message: "Upload failed.");
      }
      CloudLogger.info(
          serviceName, "Upload successfully: ${res.id} ${res.name}");
      return GoogleDriveResponse.success(message: "Upload successfully.");
    } catch (err) {
      CloudLogger.error(serviceName, "Exception while uploading file: $err");
      return GoogleDriveResponse.error(message: "Unexpected exception: $err");
    }
  }

  @override
  Future<GoogleDriveResponse> checkFolder(String remotePath) async {
    try {
      drive.DriveApi driveApi = await getClient();

      drive.FileList fileList = await driveApi.files.list(
        q: "mimeType='application/vnd.google-apps.folder'",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        for (var file in fileList.files!) {
          if (file.name == remotePath) {
            CloudLogger.debug(serviceName, "Directory already exists.");
            return GoogleDriveResponse.success(
              parentId: file.id ?? "",
              message: "Directory already exists.",
            );
          }
        }
      }

      final url = Uri.parse("$apiEndpoint/files");

      final resp = await post(
        url,
        body: jsonEncode({
          "name": remotePath,
          "mimeType": "application/vnd.google-apps.folder",
        }),
      );

      if (isSuccess(resp)) {
        CloudLogger.infoResponse(
          serviceName,
          "Create directory successfully: ${jsonDecode(resp.body)["id"]}",
          resp,
        );
        return GoogleDriveResponse.fromResponse(
          response: resp,
          parentId: jsonDecode(resp.body)["id"],
          message: "Create directory successfully.",
        );
      } else if (resp.statusCode == 404) {
        CloudLogger.error(serviceName, "Url not found: ${url.toString()}");
        return GoogleDriveResponse.fromResponse(
          response: resp,
          message: "Url not found.",
        );
      } else {
        CloudLogger.error(
          serviceName,
          "Error while creating directory: ${resp.statusCode} ${resp.body}",
        );
        return GoogleDriveResponse.fromResponse(
          response: resp,
          message: "Error while creating directory.",
        );
      }
    } catch (err) {
      CloudLogger.error(
        serviceName,
        "Exception while checking folder: $err",
      );
      return GoogleDriveResponse.error(message: "Unexpected exception:$err");
    }
  }
}
