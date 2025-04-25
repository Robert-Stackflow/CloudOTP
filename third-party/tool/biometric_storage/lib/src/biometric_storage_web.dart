import 'dart:async';
import 'package:web/web.dart' as web show window;

import 'package:biometric_storage/src/biometric_storage.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// A web implementation of the BiometricStorage plugin.
class BiometricStoragePluginWeb extends BiometricStorage {
  BiometricStoragePluginWeb() : super.create();

  static const namePrefix = 'design.codeux.authpass.';

  static void registerWith(Registrar registrar) {
    BiometricStorage.instance = BiometricStoragePluginWeb();
  }

  @override
  Future<CanAuthenticateResponse> canAuthenticate() async =>
      CanAuthenticateResponse.errorHwUnavailable;

  @override
  Future<BiometricStorageFile> getStorage(
    String name, {
    StorageFileInitOptions? options,
    bool forceInit = false,
    PromptInfo promptInfo = PromptInfo.defaultValues,
  }) async {
    return BiometricStorageFile(this, namePrefix + name, promptInfo);
  }

  @override
  Future<bool> delete(
    String name,
    PromptInfo promptInfo,
  ) async {
    final oldValue = web.window.localStorage.getItem(name);
    web.window.localStorage.removeItem(name);
    return oldValue != null;
  }

  @override
  Future<bool> linuxCheckAppArmorError() async => false;

  @override
  Future<String?> read(
    String name,
    PromptInfo promptInfo,
  ) async {
    return web.window.localStorage.getItem(name);
  }

  @override
  Future<void> write(
    String name,
    String content,
    PromptInfo promptInfo,
  ) async {
    web.window.localStorage.setItem(name, content);
  }
}
