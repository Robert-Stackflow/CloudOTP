import 'dart:convert' show jsonDecode;

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

abstract class ITokenManager {
  /// save token response
  Future<void> saveTokenResp(http.Response resp);

  /// clear token
  Future<void> clearStoredToken();

  /// get access token
  Future<String?> getAccessToken();
}

class DefaultTokenManager extends ITokenManager {
  final String scope;
  final String tokenEndpoint;
  final String clientID;
  final String redirectURL;

  final _secureStorage = const FlutterSecureStorage();
  static const String _expireInKey = "__tokenExpire";
  static const String _accessTokenKey = "__accessToken";
  static const String _refreshTokenKey = "__refreshToken";

  DefaultTokenManager({
    required this.tokenEndpoint,
    required this.clientID,
    required this.redirectURL,
    this.scope = "offline_access Files.ReadWrite.All",
  });

  @override
  Future<void> saveTokenResp(http.Response resp) async {
    Map body = jsonDecode(resp.body);
    try {
      _secureStorage.write(
          key: _expireInKey,
          value: DateTime.now()
              .add(Duration(seconds: body['expires_in']))
              .toString());
      _secureStorage.write(key: _accessTokenKey, value: body['access_token']);
      _secureStorage.write(key: _refreshTokenKey, value: body['refresh_token']);
      // ignore: empty_catches
    } catch (err) {
      debugPrint("# DefaultTokenManager -> _saveTokenMap: $err");
    }
  }

  @override
  Future<void> clearStoredToken() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _expireInKey),
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
      ]);
    } catch (err) {
      debugPrint("# DefaultTokenManager -> clearStoredToken: $err");
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      if ((accessToken?.isEmpty) ?? true) {
        return null;
      }

      final accessTokenExpiresAt = await _secureStorage.read(key: _expireInKey);
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
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
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
      await clearStoredToken();
    }

    return null;
  }

  Future<void> _saveTokenMap(Map<String, dynamic> tokenObj) async {
    try {
      final expAt =
          DateTime.now().toUtc().add(Duration(seconds: tokenObj['expires_in']));
      debugPrint("# Expres at: $expAt");

      _secureStorage.write(key: _expireInKey, value: expAt.toString());
      _secureStorage.write(
          key: _accessTokenKey, value: tokenObj['access_token']);
      _secureStorage.write(
          key: _refreshTokenKey, value: tokenObj['refresh_token']);
    } catch (err) {
      debugPrint("# DefaultTokenManager -> _saveTokenMap: $err");
    }
  }
}
