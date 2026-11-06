import 'dart:async';

import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class TrackingClient extends MockClient {
  TrackingClient(super.handler);
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  final endpoint = Uri.parse('https://example.com/oauth/login');
  for (final status in [200, 302, 503]) {
    test('iOS preflight handles $status without following the browser redirect',
        () async {
      final client = TrackingClient((request) async {
        expect(request.method, 'HEAD');
        expect(request.followRedirects, isFalse);
        return http.Response('', status,
            headers: {'location': 'https://accounts.google.com/authorize'});
      });
      expect(await IOSOAuthHttp.isAvailable(endpoint, client: client),
          status < 400);
      expect(client.closed, isTrue);
    });
  }
  test('timeout closes the connection and remains a transient network error',
      () async {
    final pending = Completer<http.Response>();
    final client = TrackingClient((_) => pending.future);
    await expectLater(
        IOSOAuthHttp.run((c) => c.get(endpoint),
            timeout: const Duration(milliseconds: 10), client: client),
        throwsA(isA<http.ClientException>()));
    expect(client.closed, isTrue);
    pending.complete(http.Response('', 200));
  });
  test('request failure also releases the connection', () async {
    final client =
        TrackingClient((_) async => throw http.ClientException('offline'));
    expect(await IOSOAuthHttp.isAvailable(endpoint, client: client), isFalse);
    expect(client.closed, isTrue);
  });
}
