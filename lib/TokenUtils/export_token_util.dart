import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/Backup/backup.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_v1.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';

import '../Models/category.dart';
import '../Utils/itoast.dart';
import '../Widgets/Dialog/custom_dialog.dart';
import '../generated/l10n.dart';

class ExportTokenUtil {
  static exportUriFile(
    String filePath, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.exporting);
    }
    List<OtpToken> tokens = await TokenDao.listTokens();
    List<String> uris =
        tokens.map((e) => OtpTokenParser.toUri(e).toString()).toList();
    String content = uris.join("\n");
    File file = File(filePath);
    file.writeAsStringSync(content);
    if (showLoading) {
      CustomLoadingDialog.dismissLoading();
    }
    IToast.showTop(S.current.exportSuccess);
  }

  Future<File> createCachedFileFromEncryptString(
      String text, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    return file.writeAsString(text);
  }

  String getEncryptedData(String password, List<Map<String, dynamic>> tokens) {
    final json = jsonEncode(tokens);
    final key = encrypt.Key.fromUtf8(password.padRight(32, ' '));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(json, iv: iv);
    return encrypted.base64;
  }

  static exportEncryptFile(
    String filePath,
    String password, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.exporting);
    }
    List<OtpToken> tokens = await TokenDao.listTokens();
    List<TokenCategory> categories = await CategoryDao.listCategories();
    Backup backup = Backup(tokens: tokens, categories: categories);
    BackupEncryptionV1 backupEncryption = BackupEncryptionV1();
    Uint8List encryptedData =
        await backupEncryption.encrypt(backup, password);
    File file = File(filePath);
    file.writeAsBytesSync(encryptedData);
    if (showLoading) {
      CustomLoadingDialog.dismissLoading();
    }
    IToast.showTop(S.current.exportSuccess);
  }
}
