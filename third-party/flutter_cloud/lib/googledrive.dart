library flutter_cloud;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cloud/token_manager.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'googledrive_response.dart';
import 'oauth2_helper.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDrive with ChangeNotifier {
  static const String authEndpoint =
      "https://accounts.google.com/o/oauth2/v2/auth";
  static const String tokenEndpoint =
      "https://www.googleapis.com/oauth2/v4/token";
  static const String revokeEndpoint =
      "https://www.googleapis.com/oauth2/v4/revoke";
  static const String apiEndpoint = "https://content.googleapis.com/drive/v3";
  static const String apiUploadEndpoint =
      "https://www.googleapis.com/upload/drive/v3/files";
  static const permission = "https://www.googleapis.com/auth/drive.file";

  static const String expireInKey = "__googledrive_tokenExpire";
  static const String accessTokenKey = "__googledrive_accessToken";
  static const String refreshTokenKey = "__googledrive_refreshToken";
  static const String idTokenKey = "__googledrive_idToken";

  late final ITokenManager _tokenManager;
  late final String redirectUrl;
  late final String callbackUrl;
  final String scopes;
  final String clientId;

  late final String state;

  GoogleDrive({
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

  Future<drive.DriveApi> getClient() async {
    final accessToken = await _tokenManager.getAccessToken();

    final authenticateClient = GoogleAuthClient({
      "Authorization": "Bearer $accessToken",
    });
    final driveApi = drive.DriveApi(authenticateClient);
    return driveApi;
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
    // GoogleSignIn googleSignIn = GoogleSignIn(
    //   clientId: clientId,
    //   scopes: [permission],
    //   forceCodeForRefreshToken: true,
    //   signInOption: SignInOption.standard,
    // );
    // try {
    //   GoogleSignInAccount? currentUser = await googleSignIn.signIn();
    //   GoogleSignInAuthentication? authentication =
    //       await currentUser?.authentication;
    //   print(authentication?.accessToken);
    //   return true;
    // } catch (e, t) {
    //   print("$e\n$t");
    return false;
    // }
  }

  Future<bool> connects() async {
    try {
      String codeVerifier = OAuth2Helper.generateCodeVerifier();

      String codeChanllenge = OAuth2Helper.generateCodeChanllenge(codeVerifier);

      Uri uri = Uri.parse(authEndpoint);
      final authUri = Uri.https(uri.authority, uri.path, {
        'code_challenge': codeChanllenge,
        "code_challenge_method": "S256",
        'client_id': clientId,
        'redirect_uri': redirectUrl,
        'response_type': 'code',
        "access_type": "offline",
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
        state: state,
        clientId: clientId,
        codeVerifier: codeVerifier,
        redirectUrl: redirectUrl,
        scopes: scopes,
      );

      if (result != null) {
        notifyListeners();
        bool res = (await _tokenManager.saveTokenResp(result));
        return res;
      } else {
        return false;
      }
    } on PlatformException {
      return false;
    } catch (err) {
      debugPrint("# GoogleDrive -> connect: $err");
      return false;
    }
  }

  Future<void> disconnect() async {
    await _tokenManager.clearStoredToken();
    notifyListeners();
  }

  Future<GoogleDriveResponse> getInfo() async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return GoogleDriveResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }
    final url = Uri.parse("$apiEndpoint/about?fields=storageQuota,user");
    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      debugPrint(
          "# GoogleDrive -> getInfo: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return GoogleDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            userInfo: GoogleDriveUserInfo.fromJson(jsonDecode(resp.body)),
            message: "Get Info successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return GoogleDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "${url.toString()} not found.",
            bodyBytes: Uint8List(0));
      } else {
        return GoogleDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while get info.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# GoogleDrive -> getInfo: $err");
      return GoogleDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Future<GoogleDriveResponse> list(String remotePath) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return GoogleDriveResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    try {
      drive.DriveApi driveApi = await getClient();

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

      return GoogleDriveResponse(
          files: fileInfos,
          message: "List files successfully.",
          isSuccess: true);
    } catch (err) {
      debugPrint("# GoogleDrive -> list: $err");
      return GoogleDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Future<GoogleDriveResponse> pullById(String id) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return GoogleDriveResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    try {
      drive.DriveApi driveApi = await getClient();

      drive.Media media = await driveApi.files.get(
        id,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      return GoogleDriveResponse(
          message: "Download successfully.",
          bodyBytes: await (media.stream as http.ByteStream).toBytes(),
          isSuccess: true);
    } catch (err) {
      debugPrint("# GoogleDrive -> pull: $err");
      return GoogleDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Future<GoogleDriveResponse> deleteById(String id) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return GoogleDriveResponse(
          message: "Null access token", bodyBytes: Uint8List(0));
    }

    try {
      drive.DriveApi driveApi = await getClient();

      await driveApi.files.delete(id);

      return GoogleDriveResponse(
          message: "Delete successfully.", isSuccess: true);
    } catch (err) {
      debugPrint("# GoogleDrive -> delete: $err");
      return GoogleDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Future<GoogleDriveResponse> push(
    Uint8List bytes,
    String fileName,
    String remotePath, {
    Function(int p1, int p2)? onProgress,
  }) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return GoogleDriveResponse(message: "Null access token.");
    }

    try {
      String parentId = (await createDir(remotePath)).parentId ?? "";

      drive.DriveApi driveApi = await getClient();

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
      debugPrint("# Upload response: ${res.id} ${res.name}");

      return GoogleDriveResponse(
          message: "Upload successfully.", isSuccess: true);
    } catch (err) {
      debugPrint("# Upload error: $err");
      return GoogleDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Future<GoogleDriveResponse> createDir(String remotePath) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return GoogleDriveResponse(message: "Null access token.");
    }

    drive.DriveApi driveApi = await getClient();

    drive.FileList fileList = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.folder'",
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      for (var file in fileList.files!) {
        if (file.name == remotePath) {
          return GoogleDriveResponse(
            parentId: file.id ?? "",
            message: "Directory already exists.",
            isSuccess: true,
          );
        }
      }
    }

    final url = Uri.parse("$apiEndpoint/files");

    try {
      final resp = await http.post(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
        body: jsonEncode({
          "name": remotePath,
          "mimeType": "application/vnd.google-apps.folder",
        }),
      );

      debugPrint(
          "# GoogleDrive -> metadata: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return GoogleDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            parentId: jsonDecode(resp.body)["id"],
            message: "Create directory successfully.",
            bodyBytes: resp.bodyBytes,
            isSuccess: true);
      } else if (resp.statusCode == 404) {
        return GoogleDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Url not found.",
            bodyBytes: Uint8List(0));
      } else {
        return GoogleDriveResponse(
            statusCode: resp.statusCode,
            body: resp.body,
            message: "Error while creating directory.",
            bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# GoogleDrive -> metadata: $err");
    }

    return GoogleDriveResponse(message: "Unexpected exception.");
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
