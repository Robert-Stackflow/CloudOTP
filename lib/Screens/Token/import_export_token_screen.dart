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

import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/asset_util.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/Backups/local_backups_bottom_sheet.dart';
import 'package:cloudotp/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:cloudotp/Widgets/BottomSheet/input_bottom_sheet.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../TokenUtils/import_token_util.dart';
import '../../Utils/file_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Dialog/dialog_builder.dart';
import '../../Widgets/Item/input_item.dart';
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
  String appName = "CloudOTP";

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) => setState(() {
          appName = info.appName;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ItemBuilder.buildAppBar(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: ResponsiveUtil.isLandscape()
            ? Icons.close_rounded
            : Icons.arrow_back_rounded,
        onLeadingTap: () {
          if (ResponsiveUtil.isLandscape()) {
            dialogNavigatorState?.popPage();
          } else {
            Navigator.pop(context);
          }
        },
        title: Text(
          S.current.exportImport,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.apply(fontWeightDelta: 2),
        ),
        actions: ResponsiveUtil.isLandscape()
            ? []
            : [
                ItemBuilder.buildBlankIconButton(context),
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
        ItemBuilder.buildCaptionItem(context: context, title: S.current.import),
        ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.importEncryptFile,
          description: S.current.importEncryptFileHint(appName),
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
        ItemBuilder.buildEntryItem(
          context: context,
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
        // ItemBuilder.buildEntryItem(
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
        ItemBuilder.buildEntryItem(
          context: context,
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
        ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.importUriFromClipBoard,
          bottomRadius: true,
          description: S.current.importUriFromClipBoardHint,
          onTap: () async {
            String? content = await Utils.getClipboardData();
            ImportTokenUtil.importText(
              content ?? "",
              emptyTip: S.current.clipboardEmpty,
              noTokenToast: S.current.clipBoardDoesNotContainToken,
            );
          },
        ),
        const SizedBox(height: 10),
        ItemBuilder.buildCaptionItem(context: context, title: S.current.export),
        ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.exportEncryptFile,
          description: S.current.exportEncryptFileHint(appName),
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
                if (await HiveUtil.canImportOrExportUseBackupPassword()) {
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
                      tailingType: InputItemTailingType.password,
                      inputFormatters: [
                        RegexInputFormatter.onlyNumberAndLetter,
                      ],
                      validator: (value) {
                        if (value.isEmpty) {
                          return S.current.encryptDatabasePasswordCannotBeEmpty;
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
              if (await HiveUtil.canImportOrExportUseBackupPassword()) {
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
                    tailingType: InputItemTailingType.password,
                    inputFormatters: [
                      RegexInputFormatter.onlyNumberAndLetter,
                    ],
                    validator: (value) {
                      if (value.isEmpty) {
                        return S.current.encryptDatabasePasswordCannotBeEmpty;
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
        ItemBuilder.buildEntryItem(
          context: context,
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
        ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.exportQrcode,
          description: S.current.exportQrcodeHint,
          onTap: () async {
            List<String>? qrCodes = await ExportTokenUtil.exportToQrcodes();
            if (qrCodes != null && qrCodes.isNotEmpty) {
              DialogBuilder.showQrcodesDialog(
                context,
                asset: 'assets/logo.png',
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
        ItemBuilder.buildEntryItem(
          context: context,
          bottomRadius: true,
          title: S.current.exportGoogleAuthenticatorQrcode,
          description: S.current.exportGoogleAuthenticatorQrcodeHint,
          onTap: () async {
            List<dynamic>? res =
                await ExportTokenUtil.exportToGoogleAuthentcatorQrcodes();
            if (res != null) {
              List<String>? qrCodes = res[0];
              int passCount = res[1];
              if (qrCodes != null && qrCodes.isNotEmpty) {
                DialogBuilder.showQrcodesDialog(
                  context,
                  asset: AssetUtil.icGoogleauthenticator,
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
        const SizedBox(height: 20),
      ],
    );
  }
}
