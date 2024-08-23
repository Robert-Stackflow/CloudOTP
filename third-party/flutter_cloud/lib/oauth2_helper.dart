import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:hashlib/hashlib.dart';
import 'package:http/http.dart' as http;

class OAuth2Helper {
  static String generateStateParameter([int length = 16]) {
    final Random random = Random.secure();
    final List<int> values =
        List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  static String generateCodeVerifier() {
    return myBase64Encode(randomBytes(32));
  }

  static String myBase64Encode(List<int> input) {
    return base64Encode(input)
        .replaceAll("+", '-')
        .replaceAll("/", '_')
        .replaceAll("=", '');
  }

  static String generateCodeChanllenge(String codeVerifier){
    return myBase64Encode(sha256.string(codeVerifier).bytes);
  }

  static Future<http.Response?> browserAuth({
    required Uri authEndpoint,
    required Uri tokenEndpoint,
    required String callbackUrl,
    required String callbackUrlScheme,
    required String clientId,
    required String redirectUrl,
    required String state,
    String? scopes,
  }) async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authEndpoint.toString(),
        callbackUrl: callbackUrl,
        callbackUrlScheme: callbackUrlScheme,
        options: const FlutterWebAuth2Options(
          timeout: 60,
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
      http.Response resp = await http.post(tokenEndpoint, body: body);
      return resp;
    } catch (e, t) {
      print("$e\n$t");
      return null;
    }
  }

  static Future<http.Response?> browserAuthWithVerifier({
    required Uri authEndpoint,
    required Uri tokenEndpoint,
    required String callbackUrl,
    required String callbackUrlScheme,
    required String clientId,
    required String redirectUrl,
    required String codeVerifier,
    required String state,
    String? scopes,
  }) async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authEndpoint.toString(),
        callbackUrl: callbackUrl,
        callbackUrlScheme: callbackUrlScheme,
        options: const FlutterWebAuth2Options(
          timeout: 60,
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
      http.Response resp = await http.post(tokenEndpoint, body: body);
      return resp;
    } catch (e, t) {
      print("$e $t");
      return null;
    }
  }
}
