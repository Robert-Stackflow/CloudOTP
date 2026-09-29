import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  tearDown(() {
    CloudLogger.logError = null;
  });

  test('redacts common credentials from messages and errors', () {
    String? loggedMessage;
    dynamic loggedError;
    CloudLogger.logError = (tag, message, [error, stackTrace]) {
      loggedMessage = message;
      loggedError = error;
    };

    CloudLogger.error(
      'OAuth',
      'access_token=message-secret password: hunter2',
      Exception('Authorization: Bearer error-secret'),
    );

    expect(loggedMessage, isNot(contains('message-secret')));
    expect(loggedMessage, isNot(contains('hunter2')));
    expect(loggedError.toString(), isNot(contains('error-secret')));
    expect(loggedMessage, contains('[REDACTED]'));
  });

  test('omits HTTP response bodies', () {
    String? loggedMessage;
    CloudLogger.logError = (tag, message, [error, stackTrace]) {
      loggedMessage = message;
    };

    CloudLogger.errorResponse(
      'OAuth',
      'Token refresh failed',
      http.Response('{"refresh_token":"response-secret"}', 401),
    );

    expect(loggedMessage, contains('401'));
    expect(loggedMessage, contains('body omitted'));
    expect(loggedMessage, isNot(contains('response-secret')));
  });
}
