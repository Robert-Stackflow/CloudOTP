import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_capturer_platform_interface/src/screen_capturer_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelScreenCapturer platform = MethodChannelScreenCapturer();
  const MethodChannel channel = MethodChannel(
    'dev.leanflutter.plugins/screen_capturer',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'isAccessAllowed':
            return true;
        }
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isAccessAllowed', () async {
    expect(await platform.isAccessAllowed(), true);
  });
}
