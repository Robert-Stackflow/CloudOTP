import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:screen_capturer_platform_interface/src/capture_mode.dart';
import 'package:screen_capturer_platform_interface/src/captured_data.dart';
import 'package:screen_capturer_platform_interface/src/screen_capturer_method_channel.dart';
import 'package:screen_capturer_platform_interface/src/system_screen_capturer.dart';

abstract class ScreenCapturerPlatform extends PlatformInterface {
  /// Constructs a ScreenCapturerPlatform.
  ScreenCapturerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScreenCapturerPlatform _instance =
      MethodChannelScreenCapturer() as ScreenCapturerPlatform;

  /// The default instance of [ScreenCapturerPlatform] to use.
  ///
  /// Defaults to [MethodChannelScreenCapturer].
  static ScreenCapturerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScreenCapturerPlatform] when
  /// they register themselves.
  static set instance(ScreenCapturerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  SystemScreenCapturer get systemScreenCapturer;

  Future<bool> isAccessAllowed() {
    throw UnimplementedError('isAccessAllowed() has not been implemented.');
  }

  Future<void> requestAccess({
    bool onlyOpenPrefPane = false,
  }) {
    throw UnimplementedError('requestAccess() has not been implemented.');
  }

  Future<Uint8List?> readImageFromClipboard() {
    throw UnimplementedError(
      'readImageFromClipboard() has not been implemented.',
    );
  }

  Future<void> saveClipboardImageAsPngFile({
    required String imagePath,
  }) {
    throw UnimplementedError(
      'saveClipboardImageAsPngFile() has not been implemented.',
    );
  }

  Future<void> captureScreen({
    required String imagePath,
  }) async {
    throw UnimplementedError('captureScreen() has not been implemented.');
  }

  Future<CapturedData?> capture({
    required CaptureMode mode,
    String? imagePath,
    bool copyToClipboard = true,
    bool silent = true,
  }) {
    throw UnimplementedError();
  }
}
