import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

class OAuth2Helper {
  static String generateStateParameter([int length = 16]) {
    final Random random = Random.secure();
    final List<int> values =
        List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  static Future<http.Response?> browserAuth({
    required BuildContext? context,
    required Uri authEndpoint,
    required Uri tokenEndpoint,
    required String callbackUrl,
    required String callbackUrlScheme,
    required String clientId,
    required String redirectUrl,
    required String state,
    String? clientSecret,
    String? windowName,
    String? scopes,
  }) async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authEndpoint.toString(),
        callbackUrl: callbackUrl,
        callbackUrlScheme: callbackUrlScheme,
        options: FlutterWebAuth2Options(
          timeout: 60,
          windowName: windowName,
          useWebview: false,
        ),
      );
      final String code = Uri.parse(result).queryParameters['code'] ?? "";
      final String responseState =
          Uri.parse(result).queryParameters['state'] ?? "";
      if (state != responseState) {
        return null;
      }
      Map body = {
        'client_id': clientId,
        'redirect_uri': redirectUrl,
        'grant_type': 'authorization_code',
        'code': code,
      };
      if (clientSecret != null && clientSecret.isNotEmpty) {
        body['client_secret'] = clientSecret;
      }
      http.Response resp = await http.post(tokenEndpoint, body: body);
      return resp;
    } catch (e, t) {
      print("$e\n$t");
      return null;
    }
  }

  static Future<http.Response?> browserAuthWithVerifier({
    required BuildContext? context,
    required Uri authEndpoint,
    required Uri tokenEndpoint,
    required String callbackUrl,
    required String callbackUrlScheme,
    required String clientId,
    required String redirectUrl,
    required String codeVerifier,
    required String state,
    String? clientSecret,
    String? windowName,
    String? scopes,
  }) async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authEndpoint.toString(),
        callbackUrl: callbackUrl,
        callbackUrlScheme: callbackUrlScheme,
        options: FlutterWebAuth2Options(
          timeout: 60,
          windowName: windowName,
          useWebview: false,
        ),
      );
      final String code = Uri.parse(result).queryParameters['code'] ?? "";
      final String responseState =
          Uri.parse(result).queryParameters['state'] ?? "";
      if (state != responseState) {
        return null;
      }
      Map body = {
        'client_id': clientId,
        'redirect_uri': redirectUrl,
        'code_verifier': codeVerifier,
        'grant_type': 'authorization_code',
        'code': code,
      };
      if (clientSecret != null && clientSecret.isNotEmpty) {
        body['client_secret'] = clientSecret;
      }
      http.Response resp = await http.post(tokenEndpoint, body: body);
      return resp;
    } catch (e, t) {
      print("$e $t");
      return null;
    }
  }
}
