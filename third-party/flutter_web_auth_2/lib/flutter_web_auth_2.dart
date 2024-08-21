import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/src/options.dart';
import 'package:flutter_web_auth_2_platform_interface/flutter_web_auth_2_platform_interface.dart';

export 'src/options.dart';
export 'src/unsupported.dart'
    if (dart.library.io) 'src/linows.dart'
    if (dart.library.js_interop) 'src/web.dart';

class _OnAppLifecycleResumeObserver extends WidgetsBindingObserver {
  _OnAppLifecycleResumeObserver(this.onResumed);

  final Future<void> Function() onResumed;

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await onResumed();
    }
  }
}

/// Provides all the functions you - as a user - should access.
class FlutterWebAuth2 {
  static final RegExp _schemeRegExp = RegExp(r'^[a-z][a-z\d+.-]*$');

  static FlutterWebAuth2Platform get _platform =>
      FlutterWebAuth2Platform.instance;

  static final _OnAppLifecycleResumeObserver _resumedObserver =
      _OnAppLifecycleResumeObserver(_cleanUpDanglingCalls);

  static void _assertCallbackScheme(String callbackUrlScheme) {
    if ((kIsWeb || (!Platform.isWindows && !Platform.isLinux)) &&
        !_schemeRegExp.hasMatch(callbackUrlScheme)) {
      throw ArgumentError.value(
        callbackUrlScheme,
        'callbackUrlScheme',
        'must be a valid URL scheme',
      );
    }
  }

  /// Ask the user to authenticate to the specified web service.
  ///
  /// The page pointed to by [url] will be loaded and displayed to the user.
  /// From the page, the user can authenticate herself and grant access to the
  /// app. On completion, the service will send a callback URL with an
  /// authentication token, and this URL will be result of the returned
  /// [Future].
  ///
  /// [callbackUrlScheme] should be a string specifying the scheme of the URL
  /// that the page will redirect to upon successful authentication.
  /// If it is `https`, you also need to specify
  /// [FlutterWebAuth2Options.httpsHost] and [FlutterWebAuth2Options.httpsPath]
  /// on Apple devices running iOS >= 17.4 or macOS >= 14.4. This allows for
  /// easy integration of Universal links.
  ///
  /// [options] can be used to specify either both general and
  /// platform-specific settings.
  static Future<String> authenticate({
    required String url,
    required String callbackUrl,
    required String callbackUrlScheme,
    FlutterWebAuth2Options options = const FlutterWebAuth2Options(),
  }) async {
    assert(
      !(kIsWeb && options.debugOrigin != null && !kDebugMode),
      'Do not use debugOrigin in production',
    );

    _assertCallbackScheme(callbackUrlScheme);

    WidgetsBinding.instance.removeObserver(
      _resumedObserver,
    ); // safety measure so we never add this observer twice
    WidgetsBinding.instance.addObserver(_resumedObserver);
    return _platform.authenticate(
      url: url,
      callbackUrl: callbackUrl,
      callbackUrlScheme: callbackUrlScheme,
      options: options.toJson(),
    );
  }

  /// The plugin may need to store the resulting callbacks in order to pass
  /// the result back to the caller of `authenticate`. But if that result never
  /// comes the callback will dangle around forever. This can be called to
  /// terminate all `authenticate` calls with an error.
  static Future<void> _cleanUpDanglingCalls() async {
    // await _platform.clearAllDanglingCalls();
    WidgetsBinding.instance.removeObserver(_resumedObserver);
  }
}
