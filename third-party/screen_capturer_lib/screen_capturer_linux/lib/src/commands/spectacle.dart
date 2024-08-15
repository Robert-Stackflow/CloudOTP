import 'dart:io';

import 'package:screen_capturer_platform_interface/screen_capturer_platform_interface.dart';
import 'package:shell_executor/shell_executor.dart';

final Map<CaptureMode, List<String>> _knownCaptureModeArgs = {
  CaptureMode.region: ['-r'],
  CaptureMode.screen: ['-f'],
  CaptureMode.window: ['-a'],
};

class _Spectacle extends Command with SystemScreenCapturer {
  @override
  String get executable {
    return 'spectacle';
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
        '-b',
        '-n',
        ..._knownCaptureModeArgs[mode]!,
        ...(copyToClipboard ? ['-c'] : []),
        ...(imagePath != null ? ['-o', imagePath] : []),
      ],
    );
  }
}

final spectacle = _Spectacle();
