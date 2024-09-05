import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/file_util.dart';
import 'package:cloudotp/Widgets/Dialog/progress_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../Models/opt_token.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';
import '../import_token_util.dart';

class WinauthTokenImporter implements BaseTokenImporter {
  static dynamic decrypt(Uint8List data, String password) {
    final archive = ZipDecoder().decodeBytes(data, password: password);
    ArchiveFile? fileEntry;
    try {
      archive.files.firstWhere((file) => file.isFile);
    } catch (e) {
      fileEntry = null;
    }

    if (fileEntry == null) {
      return [
        DecryptResult.noFileInZip,
        null,
      ];
    }

    final outputData = BytesBuilder();

    try {
      // If password is required and provided
      if (password.isNotEmpty) {
        fileEntry = _decryptZipFile(fileEntry, password);
      }
      outputData.add(fileEntry.content as List<int>);
    } catch (e) {
      return [
        DecryptResult.invalidPasswordOrDataCorrupted,
        null,
      ];
    }

    return outputData.toBytes();
  }

  static ArchiveFile _decryptZipFile(ArchiveFile fileEntry, String password) {
    // Perform decryption logic here, if needed, depending on zip file encryption.
    // Use any decryption algorithms supported by the 'archive' or another package.
    return fileEntry;
  }

  Future<void> import(List<OtpToken> toImportTokens) async {
    await BaseTokenImporter.importResult(
        ImporterResult(toImportTokens, [], []));
  }

  @override
  Future<void> importFromPath(
    String path, {
    bool showLoading = true,
  }) async {
    late ProgressDialog dialog;
    if (showLoading) {
      dialog =
          showProgressDialog(msg: S.current.importing, showProgress: false);
    }
    try {
      File file = File(path);
      if (!file.existsSync()) {
        IToast.showTop(S.current.fileNotExist);
      } else if (FileUtil.getFileExtension(path) == 'txt') {
        var content = file.readAsStringSync();
        List<OtpToken> tokens =
            await ImportTokenUtil.importText(content, showToast: false);
        await import(tokens);
      } else if (FileUtil.getFileExtension(path) == 'zip') {
        IToast.showTop(S.current.importFromWinauthNotSupportZip);
        return;
        var bytes = file.readAsBytesSync();
        if (showLoading) dialog.dismiss();
        InputValidateAsyncController validateAsyncController =
            InputValidateAsyncController(
          listen: false,
          validator: (text) async {
            if (text.isEmpty) {
              return S.current.autoBackupPasswordCannotBeEmpty;
            }
            if (showLoading) {
              dialog.show(msg: S.current.importing, showProgress: false);
            }
            var res = await compute(
              (receiveMessage) {
                return decrypt(
                    Uint8List.fromList(receiveMessage["data"] as List<int>),
                    receiveMessage["password"] as String);
              },
              {
                'data': bytes.toList(),
                'password': text,
              },
            );
            if (res[0] == DecryptResult.success) {
              List<OtpToken> tokens =
                  await ImportTokenUtil.importText(res[1], showToast: false);
              await import(tokens);
              if (showLoading) {
                dialog.dismiss();
              }
              return null;
            } else if (res[0] == DecryptResult.noFileInZip) {
              if (showLoading) {
                dialog.dismiss();
              }
              return S.current.noFileInZip;
            } else {
              if (showLoading) {
                dialog.dismiss();
              }
              return S.current.invalidPasswordOrDataCorrupted;
            }
          },
          controller: TextEditingController(),
        );
        BottomSheetBuilder.showBottomSheet(
          rootContext,
          responsive: true,
          useWideLandscape: true,
          (context) => InputBottomSheet(
            validator: (value) {
              if (value.isEmpty) {
                return S.current.autoBackupPasswordCannotBeEmpty;
              }
              return null;
            },
            checkSyncValidator: false,
            validateAsyncController: validateAsyncController,
            title: S.current.inputImportPasswordTitle,
            message: S.current.inputImportPasswordTip,
            hint: S.current.inputImportPasswordHint,
            inputFormatters: [
              RegexInputFormatter.onlyNumberAndLetterAndSymbol,
            ],
            tailingType: InputItemTailingType.password,
            onValidConfirm: (password) async {},
          ),
        );
      }
    } catch (e, t) {
      ILogger.error("Failed to import from Winauth", e, t);
      IToast.showTop(S.current.importFailed);
    } finally {
      if (showLoading) {
        dialog.dismiss();
      }
    }
  }
}
