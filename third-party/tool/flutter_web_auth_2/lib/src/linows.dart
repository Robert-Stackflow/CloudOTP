import 'dart:async';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_web_auth_2/src/server.dart';
import 'package:flutter_web_auth_2_platform_interface/flutter_web_auth_2_platform_interface.dart';

/// Implements the plugin interface for Linux and Windows (Linows).
class FlutterWebAuth2LinowsPlugin extends FlutterWebAuth2Platform {
  final FlutterWebAuth2Platform _serverImpl = FlutterWebAuth2ProtocolPlugin();

  /// Registers the Linows super-implementation.
  static void registerWith() {
    FlutterWebAuth2Platform.instance = FlutterWebAuth2LinowsPlugin();
  }

  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrl,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) async {
    final parsedOptions = FlutterWebAuth2Options.fromJson(options);
    return _serverImpl.authenticate(
      url: url,
      callbackUrl: callbackUrl,
      callbackUrlScheme: callbackUrlScheme,
      options: options,
    );
  }

  @override
  Future clearAllDanglingCalls() async {
    await _serverImpl.clearAllDanglingCalls();
  }
}
