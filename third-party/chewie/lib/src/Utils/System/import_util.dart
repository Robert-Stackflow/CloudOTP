import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:awesome_chewie/src/Widgets/Dialog/custom_dialog.dart';
import 'package:awesome_chewie/src/Utils/ilogger.dart';
import 'package:awesome_chewie/src/Utils/itoast.dart';
import 'file_util.dart';

class ImportUtil {
  static Future<String?> import({
    required String title,
    List<String> allowedExtensions = const ['json'],
  }) async {
    FilePickerResult? result = await FileUtil.pickFiles(
      dialogTitle: title,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      lockParentWindow: true,
    );
    if (result != null) {
      return importFromFile(result.files.single.path!);
    }
    return null;
  }

  static Future<String?> importFromFile(
    String filePath, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: "导入中");
    }
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        IToast.showTop("文件不存在");
        return null;
      } else {
        String content = file.readAsStringSync(encoding: utf8);
        return content;
      }
    } catch (e, t) {
      ILogger.error("Failed to import uri file from $filePath", e, t);
      IToast.showTop("导入失败");
      return null;
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
  }
}
