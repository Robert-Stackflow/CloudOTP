import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class ExportUtil {
  static export(
    String data,
    String fileName, {
    required String title,
    List<String> allowedExtensions = const ['json'],
    bool showLoading = true,
  }) async {
    if (ResponsiveUtil.isDesktop()) {
      String? result = await FileUtil.saveFile(
        dialogTitle: title,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        lockParentWindow: true,
      );
      if (result != null) {
        exportToDesktop(data, result, showLoading: showLoading);
      }
    } else {
      exportToMobile(
        data,
        fileName,
        showLoading: showLoading,
        allowedExtensions: allowedExtensions,
        title: title,
      );
    }
  }

  static exportToDesktop(
    String data,
    String filePath, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: chewieLocalizations.exporting);
    }
    await compute((_) async {
      File file = File(filePath);
      file.writeAsStringSync(data);
    }, null);
    if (showLoading) {
      CustomLoadingDialog.dismissLoading();
    }
    IToast.showTop(chewieLocalizations.exportSuccess);
  }

  static exportToMobile(
    String data,
    String fileName, {
    bool showLoading = true,
    required String title,
    List<String> allowedExtensions = const ['json'],
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: chewieLocalizations.exporting);
    }
    String? filePath = await FileUtil.saveFile(
      dialogTitle: title,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      bytes: utf8.encode(data),
    );
    if (showLoading) {
      CustomLoadingDialog.dismissLoading();
    }
    if (filePath != null) {
      IToast.showTop(chewieLocalizations.exportSuccess);
    }
  }
}
