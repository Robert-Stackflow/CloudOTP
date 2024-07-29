import 'dart:io';

import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';
import 'package:flutter/cupertino.dart';

import '../Utils/utils.dart';
import '../generated/l10n.dart';

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
  static parseData(List<String> rawUris,
      {bool autoPopup = true, BuildContext? context}) async {
    List<String> validUris = [];
    for (String line in rawUris) {
      Uri? uri = Uri.tryParse(line);
      if (uri != null &&
          uri.scheme.isNotEmpty &&
          uri.scheme == "otpauth" &&
          uri.authority.isNotEmpty) {
        validUris.add(line);
      }
    }
    if (validUris.isNotEmpty) {
      await ImportTokenUtil.importText(validUris.join("\n"));
      if (autoPopup && context != null && context.mounted) {
        Navigator.pop(context);
      }
    } else {
      IToast.showTop(S.current.noQrCodeToken);
    }
  }

  static importUriFile(
    String filePath, {
    bool showLoading = true,
  }) async {
    File file = File(filePath);
    if (!file.existsSync()) {
      IToast.showTop(S.current.fileNotExist);
      return;
    } else {
      String content = file.readAsStringSync();
      await importText(content,
          showLoading: showLoading, emptyTip: S.current.fileEmpty);
    }
  }

  static importEncryptFile(
    String filePath, {
    bool showLoading = true,
  }) async {
    File file = File(filePath);
    if (!file.existsSync()) {
      IToast.showTop(S.current.fileNotExist);
      return;
    } else {
      String content = file.readAsStringSync();
      await importText(content, showLoading: showLoading);
    }
  }

  static importText(
    String content, {
    String emptyTip = "",
    bool showLoading = true,
  }) async {
    if (Utils.isEmpty(content) && Utils.isNotEmpty(emptyTip)) {
      IToast.showTop(emptyTip);
      return;
    }
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.importing);
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
    IToast.showTop(S.current
        .importResultTip(analysis.parseSuccess, analysis.importSuccess));
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
