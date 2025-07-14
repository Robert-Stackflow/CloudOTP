import 'dart:convert';

import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

FlutterSecureStorage secureStorage = const FlutterSecureStorage();

abstract class ITokenManager {
  Future<bool> persistToken(String respBody);

  Future<void> clearToken();

  Future<String?> getAccessToken();

  Future<bool> isAuthorized();
}

class DefaultTokenManager extends ITokenManager {
  final String scope;
  final String tokenEndpoint;
  final String clientId;
  final String revokeEndpoint;

  final String expireAtKey;
  final String accessTokenKey;
  final String refreshTokenKey;
  final String idTokenKey;
  final String rawRespKey;
  static const String TAG = "TokenManager";

  DefaultTokenManager({
    required this.tokenEndpoint,
    required this.clientId,
    required this.revokeEndpoint,
    required this.scope,
    required this.expireAtKey,
    required this.accessTokenKey,
    required this.refreshTokenKey,
    required this.idTokenKey,
    required this.rawRespKey,
  });

  @override
  Future<bool> persistToken(String respBody) async {
    Map body = jsonDecode(respBody);
    try {
      debugPrint(respBody);
      String expireAt =
          DateTime.now().add(Duration(seconds: body['expires_in'])).toString();
      await secureStorage.write(key: expireAtKey, value: expireAt);
      await secureStorage.write(
          key: accessTokenKey, value: body['access_token']);
      if (body.containsKey("refresh_token")) {
        await secureStorage.write(
            key: refreshTokenKey, value: body['refresh_token']);
      }
      if (body.containsKey("id_token")) {
        await secureStorage.write(
            key: idTokenKey, value: body['id_token'] ?? "");
      }
      await secureStorage.write(key: rawRespKey, value: jsonEncode(body));
      return true;
    } catch (err, trace) {
      CloudLogger.error(TAG, "Error saving token response", err, trace);
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
    } catch (err, trace) {
      CloudLogger.error(TAG, "Error checking if authorized", err, trace);
      return false;
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      await Future.wait([
        secureStorage.delete(key: expireAtKey),
        secureStorage.delete(key: accessTokenKey),
        secureStorage.delete(key: refreshTokenKey),
        secureStorage.delete(key: idTokenKey),
        secureStorage.delete(key: rawRespKey),
      ]);
    } catch (err, trace) {
      CloudLogger.error(TAG, "Error clearing stored token", err, trace);
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
        return await _refreshToken();
      }

      return accessToken;
    } catch (err, trace) {
      CloudLogger.error(TAG, "Error getting access token", err, trace);
      return null;
    }
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await secureStorage.read(key: refreshTokenKey);
      if ((refreshToken?.isEmpty) ?? true) {
        return null;
      }

      Map body = {
        'client_id': clientId,
        'grant_type': 'refresh_token',
        'scope': scope,
        "permission": scope,
        'refresh_token': refreshToken,
      };

      final resp = await http.post(Uri.parse(tokenEndpoint), body: body);
      if (resp.statusCode != 200) {
        CloudLogger.errorResponse(TAG, "Error refreshing token", resp);
        await clearToken();
        return null;
      }

      CloudLogger.infoResponse(TAG, "Refresh token: Success", resp);
      await persistToken(resp.body);
      return await secureStorage.read(key: accessTokenKey);
    } catch (err, trace) {
      CloudLogger.error(TAG, "Error refreshing token", err, trace);
      if (err is! http.ClientException) {
        await clearToken();
      }
    }

    return null;
  }
}
