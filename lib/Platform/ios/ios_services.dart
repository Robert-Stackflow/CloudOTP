import 'dart:convert';
import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/services.dart';

import '../../Database/database_manager.dart';
import '../../Database/token_dao.dart';
import '../../Models/opt_token.dart';

/// All native calls are gated here so other platform paths stay unchanged.
class IOSServices {
  /// Balance privacy-cover exceptions even if a Keychain prompt fails/cancels.
  static Future<T> withSystemAuthentication<T>(
      Future<T> Function() action) async {
    if (!ResponsiveUtil.isIOS()) return action();
    final lease =
        await channel.invokeMethod<String>('beginSystemAuthentication');
    try {
      return await action();
    } finally {
      if (lease != null) {
        await channel.invokeMethod('endSystemAuthentication', {'id': lease});
      }
    }
  }

  static Map<String, dynamic>? cachedStatus;
  static const channel = MethodChannel('cloudotp/ios');
  static Future<void> _syncQueue = Future.value();

  static Future<Map<String, dynamic>> status() async {
    if (!ResponsiveUtil.isIOS()) return {};
    final value = Map<String, dynamic>.from(
        await channel.invokeMapMethod<String, dynamic>('status') ?? {});
    cachedStatus = value;
    return value;
  }

  static Map<String, dynamic> get autoFillDomains => Map<String, dynamic>.from(
      jsonDecode(ChewieHiveUtil.getString('iosAutoFillDomains') ?? '{}')
          as Map);

  static Future<void> saveDomains(Map<String, dynamic> domains) =>
      ChewieHiveUtil.put('iosAutoFillDomains', jsonEncode(domains));

  static Future<void> syncAutoFill({bool reportErrors = false}) {
    if (!ResponsiveUtil.isIOS() || !DatabaseManager.initialized) {
      return Future.value();
    }
    final operation = _syncQueue.then((_) async {
      if ((await status())['autofillEnabled'] != true) return;
      final tokens = await TokenDao.listTokens();
      final domains = autoFillDomains;
      final records = tokens
          .where((t) => t.tokenType == OtpTokenType.TOTP)
          .map((t) => {
                'uid': t.uid,
                'issuer': t.issuer,
                'account': t.account,
                'secret': t.secret,
                'algorithm': t.algorithm.name,
                'digits': t.digits.digit,
                'period': t.period,
                'domain': domains[t.uid],
              })
          .toList();
      await channel.invokeMethod('syncAutoFill', {'tokens': records});
    });
    _syncQueue = operation.catchError((Object error, StackTrace stack) {
      ILogger.error('Unable to sync iOS AutoFill', error, stack);
    });
    return reportErrors ? operation : _syncQueue;
  }

  static Future<int?> beginBackup() async {
    if (!ResponsiveUtil.isIOS()) return null;
    try {
      return await channel.invokeMethod<int>('beginBackup');
    } catch (_) {
      return null;
    }
  }

  static Future<void> endBackup(int? id) async {
    if (!ResponsiveUtil.isIOS() || id == null) return;
    try {
      await channel.invokeMethod('endBackup', {'id': id});
    } catch (_) {}
  }

  static Future<void> notifyBackup(String message) async {
    if (!ResponsiveUtil.isIOS()) return;
    try {
      await channel.invokeMethod('notifyBackup', {'body': message});
    } catch (error, stack) {
      ILogger.error('Unable to post iOS backup notification', error, stack);
    }
  }
}
