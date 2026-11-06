import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Bounded iOS OAuth requests. A timeout closes the underlying connection too.
class IOSOAuthHttp {
  static bool get enabled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Future<T> run<T>(
    Future<T> Function(http.Client client) action, {
    Duration timeout = const Duration(seconds: 30),
    http.Client? client,
  }) async {
    final connection = client ?? http.Client();
    try {
      return await action(connection).timeout(timeout);
    } on TimeoutException {
      // Token refresh treats ClientException as transient and retains credentials.
      throw http.ClientException('The OAuth request timed out.');
    } finally {
      connection.close();
    }
  }

  static Future<bool> isAvailable(Uri endpoint, {http.Client? client}) async {
    try {
      return await run((connection) async {
        // An authorization endpoint redirects by design. Do not preflight the
        // provider login page, create a second browser session, or await Google.
        final request = http.Request('HEAD', endpoint)..followRedirects = false;
        final response = await connection.send(request);
        return response.statusCode >= 200 && response.statusCode < 400;
      }, timeout: const Duration(seconds: 10), client: client);
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    if (!enabled) {
      return http.post(url, headers: headers, body: body, encoding: encoding);
    }
    return run((client) =>
        client.post(url, headers: headers, body: body, encoding: encoding));
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    if (!enabled) return http.get(url, headers: headers);
    return run((client) => client.get(url, headers: headers));
  }
}
