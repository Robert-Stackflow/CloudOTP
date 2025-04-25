import 'package:screen_capturer_macos/src/commands/screencapture.dart';
import 'package:screen_capturer_platform_interface/screen_capturer_platform_interface.dart';

class ScreenCapturerMacos extends MethodChannelScreenCapturer {
  /// The [ScreenCapturerMacos] constructor.
  ScreenCapturerMacos() : super();

  /// Registers this class as the default instance of [ScreenCapturerMacos].
  static void registerWith() {
    ScreenCapturerPlatform.instance = ScreenCapturerMacos();
  }

  @override
  SystemScreenCapturer get systemScreenCapturer => screencapture;
}
