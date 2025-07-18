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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/asset_util.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/Backups/local_backups_bottom_sheet.dart';
import 'package:cloudotp/Widgets/cloudotp/cloudotp_item_builder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../TokenUtils/import_token_util.dart';
import '../../l10n/l10n.dart';

class ImportExportTokenScreen extends StatefulWidget {
  const ImportExportTokenScreen({
    super.key,
  });

  static const String routeName = "/token/import";

  @override
  State<ImportExportTokenScreen> createState() =>
      _ImportExportTokenScreenState();
}

class _ImportExportTokenScreenState
    extends BaseDynamicState<ImportExportTokenScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ResponsiveAppBar(
        title: appLocalizations.exportImport,
        showBack: !ResponsiveUtil.isLandscapeLayout(),
        titleLeftMargin: ResponsiveUtil.isLandscapeLayout() ? 15 : 5,
        actions:
            ResponsiveUtil.isLandscapeLayout() ? [] : [const BlankIconButton()],
      ),
      body: EasyRefresh(
        child: _buildBody(),
      ),
    );
  }

  _buildBody() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: [
        CaptionItem(
          title: appLocalizations.import,
          children: [
            EntryItem(
              title: appLocalizations.importEncryptFile,
              description: appLocalizations
                  .importEncryptFileHint(ResponsiveUtil.appName),
              onTap: () async {
                FilePickerResult? result = await FileUtil.pickFiles(
                  dialogTitle: appLocalizations.importEncryptFileTitle,
                  type: FileType.custom,
                  allowedExtensions: ['bin'],
                  lockParentWindow: true,
                );
                if (result != null) {
                  ImportTokenUtil.importEncryptFileWrapper(
                      context, result.files.single.path!);
                }
              },
            ),
            EntryItem(
              title: appLocalizations.importFromLocalBackup,
              description: appLocalizations.importFromLocalBackupHint,
              onTap: () async {
                BottomSheetBuilder.showBottomSheet(
                  context,
                  responsive: true,
                  (dialogContext) => LocalBackupsBottomSheet(
                    onSelected: (selectedFile) async {
                      ImportTokenUtil.importEncryptFileWrapper(
                          context, selectedFile.path);
                    },
                  ),
                );
              },
            ),
            // EntryItem(
            //   context: context,
            //   title: appLocalizations.importOldEncryptFile,
            //   description: appLocalizations.importOldEncryptFileHint(appName),
            //   onTap: () async {
            //     FilePickerResult? result = await FileUtil.pickFiles(
            //       dialogTitle: appLocalizations.importOldEncryptFileTitle,
            //       type: FileType.any,
            //       lockParentWindow: true,
            //     );
            //     if (result != null) {
            //       operation() {
            //         _showImportPasswordDialog(
            //             (controller, stateController, password) async {
            //           bool success = await ImportTokenUtil.importOldEncryptFile(
            //               result.files.single.path!, password);
            //           if (success) {
            //             stateController.pop?.call();
            //           } else {
            //             stateController
            //                 .setError(appLocalizations.encryptDatabasePasswordWrong);
            //           }
            //         });
            //       }
            //
            //       if (await HiveUtil.canImportOrExportUseBackupPassword()) {
            //         bool success = await ImportTokenUtil.importOldEncryptFile(
            //             result.files.single.path!,
            //             await ConfigDao.getBackupPassword());
            //         if (!success) operation();
            //       } else {
            //         operation();
            //       }
            //     }
            //   },
            // ),
            EntryItem(
              title: appLocalizations.importUriFile,
              description: appLocalizations.importUriFileHint,
              onTap: () async {
                FilePickerResult? result = await FileUtil.pickFiles(
                  dialogTitle: appLocalizations.importUriFileTitle,
                  type: FileType.custom,
                  allowedExtensions: ['txt'],
                  lockParentWindow: true,
                );
                if (result != null) {
                  ImportTokenUtil.importUriFile(result.files.single.path!);
                }
              },
            ),
            EntryItem(
              title: appLocalizations.importUriFromClipBoard,
              description: appLocalizations.importUriFromClipBoardHint,
              onTap: () async {
                String? content = await ChewieUtils.getClipboardData();
                ImportTokenUtil.importText(
                  content ?? "",
                  emptyTip: appLocalizations.clipboardEmpty,
                  noTokenToast: appLocalizations.clipBoardDoesNotContainToken,
                );
              },
            ),
          ],
        ),
        CaptionItem(
          title: appLocalizations.export,
          children: [
            EntryItem(
              title: appLocalizations.exportEncryptFile,
              description: appLocalizations
                  .exportEncryptFileHint(ResponsiveUtil.appName),
              onTap: () async {
                if (ResponsiveUtil.isDesktop()) {
                  String? result = await FileUtil.saveFile(
                    dialogTitle: appLocalizations.exportEncryptFileTitle,
                    fileName: ExportTokenUtil.getExportFileName("bin"),
                    type: FileType.custom,
                    allowedExtensions: ['bin'],
                    lockParentWindow: true,
                  );
                  if (result != null) {
                    if (await CloudOTPHiveUtil
                        .canImportOrExportUseBackupPassword()) {
                      ExportTokenUtil.exportEncryptFile(
                          result, await ConfigDao.getBackupPassword());
                    } else {
                      BottomSheetBuilder.showBottomSheet(
                        context,
                        responsive: true,
                        (context) => InputBottomSheet(
                          title: appLocalizations.setExportPasswordTitle,
                          message: appLocalizations.setExportPasswordTip,
                          hint: appLocalizations.setExportPasswordHint,
                          tailingConfig: InputItemLeadingTailingConfig(
                            type: InputItemLeadingTailingType.password,
                          ),
                          inputFormatters: [
                            RegexInputFormatter.onlyNumberAndLetterAndSymbol,
                          ],
                          validator: (value) {
                            if (value.isEmpty) {
                              return appLocalizations
                                  .encryptDatabasePasswordCannotBeEmpty;
                            }
                            return null;
                          },
                          onValidConfirm: (password) async {
                            ExportTokenUtil.exportEncryptFile(result, password);
                            return null;
                          },
                        ),
                      );
                    }
                  }
                } else {
                  if (await CloudOTPHiveUtil
                      .canImportOrExportUseBackupPassword()) {
                    ExportTokenUtil.exportEncryptToMobileDirectory(
                        password: await ConfigDao.getBackupPassword());
                  } else {
                    BottomSheetBuilder.showBottomSheet(
                      context,
                      responsive: true,
                      (context) => InputBottomSheet(
                        title: appLocalizations.setExportPasswordTitle,
                        message: appLocalizations.setExportPasswordTip,
                        hint: appLocalizations.setExportPasswordHint,
                        tailingConfig: InputItemLeadingTailingConfig(
                          type: InputItemLeadingTailingType.password,
                        ),
                        inputFormatters: [
                          RegexInputFormatter.onlyNumberAndLetterAndSymbol,
                        ],
                        validator: (value) {
                          if (value.isEmpty) {
                            return appLocalizations
                                .encryptDatabasePasswordCannotBeEmpty;
                          }
                          return null;
                        },
                        onValidConfirm: (password) async {
                          ExportTokenUtil.exportEncryptToMobileDirectory(
                              password: password);
                          return null;
                        },
                      ),
                    );
                  }
                }
              },
            ),
            EntryItem(
              title: appLocalizations.exportUriFile,
              description: appLocalizations.exportUriFileHint,
              onTap: () async {
                DialogBuilder.showConfirmDialog(
                  context,
                  title: appLocalizations.exportUriClearWarningTitle,
                  message: appLocalizations.exportUriClearWarningTip,
                  onTapConfirm: () async {
                    if (ResponsiveUtil.isDesktop()) {
                      String? result = await FileUtil.saveFile(
                        dialogTitle: appLocalizations.exportUriFileTitle,
                        fileName: ExportTokenUtil.getExportFileName("txt"),
                        type: FileType.custom,
                        allowedExtensions: ['txt'],
                        lockParentWindow: true,
                      );
                      if (result != null) {
                        ExportTokenUtil.exportUriFile(result);
                      }
                    } else {
                      ExportTokenUtil.exportUriToMobileDirectory();
                    }
                  },
                  onTapCancel: () {},
                );
              },
            ),
            EntryItem(
              title: appLocalizations.exportQrcode,
              description: appLocalizations.exportQrcodeHint,
              onTap: () async {
                List<String>? qrCodes = await ExportTokenUtil.exportToQrcodes();
                if (qrCodes != null && qrCodes.isNotEmpty) {
                  CloudOTPItemBuilder.showQrcodesDialog(
                    context,
                    asset: AssetFiles.logo,
                    title: appLocalizations.exportQrcode,
                    message: appLocalizations.exportQrcodeMessage,
                    qrcodes: qrCodes,
                  );
                } else if (qrCodes != null && qrCodes.isEmpty) {
                  IToast.showTop(appLocalizations.exportQrcodeNoData);
                } else {
                  IToast.showTop(appLocalizations.exportFailed);
                }
              },
            ),
            // const SizedBox(height: 10),
            // ItemBuilder.buildCaptionItem(
            //     context: context, title: appLocalizations.exportToThirdParty),
            EntryItem(
              title: appLocalizations.exportGoogleAuthenticatorQrcode,
              description: appLocalizations.exportGoogleAuthenticatorQrcodeHint,
              onTap: () async {
                List<dynamic>? res =
                    await ExportTokenUtil.exportToGoogleAuthentcatorQrcodes();
                if (res != null) {
                  List<String>? qrCodes = res[0];
                  int passCount = res[1];
                  if (qrCodes != null && qrCodes.isNotEmpty) {
                    CloudOTPItemBuilder.showQrcodesDialog(
                      context,
                      asset: AssetFiles.icGoogleauthenticator,
                      title: appLocalizations.exportGoogleAuthenticatorQrcode,
                      message: appLocalizations
                          .exportGoogleAuthenticatorQrcodeMessage,
                      qrcodes: qrCodes,
                    );
                  }
                  List<String> toasts = [];
                  if (passCount > 0) {
                    toasts.add(appLocalizations
                        .exportGoogleAuthenticatorNoCompatibleCount(passCount));
                  }
                  if (qrCodes != null && qrCodes.isEmpty) {
                    toasts
                        .add(appLocalizations.exportGoogleAuthenticatorNoToken);
                  }
                  if (toasts.isNotEmpty) {
                    IToast.showTop(toasts.join("; "));
                  }
                } else {
                  IToast.showTop(appLocalizations.exportFailed);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
