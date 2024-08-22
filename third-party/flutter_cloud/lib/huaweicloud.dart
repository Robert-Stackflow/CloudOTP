library flutter_cloud;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cloud/token_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'huaweicloud_response.dart';
import 'my_multipart_request.dart';
import 'oauth2_helper.dart';

class HuaweiCloud with ChangeNotifier {
  static const String authHost = "oauth-login.cloud.huawei.com";
  static const String authEndpoint = "/oauth2/v3/authorize";
  static const String revokeEndpoint = "https://$authHost/oauth2/v3/revoke";
  static const String tokenEndpoint = "https://$authHost/oauth2/v3/token";
  static const String apiEndpoint =
      "https://driveapis.cloud.huawei.com.cn/drive/v1";
  static const String uploadApiEndpoint =
      "https://driveapis.cloud.huawei.com.cn/upload/drive/v1/files";
  static const permission = "https://www.huawei.com/auth/drive.file";

  static const String expireInKey = "__huaweicloud_tokenExpire";
  static const String accessTokenKey = "__huaweicloud_accessToken";
  static const String refreshTokenKey = "__huaweicloud_refreshToken";

  late final ITokenManager _tokenManager;
  late final String redirectUrl;
  late final String callbackUrl;
  final String scopes;
  final String clientId;
  final String clientSecret;

  late final String state;

  HuaweiCloud({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUrl,
    required this.callbackUrl,
    this.scopes = permission,
    ITokenManager? tokenManager,
  }) {
    state = OAuth2Helper.generateStateParameter();
    _tokenManager = tokenManager ??
        DefaultTokenManager(
          tokenEndpoint: tokenEndpoint,
          clientId: clientId,
          clientSecret: clientSecret,
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
        "access_type": "offline",
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
        state: state,
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUrl: redirectUrl,
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
    } on PlatformException {
      return false;
    } catch (err) {
      debugPrint("# HuaweiCloud -> connect: $err");
      return false;
    }
  }

  Future<void> disconnect() async {
    await _tokenManager.clearStoredToken();
    notifyListeners();
  }

  Future<HuaweiCloudResponse> getInfo() async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      debugPrint("# HuaweiCloud -> getInfo: Null access token");
      return HuaweiCloudResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }
    final url = Uri.parse("$apiEndpoint/about?fields=user,storageQuota");

    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      debugPrint(
          "# HuaweiCloud -> getInfo: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            userInfo: HuaweiCloudUserInfo.fromJson(jsonDecode(resp.body)),
            message: "Get Info successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "${url.toString()} not found.",
            bodyBytes: Uint8List(0));
      } else {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while get info.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# HuaweiCloud -> getInfo: $err");
      return HuaweiCloudResponse(message: "Unexpected exception: $err");
    }
  }

  Future<HuaweiCloudResponse> list(
    String remotePath, {
    String? q,
  }) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return HuaweiCloudResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    var url = Uri.https("driveapis.cloud.huawei.com.cn", "/drive/v1/files", {
      "fields": "*",
      "q": q,
    });

    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Map body = jsonDecode(resp.body);
        List<HuaweiCloudFileInfo> files = [];
        for (var item in body['files']) {
          files.add(HuaweiCloudFileInfo.fromJson(item));
        }
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            files: files,
            message: "List files successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Url not found.",
            bodyBytes: Uint8List(0));
      } else {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while listing files.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# HuaweiCloud -> list: $err");
      return HuaweiCloudResponse(message: "Unexpected exception: $err");
    }
  }

  Future<HuaweiCloudResponse> pullById(String id) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return HuaweiCloudResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    final url = Uri.parse("$apiEndpoint/files/$id?form=content");

    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      debugPrint(
          "# HuaweiCloud -> pull: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Download successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "File not found.",
            bodyBytes: Uint8List(0));
      } else {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while downloading file.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# HuaweiCloud -> pull: $err");
      return HuaweiCloudResponse(message: "Unexpected exception: $err");
    }
  }

  Future<HuaweiCloudResponse> deleteById(String id) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return HuaweiCloudResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    final url = Uri.parse("$apiEndpoint/files/$id");

    try {
      final resp = await http.delete(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      debugPrint(
          "# HuaweiCloud -> delete: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Delete successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "File not found.",
            bodyBytes: Uint8List(0));
      } else {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while deleting file.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# HuaweiCloud -> delete: $err");
      return HuaweiCloudResponse(message: "Unexpected exception: $err");
    }
  }

  Future<HuaweiCloudResponse> push(
    Uint8List bytes,
    String remotePath,
    String fileName, {
    Function(int p1, int p2)? onProgress,
  }) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return HuaweiCloudResponse(message: "Null access token.");
    }

    try {
      String parentId = (await createDir(remotePath)).parentId ?? "";

      debugPrint("# Parent id: $parentId");

      var url = Uri.parse("$uploadApiEndpoint?uploadType=multipart&fields=*");

      var boundary = 'OP8XTaXZ0UZs-Sjlefcj2OWskqXWwVQO';
      var headers = {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "multipart/related; boundary=$boundary",
        'Cache-Control': 'no-cache',
      };

      var request = MyMultipartRequest('POST', url, boundary);
      request.headers.addAll(headers);

      var jsonPart = jsonEncode({
        "fileName": fileName,
        "parentFolder": [parentId],
      });

      request.files.add(
        http.MultipartFile.fromString(
          "",
          jsonPart,
          contentType: MediaType("application", "json"),
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          '',
          bytes,
          contentType: MediaType('application', 'octet-stream'),
        ),
      );

      http.StreamedResponse resp = (await request.send());

      Uint8List bodyBytes = await resp.stream.toBytes();

      String body = utf8.decode(bodyBytes);

      debugPrint("# Upload response: ${resp.statusCode}\n# Body: $body");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        onProgress?.call(1, 1);
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: body,
            bodyBytes: bodyBytes,
            message: "Upload finished.",
            isSuccess: true);
      } else {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: body,
            bodyBytes: bodyBytes,
            message: "Upload failed.");
      }
    } catch (err, trace) {
      debugPrint("# Upload error: $err\n$trace");
      return HuaweiCloudResponse(message: "Unexpected exception: $err");
    }
  }

  Future<HuaweiCloudResponse> createDir(String remotePath) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return HuaweiCloudResponse(message: "Null access token.");
    }

    HuaweiCloudResponse res = await list(
      "",
      q: "mimeType='application/vnd.huawei-apps.folder'",
    );

    if (!res.isSuccess) {
      return HuaweiCloudResponse(
        message: "Error while listing files.",
        bodyBytes: Uint8List(0),
      );
    }

    if (res.files.isNotEmpty) {
      for (var file in res.files) {
        if (file.name == remotePath &&
            file.fileMimeType == "application/vnd.huawei-apps.folder") {
          return HuaweiCloudResponse(
            parentId: file.id,
            message: "Directory already exists.",
            isSuccess: true,
          );
        }
      }
    }

    final url = Uri.parse("$apiEndpoint/files?fields=*");

    try {
      final resp = await http.post(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
        body: jsonEncode({
          "fileName": remotePath,
          "mimeType": "application/vnd.huawei-apps.folder",
        }),
      );

      debugPrint(
          "# HuaweiCloud -> createDir: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            parentId: jsonDecode(resp.body)["id"],
            message: "Create directory successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Url not found.",
            bodyBytes: Uint8List(0));
      } else {
        return HuaweiCloudResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while creating directory.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# HuaweiCloud -> createDir: $err");
    }

    return HuaweiCloudResponse(message: "Unexpected exception.");
  }
}
