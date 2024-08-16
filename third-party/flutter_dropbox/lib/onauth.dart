import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

class OAuth2Helper {
  static HttpServer? server;

  static Future<http.Response?> browserAuth({
    required BuildContext? context,
    required Uri authEndpoint,
    required Uri tokenEndpoint,
    required String callbackUrlScheme,
    required String clientID,
    required String codeVerifier,
    required String redirectURL,
    String? windowName,
    String? scopes,
  }) async {
    try {
      print(authEndpoint);
      final result = await FlutterWebAuth2.authenticate(
        url: authEndpoint.toString(),
        callbackUrlScheme: callbackUrlScheme,
        options: FlutterWebAuth2Options(
          timeout: 5,
          windowName: windowName,
        ),
      );
      final String code = Uri.parse(result).queryParameters['code'] ?? "";
      http.Response resp = await http.post(tokenEndpoint, body: {
        'client_id': clientID,
        'redirect_uri': redirectURL,
        'code_verifier': codeVerifier,
        'grant_type': 'authorization_code',
        'code': code,
      });
      return resp;
    } catch (e, t) {
      print("$e\n$t");
      return null;
    }
  }
}
