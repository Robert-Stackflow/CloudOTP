library flutter_cloud;

import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cloud/token_manager.dart';
import 'package:http/http.dart' as http;

import 'oauth2_helper.dart';
import 'onedrive_response.dart';

class OneDrive with ChangeNotifier {
  static const String authHost = "login.microsoftonline.com";
  static const String authEndpoint = "/consumers/oauth2/v2.0/authorize";
  static const String tokenEndpoint =
      "https://$authHost/consumers/oauth2/v2.0/token";
  static const String apiEndpoint = "https://graph.microsoft.com/v1.0/";
  static const String errCANCELED = "CANCELED";
  static const _appRootFolder = "special/approot";
  static const _defaultRootFolder = "root";
  static const permissionFilesReadWriteAll = "Files.ReadWrite.All";
  static const permissionOfflineAccess = "offline_access";

  static const String expireInKey = "__onedrive_tokenExpire";
  static const String accessTokenKey = "__onedrive_accessToken";
  static const String refreshTokenKey = "__onedrive_refreshToken";

  late final ITokenManager _tokenManager;
  late final String redirectUrl;
  late final String callbackUrl;
  final String scopes;
  final String clientId;

  late final String state;

  OneDrive({
    required this.clientId,
    required this.callbackUrl,
    required this.redirectUrl,
    this.scopes = "$permissionFilesReadWriteAll $permissionOfflineAccess",
    ITokenManager? tokenManager,
  }) {
    state = OAuth2Helper.generateStateParameter();
    _tokenManager = tokenManager ??
        DefaultTokenManager(
          tokenEndpoint: tokenEndpoint,
          clientId: clientId,
          redirectUrl: redirectUrl,
          scope: scopes,
          expireInKey: expireInKey,
          accessTokenKey: accessTokenKey,
          refreshTokenKey: refreshTokenKey,
        );
  }

  Future<bool> isConnected() async {
    final accessToken = await _tokenManager.getAccessToken();
    return (accessToken?.isNotEmpty) ?? false;
  }

  Future<bool> hasAuthorized() async {
    final accessToken = await _tokenManager.getAccessToken();
    return (accessToken?.isNotEmpty) ?? false;
  }

