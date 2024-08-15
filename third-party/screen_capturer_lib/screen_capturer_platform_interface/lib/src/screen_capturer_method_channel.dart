import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_capturer_platform_interface/src/screen_capturer_platform.dart';
import 'package:screen_capturer_platform_interface/src/system_screen_capturer.dart';

/// An implementation of [ScreenCapturerPlatform] that uses method channels.
class MethodChannelScreenCapturer extends ScreenCapturerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'dev.leanflutter.plugins/screen_capturer',
  );

  @override
  SystemScreenCapturer get systemScreenCapturer => throw UnimplementedError();

  @override
  Future<bool> isAccessAllowed() async {
    if (!kIsWeb && Platform.isMacOS) {
      return await methodChannel.invokeMethod<bool>('isAccessAllowed') ?? false;
    }
    return true;
  }

  @override
  Future<void> requestAccess({
    bool onlyOpenPrefPane = false,
  }) async {
    if (!kIsWeb && Platform.isMacOS) {
      final Map<String, dynamic> arguments = {
        'onlyOpenPrefPane': onlyOpenPrefPane,
      };
      await methodChannel.invokeMethod('requestAccess', arguments);
    }
  }

  @override
  Future<Uint8List?> readImageFromClipboard() async {
    final image = await methodChannel.invokeMethod('readImageFromClipboard');
    if (image != null) {
      if (!kIsWeb &&
          (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
        return image as Uint8List;
      }
    }
    return null;
  }

  @override
  Future<void> saveClipboardImageAsPngFile({
    required String imagePath,
  }) async {
    await methodChannel.invokeMethod('saveClipboardImageAsPngFile', {
      'imagePath': imagePath,
    });
  }

  @override
  Future<void> captureScreen({
    required String imagePath,
  }) async {
    await methodChannel.invokeMethod('captureScreen', {
      'imagePath': imagePath,
    });
  }
}
