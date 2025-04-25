library flutter_cloud;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cloud/status.dart';
import 'package:flutter_cloud/token_manager.dart';
import 'package:http/http.dart' as http;

import 'cloud_logger.dart';
import 'dropbox_response.dart';
import 'oauth2_helper.dart';

class Dropbox with ChangeNotifier {
  static const String authEndpoint = "https://www.dropbox.com/oauth2/authorize";
  static const String tokenEndpoint = "https://api.dropbox.com/oauth2/token";
  static const String revokeEndpoint =
      "https://api.dropboxapi.com/2/auth/token/revoke";
  static const String apiContentEndpoint = "https://content.dropboxapi.com/2";
  static const String apiEndpoint = "https://api.dropboxapi.com/2";
  static const permission =
      "account_info.read files.metadata.write files.metadata.read files.content.write files.content.read file_requests.write file_requests.read";

  static const String expireInKey = "__dropbox_tokenExpire";
  static const String accessTokenKey = "__dropbox_accessToken";
  static const String refreshTokenKey = "__dropbox_refreshToken";
  static const String idTokenKey = "__dropbox_idToken";

  late final ITokenManager _tokenManager;
  late final String redirectUrl;
  late final String callbackUrl;
  final String scopes;
  final String clientId;
  late final String state;

  static const String TAG = "Dropbox";

  Dropbox({
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
        'client_id': clientId,
        'redirect_uri': redirectUrl,
        "response_type": "code",
        "token_access_type": "offline",
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
        codeVerifier: codeVerifier,
        scopes: scopes,
        state: state,
      );

      if (result != null &&
          (result.statusCode == 200 || result.statusCode == 201)) {
        await _tokenManager.saveTokenResp(result);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } on PlatformException {
      return false;
    } catch (err, trace) {
      CloudLogger.error(TAG, "Error while connect:", err, trace);
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      final accessToken = await checkToken();
      Uri uri = Uri.parse(revokeEndpoint);
      final resp = await http.post(
        uri,
        headers: {"Authorization": "Bearer $accessToken"},
      );
      CloudLogger.infoResponse(TAG, "Revoke access token", resp);
    } catch (err, trace) {
      CloudLogger.error(TAG, "Error while disconnect:", err, trace);
    } finally {
      await _tokenManager.clearStoredToken();
      notifyListeners();
    }
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

  Future<DropboxResponse> getInfo() async {
    try {
      final url = Uri.parse("$apiEndpoint/users/get_current_account");
      final storageUrl = Uri.parse("$apiEndpoint/users/get_space_usage");

      final resp = await post(url);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        CloudLogger.infoResponse(TAG, "Get info success", resp);
        final usageResp = await post(storageUrl);

        if (usageResp.statusCode == 200 || usageResp.statusCode == 201) {
          CloudLogger.infoResponse(TAG, "Get storage info success", usageResp);
          return DropboxResponse.fromResponse(
            response: usageResp,
            userInfo: DropboxUserInfo.fromJson(
                jsonDecode(resp.body), jsonDecode(usageResp.body)),
            message: "Get Info successfully.",
          );
        } else {
          CloudLogger.errorResponse(TAG, "Get storage info failed", usageResp);
          return DropboxResponse.fromResponse(
            response: usageResp,
            message: "Error while get storage info.",
          );
        }
      } else {
        CloudLogger.error(TAG, "Get info failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while get info.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(TAG, "Get info error", err, trace);
      return DropboxResponse(message: "Unexpected exception: $err");
    }
  }

  Future<DropboxResponse> list(String remotePath) async {
    try {
      final url = Uri.parse("$apiEndpoint//files/list_folder");
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
          "path": remotePath,
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
        CloudLogger.infoResponse(TAG, "List files success", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          files: files,
          message: "List files successfully.",
        );
      } else {
        CloudLogger.errorResponse(TAG, "List files failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while listing files.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(TAG, "List files error", err, trace);
      return DropboxResponse(message: "Unexpected exception: $err");
    }
  }

  Future<DropboxResponse> pull(
    String path,
  ) async {
    try {
      final url = Uri.parse("$apiContentEndpoint/files/download");

      final resp = await get(
        url,
        headers: {
          "Dropbox-API-Arg": jsonEncode({
            "path": path,
          }),
        },
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        CloudLogger.infoResponse(TAG, "pull successfully", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Download successfully.",
        );
      } else {
        CloudLogger.errorResponse(TAG, "pull failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while downloading file.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(TAG, "pull error", err, trace);
      return DropboxResponse(message: "Unexpected exception: $err");
    }
  }

  Future<DropboxResponse> delete(String path) async {
    try {
      final url = Uri.parse("$apiEndpoint/files/delete_v2");

      final resp = await post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"path": path}),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        CloudLogger.infoResponse(TAG, "delete successfully", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Delete successfully.",
        );
      } else {
        CloudLogger.errorResponse(TAG, "delete failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while deleting file.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(TAG, "delete error", err, trace);
      return DropboxResponse(message: "Unexpected exception: $err");
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
        CloudLogger.infoResponse(TAG, "deleteBatch successfully", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Delete batch successfully.",
        );
      } else {
        CloudLogger.errorResponse(TAG, "deleteBatch failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while deleting file.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(TAG, "deleteBatch error", err, trace);
      return DropboxResponse(message: "Unexpected exception: $err");
    }
  }

  Future<DropboxResponse> push(
    Uint8List bytes,
    String remotePath, {
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
            "path": remotePath,
            "strict_conflict": false
          }),
          "Content-Type": "application/octet-stream",
        },
        body: bytes,
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        onProgress?.call(1, 1);
        CloudLogger.infoResponse(TAG, "Upload successfully", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Upload finished.",
        );
      } else {
        CloudLogger.error(TAG, "Upload failed", resp);
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Upload failed.",
        );
      }
    } catch (err, trace) {
      CloudLogger.error(TAG, "Upload error", err, trace);
      return DropboxResponse(message: "Unexpected exception: $err");
    }
  }
}
