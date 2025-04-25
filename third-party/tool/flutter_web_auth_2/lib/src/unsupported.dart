import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2_platform_interface/flutter_web_auth_2_platform_interface.dart';

/// Implements the plugin interface for unsupported platforms (just throws
/// errors).
class FlutterWebAuth2UnsupportedPlugin extends FlutterWebAuth2Platform {
  /// Registers the unsupported implementation.
  static void registerWith() {
    FlutterWebAuth2Platform.instance = FlutterWebAuth2UnsupportedPlugin();
  }

  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrl,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) async {
    throw PlatformException(
      message: 'Platform either unsupported or unrecognised.',
      code: 'UNSUPPORTED',
    );
  }

  @override
  Future clearAllDanglingCalls() async {
    throw PlatformException(
      message: 'Platform either unsupported or unrecognised.',
      code: 'UNSUPPORTED',
    );
  }
}
