import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// An OAuth transaction also owns its temporary exception to background locking.
/// It never restores a transaction after process death or persists a callback.
class IOSOAuthSession with WidgetsBindingObserver {
  IOSOAuthSession({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static final instance = IOSOAuthSession();
  static const timeout = Duration(minutes: 5);
  final DateTime Function() _now;
  bool _active = false;
  bool _awaitingForeground = false;
  bool _observing = false;
  DateTime? _deadline;

  bool get protectsAutoLock =>
      (_active || _awaitingForeground) &&
      _deadline != null &&
      _now().isBefore(_deadline!);

  Future<String> authenticate({
    required Uri authorizationUrl,
    required Uri callbackUrl,
    required String state,
  }) async {
    if (_active) throw const IOSOAuthException('in_progress');
    if (state.isEmpty ||
        callbackUrl.scheme.isEmpty ||
        callbackUrl.scheme == 'http' ||
        callbackUrl.userInfo.isNotEmpty ||
        callbackUrl.hasQuery ||
        callbackUrl.hasFragment ||
        (callbackUrl.scheme == 'https' && callbackUrl.host.isEmpty)) {
      throw const IOSOAuthException('invalid_configuration');
    }
    _active = true;
    _awaitingForeground = false;
    _deadline = _now().add(timeout);
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authorizationUrl.toString(),
        callbackUrl: callbackUrl.toString(),
        callbackUrlScheme: callbackUrl.scheme,
        options: FlutterWebAuth2Options(
          timeout: timeout.inSeconds,
          useWebview: false,
          httpsHost: callbackUrl.scheme == 'https' ? callbackUrl.host : null,
          httpsPath: callbackUrl.scheme == 'https' ? callbackUrl.path : null,
        ),
      );
      if (!_now().isBefore(_deadline!)) {
        throw const IOSOAuthException('expired');
      }
      final returned = Uri.tryParse(result);
      if (returned == null ||
          returned.scheme != callbackUrl.scheme ||
          returned.host != callbackUrl.host ||
          returned.port != callbackUrl.port ||
          returned.path != callbackUrl.path ||
          returned.userInfo.isNotEmpty ||
          returned.hasFragment) {
        throw const IOSOAuthException('invalid_callback');
      }
      final parameters = returned.queryParametersAll;
      if (parameters['state']?.length != 1 ||
          parameters['state']!.single != state) {
        throw const IOSOAuthException('state_mismatch');
      }
      if (parameters.containsKey('error')) {
        throw const IOSOAuthException('authorization_denied');
      }
      final codes = parameters['code'];
      if (codes == null || codes.length != 1 || codes.single.trim().isEmpty) {
        throw const IOSOAuthException('missing_code');
      }
      return codes.single;
    } finally {
      _active = false;
      // iOS can deliver the callback before the foreground lifecycle event.
      // Keep only that pending return protected, with the original deadline.
      if (!_awaitingForeground) _stopObserving();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _awaitingForeground = _active;
    } else if (state == AppLifecycleState.resumed) {
      // Other observers must see the same protection regardless of their order.
      scheduleMicrotask(() {
        _awaitingForeground = false;
        if (!_active) _stopObserving();
      });
    }
  }

  void _stopObserving() {
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    _observing = false;
  }
}

/// Contains no URL, authorization code, or provider error text: safe to log.
class IOSOAuthException implements Exception {
  const IOSOAuthException(this.code);
  final String code;
  @override
  String toString() => 'iOS OAuth: $code';
}
