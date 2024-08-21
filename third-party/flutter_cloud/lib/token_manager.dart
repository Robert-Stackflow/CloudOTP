import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

FlutterSecureStorage secureStorage = const FlutterSecureStorage();

abstract class ITokenManager {
  /// save token response
  Future<void> saveTokenResp(http.Response resp);

  /// clear token
  Future<void> clearStoredToken();

  /// get access token
  Future<String?> getAccessToken();

  Future<bool> isAuthorized();
}

class DefaultTokenManager extends ITokenManager {
  final String scope;
  final String tokenEndpoint;
  final String clientID;
  final String redirectURL;

  final String expireInKey;
  final String accessTokenKey;
  final String refreshTokenKey;

  DefaultTokenManager({
    required this.tokenEndpoint,
    required this.clientID,
    required this.redirectURL,
    required this.scope,
    required this.expireInKey,
    required this.accessTokenKey,
    required this.refreshTokenKey,
  });

  @override
  Future<void> saveTokenResp(http.Response resp) async {
    Map body = jsonDecode(resp.body);
    try {
      String expireIn =
          DateTime.now().add(Duration(seconds: body['expires_in'])).toString();
      await secureStorage.write(key: expireInKey, value: expireIn);
      await secureStorage.write(
          key: accessTokenKey, value: body['access_token']);
      await secureStorage.write(
          key: refreshTokenKey, value: body['refresh_token']);
    } catch (err) {
      debugPrint("# DefaultTokenManager -> _saveTokenMap: $err");
    }
  }

  @override
  Future<bool> isAuthorized() async {
    try {
      final accessToken = await secureStorage.read(key: accessTokenKey);
      final accessTokenExpiresAt = await secureStorage.read(key: expireInKey);
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
        secureStorage.delete(key: expireInKey),
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

      final accessTokenExpiresAt = await secureStorage.read(key: expireInKey);
      if ((accessTokenExpiresAt?.isEmpty) ?? true) {
        return null;
      }

      final expAt = DateTime.parse(accessTokenExpiresAt!)
          .add(const Duration(minutes: -2));

      if (DateTime.now().toUtc().isAfter(expAt)) {
        // expired, refresh
        final tokenMap = await _refreshToken();
        if (tokenMap == null) {
          // refresh failed
          return null;
        }
        // refresh success
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

      final resp = await http.post(Uri.parse(tokenEndpoint), body: {
        'client_id': clientID,
        'grant_type': 'refresh_token',
        'scope': scope,
        'refresh_token': refreshToken,
        'redirect_uri': redirectURL,
      });
      if (resp.statusCode != 200) {
        // refresh failed
        debugPrint(
            "# DefaultTokenManager -> _refreshToken: ${resp.statusCode}\n# Body: ${resp.body}");

        await clearStoredToken();
        return null;
      }

      debugPrint("# Refresh token: Success");
      final Map<String, dynamic> tokenMap = jsonDecode(resp.body);
      await _saveTokenMap(tokenMap);

      return tokenMap;
    } catch (err) {
      debugPrint("# DefaultTokenManager -> _refreshToken: $err");
      if (err is! http.ClientException) {
        await clearStoredToken();
      }
    }

    return null;
  }

  Future<void> _saveTokenMap(Map<String, dynamic> tokenObj) async {
    try {
      final expAt =
          DateTime.now().toUtc().add(Duration(seconds: tokenObj['expires_in']));
      debugPrint("# Expres at: $expAt");

      secureStorage.write(key: expireInKey, value: expAt.toString());
      secureStorage.write(key: accessTokenKey, value: tokenObj['access_token']);
      secureStorage.write(
          key: refreshTokenKey, value: tokenObj['refresh_token']);
    } catch (err) {
      debugPrint("# DefaultTokenManager -> _saveTokenMap: $err");
    }
  }
}
