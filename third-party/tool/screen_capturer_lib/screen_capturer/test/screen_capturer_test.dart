import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:screen_capturer/screen_capturer.dart';

class MockScreenCapturerPlatform
    with MockPlatformInterfaceMixin
    implements ScreenCapturerPlatform {
  @override
  SystemScreenCapturer get systemScreenCapturer => throw UnimplementedError();

  @override
  Future<bool> isAccessAllowed() {
    return Future(() => true);
  }

  @override
  Future<void> requestAccess({
    bool onlyOpenPrefPane = false,
  }) {
    throw UnimplementedError('requestAccess() has not been implemented.');
  }

  @override
  Future<Uint8List?> readImageFromClipboard() {
    throw UnimplementedError(
      'readImageFromClipboard() has not been implemented.',
    );
  }

  @override
  Future<void> saveClipboardImageAsPngFile({
    required String imagePath,
  }) {
    throw UnimplementedError(
      'saveClipboardImageAsPngFile() has not been implemented.',
    );
  }

  @override
  Future<void> captureScreen({
    required String imagePath,
  }) async {
    throw UnimplementedError('captureScreen() has not been implemented.');
  }

  @override
  Future<CapturedData?> capture({
    required CaptureMode mode,
    String? imagePath,
    bool copyToClipboard = true,
    bool silent = true,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final ScreenCapturerPlatform initialPlatform =
      ScreenCapturerPlatform.instance;

  test('$MethodChannelScreenCapturer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelScreenCapturer>());
  });

  test('getCursorScreenPoint', () async {
    ScreenCapturer screenCapturer = ScreenCapturer.instance;
    MockScreenCapturerPlatform fakePlatform = MockScreenCapturerPlatform();
    ScreenCapturerPlatform.instance = fakePlatform;

    expect(
      await screenCapturer.isAccessAllowed(),
      true,
    );
  });
}
