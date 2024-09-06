package com.ivehement.saf.plugin

import io.flutter.plugin.common.BinaryMessenger

/// Interface shared across API classes to make
/// intuitive and clean [init] and [dispose] plugin lifecycle of [MethodCallHandler] resources
interface Listenable {
  fun startListening(binaryMessenger: BinaryMessenger);
  fun stopListening();
}