  Future<bool> connect(
    BuildContext context, {
    String? windowName,
  }) async {
    try {
      final authUri = Uri.https(authHost, authEndpoint, {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUrl,
        'scope': scopes,
        'state': state,
      });

      String callbackUrlScheme = "";

      Uri callbackUri = Uri.parse(callbackUrl);

      if (callbackUri.scheme != "http" && callbackUri.scheme != "https") {
        callbackUrlScheme = callbackUri.scheme;
      } else {
        callbackUrlScheme = callbackUri.toString();
      }

      http.Response? result = await OAuth2Helper.browserAuth(
        context: context,
        authEndpoint: authUri,
        tokenEndpoint: Uri.parse(tokenEndpoint),
        callbackUrl: callbackUrl,
        callbackUrlScheme: callbackUrlScheme,
        clientId: clientId,
        redirectUrl: redirectUrl,
        state: state,
        scopes: scopes,
        windowName: windowName,
      );
      if (result != null) {
        await _tokenManager.saveTokenResp(result);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } on PlatformException catch (err) {
      if (err.code != errCANCELED) {
        debugPrint("# OneDrive -> connect: $err");
      }
      return false;
    } catch (err) {
      debugPrint("# OneDrive -> connect: $err");
      return false;
    }
  }

  Future<void> disconnect() async {
    await _tokenManager.clearStoredToken();
    notifyListeners();
  }

  Future<OneDriveResponse> getInfo() async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      debugPrint("# OneDrive -> getInfo: Null access token");
      return OneDriveResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }
    final url = Uri.parse("$apiEndpoint/drive?select=owner,quota");

    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      debugPrint(
          "# OneDrive -> getInfo: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            userInfo: OneDriveUserInfo.fromJson(jsonDecode(resp.body)),
            message: "Get Info successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "${url.toString()} not found.",
            bodyBytes: Uint8List(0));
      } else {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while get info.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# OneDrive -> getInfo: $err");
      return OneDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Future<OneDriveResponse> list(
    String remotePath, {
    bool isAppFolder = false,
  }) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return OneDriveResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    if (isAppFolder) {
      await getMetadata(remotePath, isAppFolder: isAppFolder);
    }

    final url = Uri.parse(
        "${apiEndpoint}me/drive/${_getRootFolder(isAppFolder)}:$remotePath:/children?select=id,name,size,createdDateTime,lastModifiedDateTime,file,description");

    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Map body = jsonDecode(resp.body);
        List<OneDriveFileInfo> files = [];
        for (var item in body['value']) {
          files.add(OneDriveFileInfo.fromJson(item));
        }
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            files: files,
            message: "List files successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Url not found.",
            bodyBytes: Uint8List(0));
      } else {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while listing files.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# OneDrive -> list: $err");
      return OneDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Future<OneDriveResponse> pullById(
    String id, {
    bool isAppFolder = false,
  }) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return OneDriveResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    final url = Uri.parse("${apiEndpoint}me/drive/items/$id/content");

    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      debugPrint(
          "# OneDrive -> pull: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Download successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "File not found.",
            bodyBytes: Uint8List(0));
      } else {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while downloading file.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# OneDrive -> pull: $err");
      return OneDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Future<OneDriveResponse> deleteById(
    String id, {
    bool isAppFolder = false,
  }) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return OneDriveResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    final url = Uri.parse("${apiEndpoint}me/drive/items/$id");

    try {
      final resp = await http.delete(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      debugPrint(
          "# OneDrive -> delete: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Delete successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "File not found.",
            bodyBytes: Uint8List(0));
      } else {
        return OneDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while deleting file.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# OneDrive -> delete: $err");
      return OneDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Future<OneDriveResponse> push(
    Uint8List bytes,
    String remotePath, {
    bool isAppFolder = false,
    Function(int p1, int p2)? onProgress,
  }) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return OneDriveResponse(message: "Null access token.");
    }

    try {
      if (isAppFolder) {
        await getMetadata(remotePath, isAppFolder: isAppFolder);
      }

      const int pageSize = 1024 * 1024; // page size
      final int maxPage =
          (bytes.length / pageSize.toDouble()).ceil(); // total pages

      var now = DateTime.now();
      var url = Uri.parse(
          "$apiEndpoint/me/drive/${_getRootFolder(isAppFolder)}:$remotePath:/createUploadSession");

      var resp = await http.post(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );
      debugPrint(
          "# Create Session: ${DateTime.now().difference(now).inMilliseconds} ms");

      if (resp.statusCode == 200) {
        final Map<String, dynamic> respJson = jsonDecode(resp.body);
        final String uploadUrl = respJson["uploadUrl"];
        url = Uri.parse(uploadUrl);

        debugPrint(
            "# Upload to: $url\n# Total pages: $maxPage\n# Page size: $pageSize");

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

          final headers = {
            "Content-Length": contentLength,
            "Content-Range": range,
          };

          resp = await http.put(
            url,
            headers: headers,
            body: pageData,
          );

          debugPrint(
              "# Upload [${pageIndex + 1}/$maxPage]: ${DateTime.now().difference(now).inMilliseconds} ms, start: $start, end: $end, contentLength: $contentLength, range: $range");

          if (resp.statusCode == 202) {
            onProgress?.call(pageIndex + 1, maxPage);
            continue;
          } else if (resp.statusCode == 200 || resp.statusCode == 201) {
            onProgress?.call(pageIndex + 1, maxPage);
            return OneDriveResponse(
                statusCode: resp.statusCode,
                body: resp.body,
                message: "Upload finished.",
                isSuccess: true);
          } else {
            return OneDriveResponse(
                statusCode: resp.statusCode,
                body: resp.body,
                message: "Upload failed.");
          }
        }
      }

      debugPrint("# Upload response: ${resp.statusCode}\n# Body: ${resp.body}");
    } catch (err) {
      debugPrint("# Upload error: $err");
      return OneDriveResponse(message: "Unexpected exception: $err");
    }

    return OneDriveResponse(message: "Unexpected error.");
  }

  String _getRootFolder(bool isAppFolder) {
    return isAppFolder ? _appRootFolder : _defaultRootFolder;
  }

  Future<Uint8List?> getMetadata(
    String remotePath, {
    bool isAppFolder = false,
  }) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return Uint8List(0);
    }

    final url =
        Uri.parse("${apiEndpoint}me/drive/${_getRootFolder(isAppFolder)}");

    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return resp.bodyBytes;
      } else if (resp.statusCode == 404) {
        return Uint8List(0);
      }

      debugPrint(
          "# OneDrive -> metadata: ${resp.statusCode}\n# Body: ${resp.body}");
    } catch (err) {
      debugPrint("# OneDrive -> metadata: $err");
    }

    return null;
  }
}

class UploadStatus {
  final int index;
  final int total;
  final int start;
  final int end;
  final String contentLength;
  final String range;

  UploadStatus(
    this.index,
    this.total,
    this.start,
    this.end,
    this.contentLength,
    this.range,
  );
}
