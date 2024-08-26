import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:screen_capturer_platform_interface/screen_capturer_platform_interface.dart';

class ScreenCapturer {
  ScreenCapturer._();

  /// The shared instance of [ScreenCapturer].
  static final ScreenCapturer instance = ScreenCapturer._();

  ScreenCapturerPlatform get _platform => ScreenCapturerPlatform.instance;

  /// Checks whether the current process already has screen capture access
  ///
  /// macOS only
  Future<bool> isAccessAllowed() {
    return _platform.isAccessAllowed();
  }

  /// Requests screen capture access
  ///
  /// macOS only
  Future<void> requestAccess({
    bool onlyOpenPrefPane = false,
  }) {
    return _platform.requestAccess(
      onlyOpenPrefPane: onlyOpenPrefPane,
    );
  }

  /// Reads an image from the clipboard
  ///
  /// Returns a [Uint8List] object
  Future<Uint8List?> readImageFromClipboard() {
    return _platform.readImageFromClipboard();
  }

  /// Captures the screen and saves it to the specified [imagePath]
  ///
  /// Returns a [CapturedData] object with the image path, width, height and base64 encoded image
  Future<CapturedData?> capture({
    CaptureMode mode = CaptureMode.region,
    String? imagePath,
    bool copyToClipboard = true,
    bool silent = true,
  }) async {
    File? imageFile;
    if (imagePath != null) {
      imageFile = File(imagePath);
      if (!imageFile.parent.existsSync()) {
        imageFile.parent.create(recursive: true);
      }
    }
    if (copyToClipboard) {
      Clipboard.setData(const ClipboardData(text: ''));
    }
    await _platform.systemScreenCapturer.capture(
      mode: mode,
      imagePath: imagePath,
      copyToClipboard: copyToClipboard,
      silent: silent,
    );

    Uint8List? imageBytes;
    if (imageFile != null && imageFile.existsSync()) {
      imageBytes = imageFile.readAsBytesSync();
    }
    if (copyToClipboard) {
      imageBytes = await readImageFromClipboard();
    }

    if (imageBytes != null) {
      // 系统截图命令当传入复制到剪切板时，不会保存到文件，所以这里需要手动保存
      if (imageFile != null && !imageFile.existsSync()) {
        imageFile.writeAsBytesSync(imageBytes);
      }
      final decodedImage = await decodeImageFromList(imageBytes);
      return CapturedData(
        imagePath: imagePath,
        imageWidth: decodedImage.width,
        imageHeight: decodedImage.height,
        imageBytes: imageBytes,
      );
    }
    return null;
  }
}

final screenCapturer = ScreenCapturer.instance;
