import 'dart:io';
import 'package:cloudotp/Platform/ios/ios_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'iOS system integration does not invoke native services on other platforms',
      () async {
    if (Platform.isIOS) return;
    final calls = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(IOSServices.channel, (call) async {
      calls.add(call.method);
      throw StateError('An iOS call leaked onto a different platform');
    });
    addTearDown(
        () => messenger.setMockMethodCallHandler(IOSServices.channel, null));
    expect(await IOSServices.withSystemAuthentication(() async => 42), 42);
    expect(await IOSServices.status(), isEmpty);
    await IOSServices.syncAutoFill();
    expect(await IOSServices.beginBackup(), isNull);
    await IOSServices.endBackup(1);
    await IOSServices.notifyBackup('Backup finished');
    expect(calls, isEmpty);
  });
}
