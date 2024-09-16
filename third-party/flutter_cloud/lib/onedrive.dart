library flutter_cloud;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cloud/status.dart';
import 'package:flutter_cloud/token_manager.dart';
import 'package:http/http.dart' as http;

import 'oauth2_helper.dart';
import 'onedrive_response.dart';

class OneDrive with ChangeNotifier {
  static const String authEndpoint =
      "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize";
  static const String tokenEndpoint =
      "https://login.microsoftonline.com/consumers/oauth2/v2.0/token";
  static const String revokeEndpoint =
      "https://login.microsoftonline.com/consumers/oauth2/v2.0/revoke";
  static const String apiEndpoint = "https://graph.microsoft.com/v1.0";
  static const _appRootFolder = "special/approot";
  static const _defaultRootFolder = "root";
  static const permission = "Files.ReadWrite.All offline_access";

  static const String expireInKey = "__onedrive_tokenExpire";
  static const String accessTokenKey = "__onedrive_accessToken";
  static const String refreshTokenKey = "__onedrive_refreshToken";
  static const String idTokenKey = "__onedrive_idToken";

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
    this.scopes = permission,
    ITokenManager? tokenManager,
  }) {
    state = OAuth2Helper.generateStateParameter();
    _tokenManager = tokenManager ??
        DefaultTokenManager(
          tokenEndpoint: tokenEndpoint,
          clientId: clientId,
          redirectUrl: redirectUrl,
          revokeUrl: revokeEndpoint,
          scope: scopes,
          expireAtKey: expireInKey,
          accessTokenKey: accessTokenKey,
          refreshTokenKey: refreshTokenKey,
          idTokenKey: idTokenKey,
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

  Future<bool> connect() async {
    try {
      String codeVerifier = OAuth2Helper.generateCodeVerifier();

      String codeChanllenge = OAuth2Helper.generateCodeChanllenge(codeVerifier);

      Uri uri = Uri.parse(authEndpoint);
      final authUri = Uri.https(uri.authority, uri.path, {
        'code_challenge': codeChanllenge,
        "code_challenge_method": "S256",
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

      http.Response? result = await OAuth2Helper.browserAuthWithVerifier(
        authEndpoint: authUri,
        tokenEndpoint: Uri.parse(tokenEndpoint),
        callbackUrl: callbackUrl,
        callbackUrlScheme: callbackUrlScheme,
        clientId: clientId,
        redirectUrl: redirectUrl,
        state: state,
        scopes: scopes,
        codeVerifier: codeVerifier,
      );
      if (result != null) {
        await _tokenManager.saveTokenResp(result);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } on PlatformException {
      return false;
    } catch (err) {
      debugPrint("# OneDrive -> connect error: $err");
      return false;
    }
  }

  Future<void> disconnect() async {
    await _tokenManager.clearStoredToken();
    notifyListeners();
  }

  Future<String> checkToken() async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      throw NullAccessTokenException();
    } else {
      return accessToken;
    }
  }

  http.Response processResponse(http.Response response) {
    if (response.statusCode == 401) {
      disconnect();
    }
    return response;
  }

  Future<http.Response> post(
    Uri url, {
    dynamic headers,
    dynamic body,
  }) async {
    final accessToken = await checkToken();
    var tmpHeaders = {"Authorization": "Bearer $accessToken"};
    if (headers != null) {
      tmpHeaders.addAll(headers);
    }
    return processResponse(await http.post(
      url,
      headers: tmpHeaders,
      body: body,
    ));
  }

  Future<http.Response> get(
    Uri url, {
    dynamic headers,
  }) async {
    final accessToken = await checkToken();
    var tmpHeaders = {"Authorization": "Bearer $accessToken"};
    if (headers != null) {
      tmpHeaders.addAll(headers);
    }
    return processResponse(await http.get(
      url,
      headers: tmpHeaders,
    ));
  }

  Future<http.Response> delete(
    Uri url, {
    dynamic headers,
  }) async {
    final accessToken = await checkToken();
    var tmpHeaders = {"Authorization": "Bearer $accessToken"};
    if (headers != null) {
      tmpHeaders.addAll(headers);
    }
    return processResponse(await http.delete(
      url,
      headers: tmpHeaders,
    ));
  }

  Future<OneDriveResponse> getInfo() async {
    try {
      final url = Uri.parse("$apiEndpoint/drive?select=owner,quota");

      final resp = await get(url);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        OneDriveUserInfo userInfo =
            OneDriveUserInfo.fromJson(jsonDecode(resp.body));
        debugPrint("# OneDrive -> get info successfully: $userInfo");
        return OneDriveResponse.fromResponse(
          response: resp,
          userInfo: userInfo,
          message: "Get Info successfully.",
        );
      } else {
        debugPrint(
            "# OneDrive -> get info failed: ${resp.statusCode}\n# Body: ${resp.body}");
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Error while get info.",
        );
      }
    } catch (err) {
      debugPrint("# OneDrive -> getInfo error: $err");
      return OneDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Future<OneDriveResponse> list(
    String remotePath, {
    bool isAppFolder = false,
  }) async {
    try {
      await createFolder(remotePath, isAppFolder: isAppFolder);

      final url = Uri.parse(
          "$apiEndpoint/me/drive/${_getRootFolder(isAppFolder)}:$remotePath:/children?select=id,name,size,createdDateTime,lastModifiedDateTime,file,description");

      final resp = await get(url);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Map body = jsonDecode(resp.body);
        List<OneDriveFileInfo> files = [];
        for (var item in body['value']) {
          files.add(OneDriveFileInfo.fromJson(item));
        }
        debugPrint("# OneDrive -> list successfully");
        return OneDriveResponse.fromResponse(
          response: resp,
          files: files,
          message: "List files successfully.",
        );
      } else {
        debugPrint(
            "# OneDrive -> list failed: ${resp.statusCode}\n# Body: ${resp.body}");
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Error while listing files.",
        );
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
    try {
      final url = Uri.parse("$apiEndpoint/me/drive/items/$id/content");

      final resp = await get(url);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        debugPrint("# OneDrive -> pull successfully");
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Download successfully.",
        );
      } else {
        debugPrint(
            "# OneDrive -> pull failed: ${resp.statusCode}\n# Body: ${resp.body}");
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Error while downloading file.",
        );
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
    try {
      final url = Uri.parse("$apiEndpoint/me/drive/items/$id");

      final resp = await delete(url);

      if (resp.statusCode == 200 ||
          resp.statusCode == 201 ||
          resp.statusCode == 204) {
        debugPrint("# OneDrive -> delete successfully");
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Delete successfully.",
        );
      } else {
        debugPrint(
            "# OneDrive -> delete failed: ${resp.statusCode}\n# Body: ${resp.body}");
        return OneDriveResponse.fromResponse(
          response: resp,
          message: "Error while deleting file.",
        );
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
    try {
      await createFolder(remotePath, isAppFolder: isAppFolder);

      const int pageSize = 1024 * 1024;
      final int maxPage = (bytes.length / pageSize.toDouble()).ceil();

      var now = DateTime.now();
      var url = Uri.parse(
          "$apiEndpoint/me/drive/${_getRootFolder(isAppFolder)}:$remotePath:/createUploadSession");

      var resp = await post(url);

      debugPrint(
          "# OneDrive -> Upload Create Session: ${DateTime.now().difference(now).inMilliseconds} ms");

      if (resp.statusCode == 200) {
        final Map<String, dynamic> respJson = jsonDecode(resp.body);
        final String uploadUrl = respJson["uploadUrl"];
        url = Uri.parse(uploadUrl);

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
            url,
            headers: {
              "Content-Length": contentLength,
              "Content-Range": range,
            },
            body: pageData,
          );

          debugPrint(
              "# OneDrive -> Upload [${pageIndex + 1}/$maxPage]: ${DateTime.now().difference(now).inMilliseconds} ms, start: $start, end: $end, contentLength: $contentLength, range: $range");

          if (resp.statusCode == 202) {
            onProgress?.call(pageIndex + 1, maxPage);
            continue;
          } else if (resp.statusCode == 200 || resp.statusCode == 201) {
            onProgress?.call(pageIndex + 1, maxPage);
            debugPrint("# OneDrive -> Upload finished");
            return OneDriveResponse.fromResponse(
              response: resp,
              message: "Upload finished.",
            );
          } else {
            debugPrint(
                "# OneDrive -> Upload failed: ${resp.statusCode}\n# Body: ${resp.body}");
            return OneDriveResponse.fromResponse(
              response: resp,
              message: "Upload failed.",
            );
          }
        }
      }
    } catch (err) {
      debugPrint("# OneDrive -> Upload error: $err");
      return OneDriveResponse(message: "Unexpected exception: $err");
    }

    return OneDriveResponse(message: "Unexpected error.");
  }

  String _getRootFolder(bool isAppFolder) {
    return isAppFolder ? _appRootFolder : _defaultRootFolder;
  }

  Future<void> createFolder(
    String remotePath, {
    bool isAppFolder = false,
  }) async {
    try {
      final url = Uri.parse(
          "$apiEndpoint/me/drive/${_getRootFolder(isAppFolder)}/children");

      final resp = await post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": remotePath.replaceAll("/", ""),
          "folder": {},
          "@microsoft.graph.conflictBehavior": "replace",
        }),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        debugPrint("# OneDrive -> create folder success: ${resp.body}");
      } else {
        debugPrint(
            "# OneDrive -> create folder failed: ${resp.statusCode}\n# Body: ${resp.body}");
      }
    } catch (err) {
      debugPrint("# OneDrive -> create folder: $err");
    }
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
