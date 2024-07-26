import 'dart:io';

import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';

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
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: "导入中...");
    }
    ImportAnalysis analysis = ImportAnalysis();
    File file = File(filePath);
    String content = file.readAsStringSync();
    List<String> lines = content.split("\n");
    List<OtpToken> tokens = [];
    for (String line in lines) {
      OtpToken? token = OtpTokenParser.createFromUri(Uri.parse(line));
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
    }
    return newTokenList.length;
  }
}
