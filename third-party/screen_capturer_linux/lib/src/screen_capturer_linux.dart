import 'package:screen_capturer_linux/src/commands/gnome_screenshot.dart';
import 'package:screen_capturer_linux/src/commands/spectacle.dart';
import 'package:screen_capturer_platform_interface/screen_capturer_platform_interface.dart';
import 'package:shell_executor/shell_executor.dart';

class ScreenCapturerLinux extends MethodChannelScreenCapturer {
  /// The [ScreenCapturerLinux] constructor.
  ScreenCapturerLinux() : super();

  /// Registers this class as the default instance of [ScreenCapturerLinux].
  static void registerWith() {
    ScreenCapturerPlatform.instance = ScreenCapturerLinux();
  }

  bool? _isKdeDesktop;

  bool get isKdeDesktop {
    if (_isKdeDesktop == null) {
      try {
        final result = ShellExecutor.global.execSync('pgrep', ['plasmashell']);
        _isKdeDesktop = result.exitCode == 0;
      } catch (_) {
        _isKdeDesktop = false;
      }
    }
    return _isKdeDesktop!;
  }

  @override
  SystemScreenCapturer get systemScreenCapturer {
    if (isKdeDesktop) {
      return spectacle;
    }
    return gnomeScreenshot;
  }
}
