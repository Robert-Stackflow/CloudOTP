import 'dart:io';

import 'package:screen_capturer_platform_interface/screen_capturer_platform_interface.dart';
import 'package:shell_executor/shell_executor.dart';

final Map<CaptureMode, List<String>> _knownCaptureModeArgs = {
  CaptureMode.region: ['-a'],
  CaptureMode.screen: [],
  CaptureMode.window: ['-w'],
};

class _GnomeScreenshot extends Command with SystemScreenCapturer {
  @override
  String get executable {
    return 'gnome-screenshot';
  }

  @override
  Future<void> install() {
    throw UnimplementedError();
  }

  @override
  Future<ProcessResult> capture({
    required CaptureMode mode,
    String? imagePath,
    bool copyToClipboard = true,
    bool silent = true,
  }) {
    return exec(
      [
        ..._knownCaptureModeArgs[mode]!,
        ...(copyToClipboard ? ['-c'] : []),
        ...(imagePath != null ? ['-f', imagePath] : []),
      ],
    );
  }
}

final gnomeScreenshot = _GnomeScreenshot();
