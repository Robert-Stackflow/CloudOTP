import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

FlutterSecureStorage secureStorage = const FlutterSecureStorage();

abstract class ITokenManager {
  /// save token response
  Future<bool> saveTokenResp(http.Response resp);

  /// clear token
  Future<void> clearStoredToken();

  /// get access token
  Future<String?> getAccessToken();

  Future<bool> isAuthorized();
}

class DefaultTokenManager extends ITokenManager {
  final String scope;
  final String tokenEndpoint;
  final String clientId;
  final String redirectUrl;
  final String revokeUrl;

  final String expireAtKey;
  final String accessTokenKey;
  final String refreshTokenKey;
  final String idTokenKey;

  DefaultTokenManager({
    required this.tokenEndpoint,
    required this.clientId,
    required this.redirectUrl,
    required this.revokeUrl,
    required this.scope,
    required this.expireAtKey,
    required this.accessTokenKey,
    required this.refreshTokenKey,
    required this.idTokenKey,
  });

  @override
  Future<bool> saveTokenResp(http.Response resp) async {
    Map body = jsonDecode(resp.body);
    try {
      String expireAt =
          DateTime.now().add(Duration(seconds: body['expires_in'])).toString();
      await secureStorage.write(key: expireAtKey, value: expireAt);
      await secureStorage.write(
          key: accessTokenKey, value: body['access_token']);
      await secureStorage.write(
          key: refreshTokenKey, value: body['refresh_token']);
      await secureStorage.write(key: idTokenKey, value: body['id_token'] ?? "");
      return true;
    } catch (err) {
      debugPrint("# DefaultTokenManager -> _saveTokenMap: $err");
      return false;
    }
  }

  @override
  Future<bool> isAuthorized() async {
    try {
      final accessToken = await secureStorage.read(key: accessTokenKey);
      final accessTokenExpiresAt = await secureStorage.read(key: expireAtKey);
      if (((accessToken?.isEmpty) ?? true) &&
          ((accessTokenExpiresAt?.isEmpty) ?? true)) {
        return false;
      }
      return true;
    } catch (err) {
      debugPrint("# DefaultTokenManager -> getAccessToken: $err");
      return false;
    }
  }

  @override
  Future<void> clearStoredToken() async {
    try {
      await Future.wait([
        secureStorage.delete(key: expireAtKey),
        secureStorage.delete(key: accessTokenKey),
        secureStorage.delete(key: refreshTokenKey),
      ]);
    } catch (err) {
      debugPrint("# DefaultTokenManager -> clearStoredToken: $err");
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      final accessToken = await secureStorage.read(key: accessTokenKey);
      if ((accessToken?.isEmpty) ?? true) {
        return null;
      }

      final expiresAt = await secureStorage.read(key: expireAtKey);
      if ((expiresAt?.isEmpty) ?? true) {
        return null;
      }

      final expAt = DateTime.parse(expiresAt!).add(const Duration(minutes: -2));

      if (DateTime.now().toUtc().isAfter(expAt)) {
        final tokenMap = await _refreshToken();
        if (tokenMap == null) return null;
        return tokenMap['access_token'];
      }

      return accessToken;
    } catch (err) {
      debugPrint("# DefaultTokenManager -> getAccessToken: $err");
      return null;
    }
  }

  Future<Map<String, dynamic>?> _refreshToken() async {
    try {
      final refreshToken = await secureStorage.read(key: refreshTokenKey);
      if ((refreshToken?.isEmpty) ?? true) {
        return null;
      }

      Map body = {
        'client_id': clientId,
        'grant_type': 'refresh_token',
        'scope': scope,
        'refresh_token': refreshToken,
        'redirect_uri': redirectUrl,
      };

      final resp = await http.post(Uri.parse(tokenEndpoint), body: body);
      if (resp.statusCode != 200) {
        debugPrint(
            "# DefaultTokenManager -> _refreshToken: ${resp.statusCode}\n# Body: ${resp.body}");

        await clearStoredToken();
        return null;
      }

      debugPrint("# Refresh token: Success");
      final Map<String, dynamic> tokenMap = jsonDecode(resp.body);
      await saveTokenResp(resp);
      return tokenMap;
    } catch (err) {
      debugPrint("# DefaultTokenManager -> _refreshToken: $err");
      if (err is! http.ClientException) {
        await clearStoredToken();
      }
    }

    return null;
  }
}
