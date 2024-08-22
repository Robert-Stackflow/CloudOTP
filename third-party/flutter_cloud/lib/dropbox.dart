library flutter_cloud;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cloud/token_manager.dart';
import 'package:hashlib/hashlib.dart';
import 'package:http/http.dart' as http;

import 'dropbox_response.dart';
import 'oauth2_helper.dart';

class Dropbox with ChangeNotifier {
  static const String authHost = "www.dropbox.com";
  static const String authEndpoint = "/oauth2/authorize";
  static const String tokenEndpoint = "https://$authHost/oauth2/token";
  static const String apiContentEndpoint = "https://content.dropboxapi.com/2";
  static const String apiEndpoint = "https://api.dropboxapi.com/2";
  static const String errCANCELED = "CANCELED";
  static const permissionFilesReadWriteAll =
      "account_info.read files.metadata.write files.metadata.read files.content.write files.content.read file_requests.write file_requests.read";

  static const String expireInKey = "__dropbox_tokenExpire";
  static const String accessTokenKey = "__dropbox_accessToken";
  static const String refreshTokenKey = "__dropbox_refreshToken";

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
    this.scopes = permissionFilesReadWriteAll,
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

  String generateCodeVerifier() {
    return myBase64Encode(randomBytes(32));
  }

  String myBase64Encode(List<int> input) {
    return base64Encode(input)
        .replaceAll("+", '-')
        .replaceAll("/", '_')
        .replaceAll("=", '');
  }

  Future<bool> connect(
    BuildContext context, {
    String? windowName,
  }) async {
    try {
      String codeVerifier = generateCodeVerifier();

      String codeChanllenge = myBase64Encode(sha256.string(codeVerifier).bytes);

      final authUri = Uri.https(authHost, authEndpoint, {
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
        context: context,
        authEndpoint: authUri,
        tokenEndpoint: Uri.parse(tokenEndpoint),
        callbackUrl: callbackUrl,
        callbackUrlScheme: callbackUrlScheme,
        clientId: clientId,
        redirectUrl: redirectUrl,
        codeVerifier: codeVerifier,
        scopes: scopes,
        windowName: windowName,
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
    } on PlatformException catch (err, trace) {
      if (err.code != errCANCELED) {
        debugPrint("# Dropbox -> connect: $err\n$trace");
      }
      return false;
    } catch (err, trace) {
      debugPrint("# Dropbox -> connect: $err\n$trace");
      return false;
    }
  }

  Future<void> disconnect() async {
    await _tokenManager.clearStoredToken();
    notifyListeners();
  }

  Future<DropboxResponse> getInfo() async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return DropboxResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }
    final url = Uri.parse("$apiEndpoint/users/get_current_account");
    final storageUrl = Uri.parse("$apiEndpoint/users/get_space_usage");

    try {
      final resp = await http.post(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      debugPrint(
          "# Dropbox -> getInfo: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final usageResp = await http.post(
          storageUrl,
          headers: {"Authorization": "Bearer $accessToken"},
        );

        debugPrint(
            "# Dropbox -> getStorageInfo: ${usageResp.statusCode}\n# Body: ${usageResp.body}");

        if (usageResp.statusCode == 200 || usageResp.statusCode == 201) {
          return DropboxResponse(
              statusCode: resp.statusCode,
              body: resp.body,
              userInfo: DropboxUserInfo.fromJson(
                  jsonDecode(resp.body), jsonDecode(usageResp.body)),
              message: "Get Info successfully.",
              bodyBytes: resp.bodyBytes,
              isSuccess: true);
        } else {
          return DropboxResponse(
              statusCode: resp.statusCode,
              body: resp.body,
              message: "Error while get storage info.",
              bodyBytes: Uint8List(0));
        }
      } else if (resp.statusCode == 404) {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "${url.toString()} not found.",
            bodyBytes: Uint8List(0));
      } else {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while get info.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# Dropbox -> getInfo: $err");
      return DropboxResponse(message: "Unexpected exception: $err");
    }
  }

  Future<DropboxResponse> list(String remotePath) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return DropboxResponse(message: "Null access token");
    }

    final url = Uri.parse("$apiEndpoint/files/list_folder");

    try {
      final resp = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
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

      debugPrint("# Dropbox -> list: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Map body = jsonDecode(resp.body);
        List<DropboxFileInfo> files = [];
        for (var item in body['entries']) {
          if (item['.tag'] == "folder") continue;
          files.add(DropboxFileInfo.fromJson(item));
        }
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            files: files,
            message: "List files successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Url not found.");
      } else {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while listing files.");
      }
    } catch (err) {
      debugPrint("# Dropbox -> list: $err");
      return DropboxResponse(message: "Unexpected exception: $err");
    }
  }

  Future<DropboxResponse> pull(
    String path,
  ) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return DropboxResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    final url = Uri.parse("$apiContentEndpoint/files/download");

    try {
      final resp = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Dropbox-API-Arg": jsonEncode({
            "path": path,
          }),
        },
      );

      debugPrint("# Dropbox -> pull: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Download successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "File not found.",
            bodyBytes: Uint8List(0));
      } else {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while downloading file.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# Dropbox -> pull: $err");
      return DropboxResponse(message: "Unexpected exception: $err");
    }
  }

  Future<DropboxResponse> delete(String path) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return DropboxResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    final url = Uri.parse("$apiEndpoint/files/delete_v2");

    try {
      final resp = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"path": path}),
      );

      debugPrint(
          "# Dropbox -> delete: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Delete successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "File not found.",
            bodyBytes: Uint8List(0));
      } else {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while deleting file.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# Dropbox -> delete: $err");
      return DropboxResponse(message: "Unexpected exception: $err");
    }
  }

  Future<DropboxResponse> deleteBatch(List<String> paths) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return DropboxResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    final url = Uri.parse("$apiEndpoint/files/delete_batch");

    try {
      final resp = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(
          {
            "entries": paths.map((e) => {"path": e}).toList()
          },
        ),
      );

      debugPrint(
          "# Dropbox -> deleteBatch: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Delete successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "File not found.",
            bodyBytes: Uint8List(0));
      } else {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while deleting file.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# Dropbox -> deleteBatch: $err");
      return DropboxResponse(message: "Unexpected exception: $err");
    }
  }

  Future<DropboxResponse> push(
    Uint8List bytes,
    String remotePath, {
    Function(int p1, int p2)? onProgress,
  }) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return DropboxResponse(message: "Null access token.");
    }

    try {
      var url = Uri.parse("$apiContentEndpoint/files/upload");

      var resp = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
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

      debugPrint("# Upload response: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        onProgress?.call(1, 1);
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Upload finished.",
            isSuccess: true);
      } else {
        return DropboxResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Upload failed.");
      }
    } catch (err) {
      debugPrint("# Upload error: $err");
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
