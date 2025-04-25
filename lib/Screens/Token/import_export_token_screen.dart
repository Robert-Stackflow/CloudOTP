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
import '../../generated/l10n.dart';

class ImportExportTokenScreen extends StatefulWidget {
  const ImportExportTokenScreen({
    super.key,
  });

  static const String routeName = "/token/import";

  @override
  State<ImportExportTokenScreen> createState() =>
      _ImportExportTokenScreenState();
}

class _ImportExportTokenScreenState extends State<ImportExportTokenScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ResponsiveAppBar(
        title: S.current.exportImport,
        showBack: !ResponsiveUtil.isLandscape(),
        titleLeftMargin: ResponsiveUtil.isLandscape() ? 15 : 5,
        actions: ResponsiveUtil.isLandscape()
            ? []
            : [
                const BlankIconButton(),
                const SizedBox(width: 5),
              ],
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
          title: S.current.import,
          children: [
            EntryItem(
              title: S.current.importEncryptFile,
              description:
                  S.current.importEncryptFileHint(ResponsiveUtil.appName),
              onTap: () async {
                FilePickerResult? result = await FileUtil.pickFiles(
                  dialogTitle: S.current.importEncryptFileTitle,
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
              title: S.current.importFromLocalBackup,
              description: S.current.importFromLocalBackupHint,
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
            //   title: S.current.importOldEncryptFile,
            //   description: S.current.importOldEncryptFileHint(appName),
            //   onTap: () async {
            //     FilePickerResult? result = await FileUtil.pickFiles(
            //       dialogTitle: S.current.importOldEncryptFileTitle,
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
            //                 .setError(S.current.encryptDatabasePasswordWrong);
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
              title: S.current.importUriFile,
              description: S.current.importUriFileHint,
              onTap: () async {
                FilePickerResult? result = await FileUtil.pickFiles(
                  dialogTitle: S.current.importUriFileTitle,
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
              title: S.current.importUriFromClipBoard,
              description: S.current.importUriFromClipBoardHint,
              onTap: () async {
                String? content = await ChewieUtils.getClipboardData();
                ImportTokenUtil.importText(
                  content ?? "",
                  emptyTip: S.current.clipboardEmpty,
                  noTokenToast: S.current.clipBoardDoesNotContainToken,
                );
              },
            ),
          ],
        ),
        CaptionItem(
          title: S.current.export,
          children: [
            EntryItem(
              title: S.current.exportEncryptFile,
              description:
                  S.current.exportEncryptFileHint(ResponsiveUtil.appName),
              onTap: () async {
                if (ResponsiveUtil.isDesktop()) {
                  String? result = await FileUtil.saveFile(
                    dialogTitle: S.current.exportEncryptFileTitle,
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
                        useWideLandscape: true,
                        (context) => InputBottomSheet(
                          title: S.current.setExportPasswordTitle,
                          message: S.current.setExportPasswordTip,
                          hint: S.current.setExportPasswordHint,
                          tailingConfig: InputItemLeadingTailingConfig(
                            type: InputItemLeadingTailingType.password,
                          ),
                          inputFormatters: [
                            RegexInputFormatter.onlyNumberAndLetterAndSymbol,
                          ],
                          validator: (value) {
                            if (value.isEmpty) {
                              return S
                                  .current.encryptDatabasePasswordCannotBeEmpty;
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
                      useWideLandscape: true,
                      (context) => InputBottomSheet(
                        title: S.current.setExportPasswordTitle,
                        message: S.current.setExportPasswordTip,
                        hint: S.current.setExportPasswordHint,
                        tailingConfig: InputItemLeadingTailingConfig(
                          type: InputItemLeadingTailingType.password,
                        ),
                        inputFormatters: [
                          RegexInputFormatter.onlyNumberAndLetterAndSymbol,
                        ],
                        validator: (value) {
                          if (value.isEmpty) {
                            return S
                                .current.encryptDatabasePasswordCannotBeEmpty;
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
              title: S.current.exportUriFile,
              description: S.current.exportUriFileHint,
              onTap: () async {
                DialogBuilder.showConfirmDialog(
                  context,
                  title: S.current.exportUriClearWarningTitle,
                  message: S.current.exportUriClearWarningTip,
                  onTapConfirm: () async {
                    if (ResponsiveUtil.isDesktop()) {
                      String? result = await FileUtil.saveFile(
                        dialogTitle: S.current.exportUriFileTitle,
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
              title: S.current.exportQrcode,
              description: S.current.exportQrcodeHint,
              onTap: () async {
                List<String>? qrCodes = await ExportTokenUtil.exportToQrcodes();
                if (qrCodes != null && qrCodes.isNotEmpty) {
                  CloudOTPItemBuilder.showQrcodesDialog(
                    context,
                    asset: AssetFiles.logo,
                    title: S.current.exportQrcode,
                    message: S.current.exportQrcodeMessage,
                    qrcodes: qrCodes,
                  );
                } else if (qrCodes != null && qrCodes.isEmpty) {
                  IToast.showTop(S.current.exportQrcodeNoData);
                } else {
                  IToast.showTop(S.current.exportFailed);
                }
              },
            ),
            // const SizedBox(height: 10),
            // ItemBuilder.buildCaptionItem(
            //     context: context, title: S.current.exportToThirdParty),
            EntryItem(
              title: S.current.exportGoogleAuthenticatorQrcode,
              description: S.current.exportGoogleAuthenticatorQrcodeHint,
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
                      title: S.current.exportGoogleAuthenticatorQrcode,
                      message: S.current.exportGoogleAuthenticatorQrcodeMessage,
                      qrcodes: qrCodes,
                    );
                  }
                  List<String> toasts = [];
                  if (passCount > 0) {
                    toasts.add(S.current
                        .exportGoogleAuthenticatorNoCompatibleCount(passCount));
                  }
                  if (qrCodes != null && qrCodes.isEmpty) {
                    toasts.add(S.current.exportGoogleAuthenticatorNoToken);
                  }
                  if (toasts.isNotEmpty) {
                    IToast.showTop(toasts.join("; "));
                  }
                } else {
                  IToast.showTop(S.current.exportFailed);
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
