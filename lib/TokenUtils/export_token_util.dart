import 'dart:io';

import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';

import '../Utils/itoast.dart';
import '../Widgets/Dialog/custom_dialog.dart';

class ExportTokenUtil{
  static exportUriFile(
      String filePath, {
        bool showLoading = true,
      }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: "导入中...");
    }
    List<OtpToken> tokens=await TokenDao.listTokens();
    List<String> uris=tokens.map((e)=>OtpTokenParser.toUri(e).toString()).toList();
    String content=uris.join("\n");
    File file = File(filePath);
    file.writeAsStringSync(content);
    IToast.showTop("导出成功");
  }
}