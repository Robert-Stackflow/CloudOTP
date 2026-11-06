import 'dart:async';

import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_web_auth_2');
  const state = 'transaction-state';
  final callback = Uri.parse('cloudotp://auth/googledrive/callback');
  final authorization =
      Uri.https('example.com', '/authorize', {'state': state});
  late Future<dynamic> Function(MethodCall) handler;
  late IOSOAuthSession session;
  Future<String> authenticate({Uri? redirect}) => session.authenticate(
        authorizationUrl: authorization,
        callbackUrl: redirect ?? callback,
        state: state,
      );

  setUp(() {
    session = IOSOAuthSession();
    handler = (_) async => '$callback?state=$state&code=test-code';
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) => handler(call));
  });
  tearDown(() async {
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('accepts only the pending redirect and state', () async {
    expect(await authenticate(), 'test-code');
    expect(session.protectsAutoLock, isFalse);
  });

  for (final value in <String>[
    'cloudotp://auth/dropbox/callback?state=$state&code=test-code',
    'cloudotp://attacker/googledrive/callback?state=$state&code=test-code',
    'other://auth/googledrive/callback?state=$state&code=test-code',
    '$callback?state=wrong&code=test-code',
    '$callback?state=$state&state=$state&code=test-code',
    '$callback?state=$state&code=a&code=b',
    '$callback?state=$state&code=',
    '$callback?state=$state&error=access_denied',
    '$callback?state=$state&code=test-code#fragment',
  ]) {
    test('rejects malformed, denied, or unrelated callback ${value.hashCode}',
        () async {
      handler = (_) async => value;
      await expectLater(authenticate(), throwsA(isA<IOSOAuthException>()));
      expect(session.protectsAutoLock, isFalse);
    });
  }

  test('HTTPS uses a scheme plus exact host/path options', () async {
    final https = Uri.parse('https://example.com/oauth/callback');
    handler = (call) async {
      final args = call.arguments as Map;
      expect(args['callbackUrlScheme'], 'https');
      expect(args['options']['httpsHost'], 'example.com');
      expect(args['options']['httpsPath'], '/oauth/callback');
      expect(args['options']['timeout'], 300);
      return '$https?state=$state&code=test-code';
    };
    expect(await authenticate(redirect: https), 'test-code');
  });

  test('rejects concurrent login without replacing the live transaction',
      () async {
    final result = Completer<String>();
    handler = (_) => result.future;
    final pending = authenticate();
    await expectLater(authenticate(), throwsA(isA<IOSOAuthException>()));
    expect(session.protectsAutoLock, isTrue);
    result.complete('$callback?state=$state&code=test-code');
    expect(await pending, 'test-code');
  });

  test('callback before resume preserves only that browser return', () async {
    final result = Completer<String>();
    handler = (_) => result.future;
    final pending = authenticate();
    session.didChangeAppLifecycleState(AppLifecycleState.paused);
    result.complete('$callback?state=$state&code=test-code');
    await pending;
    expect(session.protectsAutoLock, isTrue);
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(session.protectsAutoLock, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(session.protectsAutoLock, isFalse);
    session.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(session.protectsAutoLock, isFalse);
  });

  test('resume before callback and cancel/timeout both release protection',
      () async {
    for (final error in ['CANCELED', 'TIMEOUT', 'START_FAILED']) {
      final result = Completer<String>();
      handler = (_) => result.future;
      final pending = authenticate();
      final expectation =
          expectLater(pending, throwsA(isA<PlatformException>()));
      session.didChangeAppLifecycleState(AppLifecycleState.paused);
      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(session.protectsAutoLock, isTrue);
      result.completeError(PlatformException(code: error));
      await expectation;
      expect(session.protectsAutoLock, isFalse);
    }
  });

  test('an abandoned background login cannot disable locking indefinitely',
      () async {
    var now = DateTime.utc(2026);
    session = IOSOAuthSession(now: () => now);
    final result = Completer<String>();
    handler = (_) => result.future;
    final pending = authenticate();
    session.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 5));
    expect(session.protectsAutoLock, isFalse);
    final rejected = expectLater(pending, throwsA(isA<IOSOAuthException>()));
    result.complete('$callback?state=$state&code=test-code');
    await rejected;
    expect(session.protectsAutoLock, isFalse);
  });

  test('iOS creates fresh state for every attempt and normalizes HTTPS',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final states = <String>[];
    handler = (call) async {
      final args = call.arguments as Map;
      final currentState =
          Uri.parse(args['url'] as String).queryParameters['state']!;
      states.add(currentState);
      expect(args['callbackUrlScheme'], 'https');
      return 'https://example.com/oauth/callback?state=${Uri.encodeQueryComponent(currentState)}&code=test-code';
    };
    for (var i = 0; i < 2; i++) {
      expect(
          await OAuth2Helper.browserAuth(
            authUri: authorization,
            callbackUrl: 'https://example.com/oauth/callback',
            callbackUrlScheme: 'https://example.com/oauth/callback',
            state: state,
          ),
          'test-code');
    }
    expect(states.toSet(), hasLength(2));
    expect(states, isNot(contains(state)));
  });

  test('other platforms preserve their existing arguments and state', () async {
    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      handler = (call) async {
        final args = call.arguments as Map;
        expect(args['url'], authorization.toString());
        expect(args['callbackUrlScheme'], 'cloudotp');
        expect(args['options']['timeout'], 60);
        expect(args['options']['httpsHost'], isNull);
        return '$callback?state=$state&code=test-code';
      };
      expect(
          await OAuth2Helper.browserAuth(
              authUri: authorization,
              callbackUrl: callback.toString(),
              callbackUrlScheme: 'cloudotp',
              state: state),
          'test-code');
    }
  });
}
