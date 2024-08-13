import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:cloudotp/Widgets/BottomSheet/input_bottom_sheet.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../TokenUtils/import_token_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
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
        center: true,
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

  _showImportPasswordDialog(
    Function(TextEditingController, InputStateController, String)?
        onValidConfirm,
  ) {
    TextEditingController controller = TextEditingController();
    InputStateController stateController = InputStateController(
      validate: (value) {
        if (value.isEmpty) {
          return Future.value(S.current.autoBackupPasswordCannotBeEmpty);
        }
        return Future.value(null);
      },
    );
    BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      (context) => InputBottomSheet(
        stateController: stateController,
        title: S.current.inputImportPasswordTitle,
        message: S.current.inputImportPasswordTip,
        hint: S.current.inputImportPasswordHint,
        inputFormatters: [
          RegexInputFormatter.onlyNumberAndLetter,
        ],
        tailingType: InputItemTailingType.password,
        preventPop: true,
        onValidConfirm: (password) async {
          onValidConfirm?.call(controller, stateController, password);
        },
      ),
    );
  }

  _buildBody() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      children: [
        ItemBuilder.buildCaptionItem(context: context, title: S.current.import),
        ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.importEncryptFile,
          description: S.current.importEncryptFileHint(appName),
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              dialogTitle: S.current.importEncryptFileTitle,
              type: FileType.custom,
              allowedExtensions: ['bin'],
              lockParentWindow: true,
            );
            if (result != null) {
              operation() {
                _showImportPasswordDialog(
                    (controller, stateController, password) async {
                  bool success = await ImportTokenUtil.importEncryptFile(
                      result.files.single.path!, password);
                  if (success) {
                    stateController.pop?.call();
                  } else {
                    stateController
                        .setError(S.current.encryptDatabasePasswordWrong);
                  }
                });
              }

              if (await HiveUtil.canImportOrExportUseBackupPassword()) {
                bool success = await ImportTokenUtil.importEncryptFile(
                    result.files.single.path!,
                    await ConfigDao.getBackupPassword());
                if (!success) operation();
              } else {
                operation();
              }
            }
          },
        ),
        // ItemBuilder.buildEntryItem(
        //   context: context,
        //   title: S.current.importOldEncryptFile,
        //   description: S.current.importOldEncryptFileHint(appName),
        //   onTap: () async {
        //     FilePickerResult? result = await FilePicker.platform.pickFiles(
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
            FilePickerResult? result = await FilePicker.platform.pickFiles(
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
              String? result = await FilePicker.platform.saveFile(
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
                  InputStateController stateController = InputStateController(
                    validate: (value) {
                      if (value.isEmpty) {
                        return Future.value(
                            S.current.encryptDatabasePasswordCannotBeEmpty);
                      }
                      return Future.value(null);
                    },
                  );
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    responsive: true,
                    (context) => InputBottomSheet(
                      title: S.current.setExportPasswordTitle,
                      message: S.current.setExportPasswordTip,
                      hint: S.current.setExportPasswordHint,
                      tailingType: InputItemTailingType.password,
                      inputFormatters: [
                        RegexInputFormatter.onlyNumberAndLetter,
                      ],
                      stateController: stateController,
                      onValidConfirm: (password) {
                        ExportTokenUtil.exportEncryptFile(result, password);
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
                InputStateController stateController = InputStateController(
                  validate: (value) {
                    if (value.isEmpty) {
                      return Future.value(
                          S.current.encryptDatabasePasswordCannotBeEmpty);
                    }
                    return Future.value(null);
                  },
                );
                BottomSheetBuilder.showBottomSheet(
                  context,
                  responsive: true,
                  (context) => InputBottomSheet(
                    title: S.current.setExportPasswordTitle,
                    message: S.current.setExportPasswordTip,
                    hint: S.current.setExportPasswordHint,
                    tailingType: InputItemTailingType.password,
                    inputFormatters: [
                      RegexInputFormatter.onlyNumberAndLetter,
                    ],
                    stateController: stateController,
                    onValidConfirm: (password) async {
                      ExportTokenUtil.exportEncryptToMobileDirectory(
                          password: password);
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
          bottomRadius: true,
          description: S.current.exportUriFileHint,
          onTap: () async {
            DialogBuilder.showConfirmDialog(
              context,
              title: S.current.exportUriClearWarningTitle,
              message: S.current.exportUriClearWarningTip,
              onTapConfirm: () async {
                if (ResponsiveUtil.isDesktop()) {
                  String? result = await FilePicker.platform.saveFile(
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
      ],
    );
  }
}
