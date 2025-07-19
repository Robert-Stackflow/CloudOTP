/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../Models/opt_token.dart';
import '../../l10n/l10n.dart';
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
          showProgressDialog(appLocalizations.importing, showProgress: false);
    }
    try {
      File file = File(path);
      if (!file.existsSync()) {
        IToast.showTop(appLocalizations.fileNotExist);
      } else if (FileUtil.getFileExtension(path) == 'txt') {
        var content = file.readAsStringSync();
        List<OtpToken> tokens =
            await ImportTokenUtil.importText(content, showToast: false);
        await import(tokens);
      } else if (FileUtil.getFileExtension(path) == 'zip') {
        IToast.showTop(appLocalizations.importFromWinauthNotSupportZip);
        return;
        var bytes = file.readAsBytesSync();
        if (showLoading) dialog.dismiss();
        InputValidateAsyncController validateAsyncController =
            InputValidateAsyncController(
          listen: false,
          validator: (text) async {
            if (text.isEmpty) {
              return appLocalizations.autoBackupPasswordCannotBeEmpty;
            }
            if (showLoading) {
              dialog.show(msg: appLocalizations.importing, showProgress: false);
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
              return appLocalizations.noFileInZip;
            } else {
              if (showLoading) {
                dialog.dismiss();
              }
              return appLocalizations.invalidPasswordOrDataCorrupted;
            }
          },
          controller: TextEditingController(),
        );
        BottomSheetBuilder.showBottomSheet(
          chewieProvider.rootContext,
          responsive: true,
          (context) => InputBottomSheet(
            validator: (value) {
              if (value.isEmpty) {
                return appLocalizations.autoBackupPasswordCannotBeEmpty;
              }
              return null;
            },
            checkSyncValidator: false,
            validateAsyncController: validateAsyncController,
            title: appLocalizations.inputImportPasswordTitle,
            message: appLocalizations.inputImportPasswordTip,
            hint: appLocalizations.inputImportPasswordHint,
            inputFormatters: [
              RegexInputFormatter.onlyNumberAndLetterAndSymbol,
            ],
            tailingConfig: InputItemLeadingTailingConfig(
              type: InputItemLeadingTailingType.password,
            ),
            onValidConfirm: (password) async {},
          ),
        );
      }
    } catch (e, t) {
      ILogger.error("Failed to import from Winauth", e, t);
      IToast.showTop(appLocalizations.importFailed);
    } finally {
      if (showLoading) {
        dialog.dismiss();
      }
    }
  }
}
