import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/src/options.dart';
import 'package:flutter_web_auth_2_platform_interface/flutter_web_auth_2_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart';

/// Implements the plugin interface using iframes (for silent authentication)
/// and through an event listener system (for usual authentication).
class FlutterWebAuth2WebPlugin extends FlutterWebAuth2Platform {
  /// Registers the web implementation.
  static void registerWith(Registrar registrar) {
    final channel = MethodChannel(
      'flutter_web_auth_2',
      const StandardMethodCodec(),
      registrar,
    );
    final instance = FlutterWebAuth2WebPlugin();
    channel.setMethodCallHandler(instance._handleMethodCall);
    FlutterWebAuth2Platform.instance = instance;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'authenticate':
        final url = call.arguments['url'].toString();
        return authenticate(
          url: url,
          callbackUrl: call.arguments['callbackUrl'].toString(),
          callbackUrlScheme: '',
          options: call.arguments['options'],
        );
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: "The flutter_web_auth_2 plugin for web doesn't implement "
              "the method '${call.method}'",
        );
    }
  }

  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrl,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) async {
    final parsedOptions = FlutterWebAuth2Options.fromJson(options);

    if (parsedOptions.silentAuth) {
      final authIframe = (document.createElement('iframe') as HTMLIFrameElement)
        ..src = url
        ..style.display = 'none';

      document.body?.append(authIframe);

      final completer = Completer<String>();
      StreamSubscription? messageSubscription;
      Timer? responseTimeoutTimer;

      messageSubscription = window.onMessage.listen((messageEvent) {
        if (messageEvent.origin ==
            (parsedOptions.debugOrigin ?? Uri.base.origin)) {
          final data = messageEvent.data.dartify();
          final authMessage =
              data != null && data is Map ? data['flutter-web-auth-2'] : null;
          if (authMessage is String) {
            authIframe.remove();
            completer.complete(authMessage);
            responseTimeoutTimer?.cancel();
            messageSubscription?.cancel();
          }
        }
      });

      // Add a timeout for the iframe response
      responseTimeoutTimer =
          Timer(Duration(seconds: parsedOptions.timeout), () {
        authIframe.remove();
        messageSubscription?.cancel();
        completer.completeError(
          PlatformException(
            code: 'timeout',
            message: 'Timeout waiting for the iframe response',
          ),
        );
      });

      return completer.future;
    }

    await launchUrl(
      Uri.parse(url),
      webOnlyWindowName: parsedOptions.windowName,
    );

    // Remove the old record if it exists
    const storageKey = 'flutter-web-auth-2';
    window.localStorage.removeItem(storageKey);
    Timer? lsTimer;
    StreamSubscription? messageSubscription;
    final completer = Completer<String>();
    try {
      // Periodically check for the callback value in local storage.
      // If it exists, return it. If not, check the timeout.
      // If the timeout has passed, throw an exception.
      lsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final flutterWebAuthMessage = window.localStorage.getItem(storageKey);
        if (flutterWebAuthMessage != null) {
          completer.complete(flutterWebAuthMessage);
          window.localStorage.removeItem(storageKey);
          messageSubscription?.cancel();
          timer.cancel();
        } else if (timer.tick >= parsedOptions.timeout) {
          messageSubscription?.cancel();
          timer.cancel();
          completer.completeError(
            PlatformException(
              code: 'error',
              message: 'Timeout waiting for callback value',
            ),
          );
        }
      });

      // Traditional window.opener method of listening for the redirect
      messageSubscription = window.onMessage.listen(
        (messageEvent) {
          if (messageEvent.origin ==
              (parsedOptions.debugOrigin ?? Uri.base.origin)) {
            final data = messageEvent.data.dartify();
            final flutterWebAuthMessage =
                data != null && data is Map ? data['flutter-web-auth-2'] : null;
            if (flutterWebAuthMessage is String) {
              lsTimer?.cancel();
              messageSubscription?.cancel();
              completer.complete(flutterWebAuthMessage);
            }
          }

          final appleOrigin = Uri(scheme: 'https', host: 'appleid.apple.com');
          if (messageEvent.origin == appleOrigin.toString()) {
            try {
              final data = jsonDecode(messageEvent.data.toString());
              if (data['method'] == 'oauthDone') {
                final appleAuth =
                    data['data']['authorization'] as Map<String, dynamic>?;
                if (appleAuth != null) {
                  final appleAuthQuery = Uri(queryParameters: appleAuth).query;
                  lsTimer?.cancel();
                  messageSubscription?.cancel();
                  completer.complete(
                    appleOrigin.replace(fragment: appleAuthQuery).toString(),
                  );
                }
              }
            } on FormatException {
              // ignore exception
            }
          }
        },
        onError: (error) {
          lsTimer?.cancel();
          messageSubscription?.cancel();
          throw error;
        },
      );
    } catch (e) {
      lsTimer?.cancel();
      completer.completeError(e);
    }

    return completer.future;
  }

  @override
  Future<void> clearAllDanglingCalls() async {}
}
