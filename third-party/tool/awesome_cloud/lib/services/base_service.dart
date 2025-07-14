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

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/status.dart';
import '../utils/cloud_logger.dart';
import '../utils/oauth2_helper.dart';
import '../utils/token_manager.dart';

abstract class BaseCloudService with ChangeNotifier {
  String get serviceId;

  String get serviceName;

  String get authEndpoint;

  String get tokenEndpoint;

  String get revokeEndpoint;

  String get apiEndpoint;

  String get permission;

  String get expireInKey;

  String get accessTokenKey;

  String get refreshTokenKey;

  String get idTokenKey;

  String get rawRespKey;

  late final ITokenManager tokenManager;
  late final String callbackUrl;
  late final String scopes;
  late final String clientId;
  late final String state;

  // 非 PKCE 模式下的字段
  late final String customAuthEndpoint;
  late final String customTokenEndpoint;
  late final String customRevokeEndpoint;

  bool isPKCE = true; // 标识是否为 PKCE 模式

  BaseCloudService({
    required this.clientId,
    required this.callbackUrl,
    String scopes = "",
    ITokenManager? tokenManager,
  }) {
    this.scopes = scopes.isEmpty ? permission : scopes;
    state = OAuth2Helper.generateStateParameter();
    this.tokenManager = tokenManager ??
        DefaultTokenManager(
          tokenEndpoint: tokenEndpoint,
          clientId: clientId,
          revokeEndpoint: revokeEndpoint,
          scope: scopes,
          expireAtKey: expireInKey,
          accessTokenKey: accessTokenKey,
          refreshTokenKey: refreshTokenKey,
          idTokenKey: idTokenKey,
          rawRespKey: rawRespKey,
        );
  }

  BaseCloudService.server({
    required this.clientId,
    required this.callbackUrl,
    required this.customAuthEndpoint,
    required this.customRevokeEndpoint,
    required this.customTokenEndpoint,
    String scopes = "",
    ITokenManager? tokenManager,
  }) {
    isPKCE = false;
    this.scopes = scopes.isEmpty ? permission : scopes;
    state = OAuth2Helper.generateStateParameter();
    this.tokenManager = tokenManager ??
        DefaultTokenManager(
          tokenEndpoint: customTokenEndpoint,
          revokeEndpoint: customRevokeEndpoint ?? "",
          clientId: clientId,
          scope: scopes,
          expireAtKey: expireInKey,
          accessTokenKey: accessTokenKey,
          refreshTokenKey: refreshTokenKey,
          idTokenKey: idTokenKey,
          rawRespKey: rawRespKey,
        );
  }

  Future<bool> isConnected() async {
    final accessToken = await tokenManager.getAccessToken();
    return (accessToken?.isNotEmpty) ?? false;
  }

  Future<bool> hasAuthorized() async {
    final accessToken = await tokenManager.getAccessToken();
    return (accessToken?.isNotEmpty) ?? false;
  }

  Future<bool> connect() async {
    if (isPKCE) {
      return await connectPKCE();
    } else {
      return await connectServer();
    }
  }

  Future<bool> connectPKCE() async {
    try {
      String codeVerifier = OAuth2Helper.generateCodeVerifier();

      String codeChanllenge = OAuth2Helper.generateCodeChanllenge(codeVerifier);

      Uri uri = Uri.parse(authEndpoint);
      final authUri = Uri.https(uri.authority, uri.path, {
        'code_challenge': codeChanllenge,
        "code_challenge_method": "S256",
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': callbackUrl,
        "access_type": "offline",
        'scope': scopes,
        'state': state,
      });
      Uri tokenUri = Uri.parse(tokenEndpoint);

      String callbackUrlScheme = "";
      Uri callbackUri = Uri.parse(callbackUrl);
      if (callbackUri.scheme != "http" && callbackUri.scheme != "https") {
        callbackUrlScheme = callbackUri.scheme;
      } else {
        callbackUrlScheme = callbackUri.toString();
      }

      String? code = await OAuth2Helper.browserAuth(
        authUri: authUri,
        callbackUrl: callbackUrl,
        callbackUrlScheme: callbackUrlScheme,
        state: state,
      );
      if (code == null) {
        CloudLogger.error(serviceName, "Connect failed: No code received");
        return false;
      }
      Map body = {
        'client_id': clientId,
        'redirect_uri': callbackUrl,
        'code_verifier': codeVerifier,
        'grant_type': 'authorization_code',
        'code': code,
      };
      http.Response resp = await http.post(tokenUri, body: body);
      if (!isSuccess(resp)) {
        CloudLogger.errorResponse(
            serviceName, "Connect failed when getting access token", resp);
        return false;
      }
      var res = await tokenManager.persistToken(resp.body);
      notifyListeners();
      return res;
    } on PlatformException {
      return false;
    } catch (e, t) {
      CloudLogger.error(serviceName, "Connect error", e, t);
      return false;
    }
  }

  Future<bool> connectServer() async {
    try {
      Uri authUri = Uri.parse(customAuthEndpoint);
      authUri = authUri.replace(queryParameters: {
        'redirect_uri': callbackUrl,
        'state': state,
      });
      Uri tokenUri = Uri.parse(customTokenEndpoint);
      String callbackUrlScheme = "";
      Uri callbackUri = Uri.parse(callbackUrl);
      if (callbackUri.scheme != "http" && callbackUri.scheme != "https") {
        callbackUrlScheme = callbackUri.scheme;
      } else {
        callbackUrlScheme = callbackUri.toString();
      }

      String? code = await OAuth2Helper.browserAuth(
        authUri: authUri,
        callbackUrl: callbackUrl,
        callbackUrlScheme: callbackUrlScheme,
        state: state,
      );
      if (code == null) {
        CloudLogger.error(serviceName, "Connect failed: No code received");
        return false;
      }
      http.Response resp = await http.post(tokenUri, body: {
        'client_id': clientId,
        'redirect_uri': callbackUrl,
        'grant_type': 'authorization_code',
        'code': code,
      });
      if (!isSuccess(resp)) {
        CloudLogger.errorResponse(
            serviceName, "Connect failed when getting access token", resp);
        return false;
      }
      var res = await tokenManager.persistToken(resp.body);
      notifyListeners();
      return res;
    } catch (e, t) {
      CloudLogger.error(serviceName, "Connect error", e, t);
      return false;
    }
  }

  Future<void> disconnect() async {
    await tokenManager.clearToken();
    notifyListeners();
  }

  Future<String> checkToken() async {
    final accessToken = await tokenManager.getAccessToken();
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

  bool isSuccess(http.Response response) {
    return response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204;
  }

  bool isStreamSuccess(http.StreamedResponse response) {
    return response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204;
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

  Future<dynamic> getInfo();

  Future<dynamic> list(String remotePath);

  Future<dynamic> pullById(String id);

  Future<dynamic> deleteById(String id);

  Future<dynamic> push(Uint8List bytes, String remotePath);

  Future<void> checkFolder(String remotePath);
}
