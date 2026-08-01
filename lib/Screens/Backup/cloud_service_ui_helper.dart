import 'dart:typed_data';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../TokenUtils/import_token_util.dart';
import '../../l10n/l10n.dart';

class CloudServiceUiHelper {
  const CloudServiceUiHelper._();

  static Future<T> runWithLoading<T>({
    required Future<T> Function() action,
    bool showLoading = true,
    String? title,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(
        title: title ?? appLocalizations.cloudConnecting,
      );
    }
    try {
      return await action();
    } finally {
      if (showLoading) {
        await CustomLoadingDialog.dismissLoading();
      }
    }
  }

  static Future<T?> loadBackups<T>({
    required Future<T?> Function() action,
    required String logName,
  }) async {
    try {
      final result = await runWithLoading<T?>(
        action: action,
        title: appLocalizations.cloudPulling,
      );
      if (result == null) {
        IToast.show(appLocalizations.cloudPullFailed);
      }
      return result;
    } catch (error, stackTrace) {
      ILogger.error(
          "Failed to list cloud backups from $logName", error, stackTrace);
      IToast.show(appLocalizations.cloudPullFailed);
      return null;
    }
  }

  static Future<void> downloadAndImport({
    required BuildContext context,
    required Future<Uint8List?> Function(
      void Function(int current, int total) onProgress,
    ) action,
    required String logName,
  }) async {
    final dialog = showProgressDialog(
      appLocalizations.cloudPulling,
      showProgress: true,
    );
    try {
      final data = await action((current, total) {
        if (total > 0) {
          dialog.updateProgress(progress: current / total);
        }
      });
      if (!context.mounted) {
        dialog.dismiss();
        return;
      }
      await ImportTokenUtil.importFromCloud(context, data, dialog);
    } catch (error, stackTrace) {
      ILogger.error(
          "Failed to download cloud backup from $logName", error, stackTrace);
      dialog.dismiss();
      IToast.show(appLocalizations.cloudPullFailed);
    }
  }
}
