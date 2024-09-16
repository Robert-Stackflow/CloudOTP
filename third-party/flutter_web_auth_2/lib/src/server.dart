import 'dart:async';

import 'package:flutter_web_auth_2_platform_interface/flutter_web_auth_2_platform_interface.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Implements the plugin interface using an internal server
class AuthProtocolListener implements ProtocolListener {
  /// Creates a new instance of the [AuthProtocolListener]
  const AuthProtocolListener(this.onReceivedUrl);

  /// Callback for when a URL is received
  final Function(String) onReceivedUrl;

  @override
  Future<void> onProtocolUrlReceived(String url) async {
    onReceivedUrl.call(url);
  }
}

/// Implements the plugin interface using an internal server (currently used by
/// Windows and Linux).
class FlutterWebAuth2ProtocolPlugin extends FlutterWebAuth2Platform {
  /// Registers the server implementation.
  FlutterWebAuth2ProtocolPlugin() {
    _protocolListener = AuthProtocolListener((url) async {
      if (url.contains(_callbackUrl)) {
        _handleUriCallback(url);
        protocolHandler.removeListener(_protocolListener);
      }
    });
  }

  ///[optional] CallbackUrl is used to match whether the received URI
  ///matches the redirect address
  String _callbackUrl = '';
  late AuthProtocolListener _protocolListener;

  Completer<String>? _completer;

  void _handleUriCallback(String uri) {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(uri);
    }
  }

  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrl,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) async {
    _callbackUrl = callbackUrl;
    protocolHandler.addListener(_protocolListener);

    ///Block the thread until the _handleUriCallback method is actively called
    _completer = Completer<String>();

    await launchUrl(Uri.parse(url));

    return _completer!.future;
  }

  @override
  Future clearAllDanglingCalls() async {
    ///If the user cancels the authentication process, the _completer will
    ///never be completed. This will cause the thread to hang indefinitely.
    ///This method is used to clear all dangling calls.
    _handleUriCallback('');
  }
}
