library flutter_cloud;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cloud/status.dart';
import 'package:flutter_cloud/token_manager.dart';
import 'package:http/http.dart' as http;

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
      debugPrint("# Dropbox -> connect: $err\n$trace");
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
      debugPrint(
          "# Dropbox -> disconnect: revoke access token: ${resp.statusCode}");
    } catch (err, trace) {
      debugPrint("# Dropbox -> disconnect: $err\n$trace");
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
        debugPrint("# Dropbox -> getInfo success: ${jsonDecode(resp.body)}");

        final usageResp = await post(storageUrl);

        if (usageResp.statusCode == 200 || usageResp.statusCode == 201) {
          debugPrint(
              "# Dropbox -> getStorageInfo success: ${jsonDecode(usageResp.body)}");

          return DropboxResponse.fromResponse(
            response: usageResp,
            userInfo: DropboxUserInfo.fromJson(
                jsonDecode(resp.body), jsonDecode(usageResp.body)),
            message: "Get Info successfully.",
          );
        } else {
          debugPrint(
              "# Dropbox -> getStorageInfo failed: ${usageResp.statusCode} # Body: ${usageResp.body}");
          return DropboxResponse.fromResponse(
            response: usageResp,
            message: "Error while get storage info.",
          );
        }
      } else {
        debugPrint(
            "# Dropbox -> getInfo failed: ${resp.statusCode} # Body: ${resp.body}");
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while get info.",
        );
      }
    } catch (err) {
      debugPrint("# Dropbox -> getInfo error: $err");
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
        debugPrint("# Dropbox -> list successfully");
        return DropboxResponse.fromResponse(
          response: resp,
          files: files,
          message: "List files successfully.",
        );
      } else {
        debugPrint(
            "# Dropbox -> list failed: ${resp.statusCode}\n# Body: ${resp.body}");
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while listing files.",
        );
      }
    } catch (err) {
      debugPrint("# Dropbox -> list error: $err");
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
        debugPrint("# Dropbox -> pull successfully");
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Download successfully.",
        );
      } else {
        debugPrint(
            "# Dropbox -> pull failed : ${resp.statusCode}\n# Body: ${resp.body}");
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while downloading file.",
        );
      }
    } catch (err) {
      debugPrint("# Dropbox -> pull: $err");
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
        debugPrint("# Dropbox -> delete successfully");
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Delete successfully.",
        );
      } else {
        debugPrint(
            "# Dropbox -> delete failed ${resp.statusCode}\n# Body: ${resp.body}");
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while deleting file.",
        );
      }
    } catch (err) {
      debugPrint("# Dropbox -> delete error: $err");
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
        debugPrint("# Dropbox -> deleteBatch successfully");
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Delete batch successfully.",
        );
      } else {
        debugPrint(
            "# Dropbox -> deleteBatch failed: ${resp.statusCode}\n# Body: ${resp.body}");
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Error while deleting file.",
        );
      }
    } catch (err) {
      debugPrint("# Dropbox -> deleteBatch error: $err");
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
        debugPrint("# Dropbox -> Upload successfully");
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Upload finished.",
        );
      } else {
        debugPrint("# Dropbox -> Upload failed: ${resp.statusCode}\n# Body: ${resp.body}");
        return DropboxResponse.fromResponse(
          response: resp,
          message: "Upload failed.",
        );
      }
    } catch (err) {
      debugPrint("# Dropbox -> Upload error: $err");
      return DropboxResponse(message: "Unexpected exception: $err");
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
