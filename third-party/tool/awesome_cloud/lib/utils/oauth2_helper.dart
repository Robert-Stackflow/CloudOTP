import 'dart:convert';
import 'dart:math';

import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:hashlib/hashlib.dart';

class OAuth2Helper {
  static String generateStateParameter([int length = 32]) {
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

  static String generateCodeChanllenge(String codeVerifier) {
    return myBase64Encode(sha256.string(codeVerifier).bytes);
  }

  static Future<String?> browserAuth({
    required Uri authUri,
    required String callbackUrl,
    required String callbackUrlScheme,
    required String state,
    String? scopes,
  }) async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
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
        throw StateMisMatchException();
      }
      return code;
    } catch (e, t) {
      CloudLogger.debug("OAuth", "Error when browser auth with PKCE", "$e\n$t");
      return null;
    }
  }
}
