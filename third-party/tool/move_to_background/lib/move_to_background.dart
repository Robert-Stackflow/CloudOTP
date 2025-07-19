/// This library is a wrapper for iOS and Android to send the application to the background programmatically.
import 'dart:async';

import 'package:flutter/services.dart';

/// A class containing the static function used.
class MoveToBackground {
  /// The method channel used to contact the native side
  static const MethodChannel _channel =
      const MethodChannel('move_to_background');

  /// Calls the platform-specific function to send the app to the background
  static Future<void> moveTaskToBack() async {
    await _channel.invokeMethod('moveTaskToBack');
  }
}
