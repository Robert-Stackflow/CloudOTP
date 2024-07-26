import 'dart:io';

import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';

import '../Utils/utils.dart';

class ImportAnalysis {
  int parseFailed;

  int parseSuccess;

  int importSuccess;

  ImportAnalysis({
    this.parseFailed = 0,
    this.parseSuccess = 0,
    this.importSuccess = 0,
  });
}

class ImportTokenUtil {
  static importUriFile(
    String filePath, {
    bool showLoading = true,
  }) async {
    File file = File(filePath);
    if (!file.existsSync()) {
      IToast.showTop("文件不存在");
      return;
    } else {
      String content = file.readAsStringSync();
      await importText(content, showLoading: showLoading, emptyTip: "文件内容为空");
    }
  }

  static importEncryptFile(
    String filePath, {
    bool showLoading = true,
  }) async {
    File file = File(filePath);
    if (!file.existsSync()) {
      IToast.showTop("文件不存在");
      return;
    } else {
      String content = file.readAsStringSync();
      await importText(content, showLoading: showLoading);
    }
  }

  static importText(
    String content, {
    String emptyTip = "内容为空",
    bool showLoading = true,
  }) async {
    if (Utils.isEmpty(content)) {
      IToast.showTop(emptyTip);
      return;
    }
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: "导入中...");
    }
    ImportAnalysis analysis = ImportAnalysis();
    List<String> lines = content.split("\n");
    List<OtpToken> tokens = [];
    for (String line in lines) {
      OtpToken? token =
          OtpTokenParser.createFromUri(Uri.tryParse(line) ?? Uri());
      if (token != null) {
        tokens.add(token);
        analysis.parseSuccess++;
      } else {
        analysis.parseFailed++;
      }
    }
    analysis.importSuccess = await mergeTokens(tokens);
    if (showLoading) {
      CustomLoadingDialog.dismissLoading();
    }
    IToast.showTop(
        "解析成功${analysis.parseSuccess}个令牌，导入成功${analysis.importSuccess}个令牌");
  }

  static bool contain(OtpToken token, List<OtpToken> tokenList) {
    for (OtpToken otpToken in tokenList) {
      if (otpToken.issuer == token.issuer &&
          otpToken.account == token.account) {
        return true;
      }
    }
    return false;
  }

  static Future<int> mergeTokens(
    List<OtpToken> tokenList, {
    bool performInsert = true,
  }) async {
    List<OtpToken> already = await TokenDao.listTokens();
    List<OtpToken> newTokenList = [];
    for (OtpToken otpToken in tokenList) {
      if (!contain(otpToken, already) && !contain(otpToken, newTokenList)) {
        newTokenList.add(otpToken);
      }
    }
    if (performInsert) {
      await TokenDao.insertTokens(newTokenList);
      homeScreenState?.refresh();
    }
    return newTokenList.length;
  }
}
