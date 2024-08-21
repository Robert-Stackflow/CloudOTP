import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Screens/Backup/cloud_service_screen.dart';
import 'package:cloudotp/Screens/Setting/backup_log_screen.dart';
import 'package:cloudotp/TokenUtils/Cloud/webdav_cloud_service.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/constant.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/input_item.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/Backups/local_backups_bottom_sheet.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class BackupSettingScreen extends StatefulWidget {
  const BackupSettingScreen({super.key, this.jumpToAutoBackupPassword = false});

  final bool jumpToAutoBackupPassword;

  static const String routeName = "/setting/backup";

  @override
  State<BackupSettingScreen> createState() => _BackupSettingScreenState();
}

extension GetOffset on Widget {
  Offset getOffset() {
    if (key == null || key is! GlobalKey) return Offset.zero;
    return ((key as GlobalKey).currentContext!.findRenderObject()! as RenderBox)
        .localToGlobal(Offset.zero);
  }
}

class _BackupSettingScreenState extends State<BackupSettingScreen>
    with TickerProviderStateMixin {
  bool _enableAutoBackup = HiveUtil.getBool(HiveUtil.enableAutoBackupKey);
  bool _enableLocalBackup = HiveUtil.getBool(HiveUtil.enableLocalBackupKey);
  bool _useBackupPasswordToExportImport =
      HiveUtil.getBool(HiveUtil.useBackupPasswordToExportImportKey);
  String _autoBackupPath = HiveUtil.getString(HiveUtil.backupPathKey) ?? "";
  String _autoBackupPassword = "";
  bool _enableCloudBackup = HiveUtil.getBool(HiveUtil.enableCloudBackupKey);
  CloudServiceConfig? _cloudServiceConfig;
  int _maxBackupsCount = HiveUtil.getMaxBackupsCount();
  final GlobalKey _setAutoBackupPasswordKey = GlobalKey();
  String validConfigs = "";

  @override
  void initState() {
    super.initState();
    ConfigDao.getConfig().then((config) {
      setState(() {
        _autoBackupPassword = config.backupPassword;
      });
    });
    loadWebDavConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.jumpToAutoBackupPassword) {
        scrollToSetAutoBackupPassword();
      }
    });
  }

  scrollToSetAutoBackupPassword() {
    if (_setAutoBackupPasswordKey.currentContext != null) {
      Scrollable.ensureVisible(
        _setAutoBackupPasswordKey.currentContext!,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ResponsiveUtil.isLandscape()
            ? ItemBuilder.buildSimpleAppBar(
                title: S.current.backupSetting,
                context: context,
                transparent: true,
              )
            : ItemBuilder.buildAppBar(
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: Icons.arrow_back_rounded,
                onLeadingTap: () {
                  Navigator.pop(context);
                },
                title: Text(
                  S.current.backupSetting,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.apply(fontWeightDelta: 2),
                ),
                center: true,
                actions: [
                  ItemBuilder.buildBlankIconButton(context),
                  const SizedBox(width: 5),
                ],
              ),
        body: EasyRefresh(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              ..._backupSettings(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  bool get canBackup => _autoBackupPassword.isNotEmpty;

  bool get canLocalBackup =>
      _autoBackupPath.isNotEmpty && _autoBackupPassword.isNotEmpty;

  bool get canCloudBackup => _autoBackupPassword.isNotEmpty;

  bool get canImmediateBackup =>
      canBackup &&
      ((canLocalBackup && _enableLocalBackup) ||
          (canCloudBackup && _enableCloudBackup));

  loadWebDavConfig() async {
    List<CloudServiceConfig> configs =
        await CloudServiceConfigDao.getValidConfigs();
    setState(() {
      validConfigs = configs.map((e) => e.type.label).join(", ");
    });
  }

  getBackupsCount() async {
    int currentLocalBackupsCount = await ExportTokenUtil.getBackupsCount();
    late int currentCloudBackupsCount;
    if (!_enableCloudBackup ||
        !validConfigs.isNotEmpty ||
        _cloudServiceConfig == null) {
      currentCloudBackupsCount = 0;
    } else {
      WebDavCloudService webDavCloudService =
          WebDavCloudService(_cloudServiceConfig!);
      try {
        currentCloudBackupsCount = await webDavCloudService.getBackupsCount();
      } catch (e) {
        currentCloudBackupsCount = 0;
      }
    }
    return [currentLocalBackupsCount, currentCloudBackupsCount];
  }

  deleteOldBackups(int maxBackupsCount) async {
    await ExportTokenUtil.deleteOldBackup();
    if (_enableCloudBackup &&
        validConfigs.isNotEmpty &&
        _cloudServiceConfig != null) {
      WebDavCloudService webDavCloudService =
          WebDavCloudService(_cloudServiceConfig!);
      await webDavCloudService.deleteOldBackup(maxBackupsCount);
    }
  }

  _backupSettings() {
    return [
      ItemBuilder.buildEntryItem(
        key: _setAutoBackupPasswordKey,
        context: context,
        topRadius: true,
        title: Utils.isNotEmpty(_autoBackupPassword)
            ? S.current.editAutoBackupPassword
            : S.current.setAutoBackupPassword,
        onTap: () {
          BottomSheetBuilder.showBottomSheet(
            context,
            responsive: true,
            (context) => InputBottomSheet(
              title: Utils.isNotEmpty(_autoBackupPassword)
                  ? S.current.editAutoBackupPassword
                  : S.current.setAutoBackupPassword,
              text: _autoBackupPassword,
              message: Utils.isNotEmpty(_autoBackupPassword)
                  ? S.current.editAutoBackupPasswordTip
                  : S.current.setAutoBackupPasswordTip,
              hint: S.current.inputAutoBackupPassword,
              tailingType: InputItemTailingType.password,
              validator: (text) {
                if (text.isEmpty) {
                  return S.current.autoBackupPasswordCannotBeEmpty;
                }
                return null;
              },
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetter,
              ],
              onConfirm: (text) async {},
              onValidConfirm: (text) async {
                IToast.showTop(Utils.isNotEmpty(_autoBackupPassword)
                    ? S.current.editSuccess
                    : S.current.setSuccess);
                ConfigDao.updateBackupPassword(text);
                setState(() {
                  _autoBackupPassword = text;
                  appProvider.canShowCloudBackupButton = _enableCloudBackup;
                });
              },
            ),
          );
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        bottomRadius: true,
        value: canBackup ? _useBackupPasswordToExportImport : false,
        title: S.current.useBackupPasswordToExportImport,
        description: S.current.useBackupPasswordToExportImportTip,
        disabled: _autoBackupPassword.isEmpty,
        onTap: () {
          setState(() {
            _useBackupPasswordToExportImport =
                !_useBackupPasswordToExportImport;
            HiveUtil.put(HiveUtil.useBackupPasswordToExportImportKey,
                _useBackupPasswordToExportImport);
          });
        },
      ),
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        context: context,
        topRadius: true,
        bottomRadius: !canImmediateBackup,
        value: canBackup ? _enableAutoBackup : false,
        title: S.current.autoBackup,
        description: S.current.autoBackupTip,
        disabled: !canBackup || !canImmediateBackup,
        onTap: () {
          setState(() {
            _enableAutoBackup = !_enableAutoBackup;
            HiveUtil.put(HiveUtil.enableAutoBackupKey, _enableAutoBackup);
          });
        },
      ),
      Visibility(
        visible: canImmediateBackup,
        child: ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.immediatelyBackup,
          description: S.current.immediatelyBackupTip,
          onTap: () async {
            ExportTokenUtil.autoBackup(
                showToast: true, showLoading: true, force: true);
          },
        ),
      ),
      Visibility(
        visible: canImmediateBackup,
        child: ItemBuilder.buildEntryItem(
          context: context,
          bottomRadius: true,
          title: S.current.backupLogs,
          onTap: () async {
            RouteUtil.pushDialogRoute(
              context,
              const BackupLogScreen(),
              overrideDialogNavigatorKey: GlobalKey(),
            );
          },
        ),
      ),
      if (canImmediateBackup) const SizedBox(height: 10),
      Visibility(
        visible: canImmediateBackup,
        child: ItemBuilder.buildEntryItem(
          context: context,
          topRadius: true,
          bottomRadius: true,
          title: S.current.maxBackupCount,
          description: S.current.maxBackupCountTip,
          tip: _maxBackupsCount.toString(),
          onTap: () async {
            CustomLoadingDialog.showLoading(title: S.current.loading);
            List<int> counts = await getBackupsCount();
            CustomLoadingDialog.dismissLoading();
            InputValidateAsyncController validateAsyncController =
                InputValidateAsyncController(
              controller:
                  TextEditingController(text: _maxBackupsCount.toString()),
              validator: (text) async {
                return null;
              },
            );
            BottomSheetBuilder.showBottomSheet(
              context,
              responsive: true,
              (context) => InputBottomSheet(
                title: S.current.maxBackupCount,
                text: _maxBackupsCount.toString(),
                message:
                    '${S.current.maxBackupCountTip}\n${S.current.currentBackupCountTip(counts[0], counts[1])}',
                hint: S.current.inputMaxBackupCount,
                inputFormatters: [RegexInputFormatter.onlyNumber],
                preventPop: true,
                validateAsyncController: validateAsyncController,
                validator: (text) {
                  if (text.isEmpty) {
                    return S.current.maxBackupCountCannotBeEmpty;
                  }
                  int? count = int.tryParse(text);
                  if (count == null) {
                    return S.current.maxBackupCountTooLong;
                  }
                  if (count > maxBackupCountThrehold) {
                    return S.current
                        .maxBackupCountExceed(maxBackupCountThrehold);
                  }
                  return null;
                },
                onConfirm: (text) async {},
                onValidConfirm: (text) async {
                  int count = int.parse(text);
                  onValid() {
                    HiveUtil.put(HiveUtil.maxBackupsCountKey, count);
                    setState(() {
                      _maxBackupsCount = count;
                    });
                    deleteOldBackups(count);
                    validateAsyncController.doPop?.call();
                  }

                  if (count > 0 && (counts[0] > count || counts[1] > count)) {
                    DialogBuilder.showConfirmDialog(
                      context,
                      title: S.current.maxBackupCountWarning,
                      message: S.current
                          .maxBackupCountWarningMessage(counts[0], counts[1]),
                      onTapConfirm: () {
                        onValid();
                      },
                      onTapCancel: () {},
                    );
                  } else {
                    onValid();
                  }
                },
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        context: context,
        value: canBackup ? _enableLocalBackup : false,
        title: S.current.enableLocalBackup,
        topRadius: true,
        description: S.current.enableLocalBackupTip,
        bottomRadius: !_enableLocalBackup || !canBackup,
        disabled: !canLocalBackup,
        onTap: () {
          setState(() {
            _enableLocalBackup = !_enableLocalBackup;
            HiveUtil.put(HiveUtil.enableLocalBackupKey, _enableLocalBackup);
          });
        },
      ),
      Visibility(
        visible: canBackup && _enableLocalBackup,
        child: ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.autoBackupPath,
          description: _autoBackupPath,
          onTap: () async {
            String? selectedDirectory =
                await FilePicker.platform.getDirectoryPath(
              dialogTitle: S.current.autoBackupPath,
              lockParentWindow: true,
            );
            if (selectedDirectory != null) {
              setState(() {
                _autoBackupPath = selectedDirectory;
                HiveUtil.put(HiveUtil.backupPathKey, selectedDirectory);
              });
            }
          },
        ),
      ),
      Visibility(
        visible: canBackup && _enableLocalBackup,
        child: ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.viewLocalBackup,
          bottomRadius: true,
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
      ),
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        context: context,
        topRadius: true,
        value: canBackup ? _enableCloudBackup : false,
        title: S.current.enableCloudBackup,
        description: S.current.enableCloudBackupTip,
        bottomRadius: !_enableCloudBackup || !canBackup,
        disabled: !canCloudBackup,
        onTap: () {
          setState(() {
            _enableCloudBackup = !_enableCloudBackup;
            HiveUtil.put(HiveUtil.enableCloudBackupKey, _enableCloudBackup);
            appProvider.canShowCloudBackupButton = _enableCloudBackup;
          });
        },
      ),
      Visibility(
        visible: canBackup && _enableCloudBackup,
        child: ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.cloudBackupServiceSetting,
          bottomRadius: true,
          description: validConfigs.isNotEmpty
              ? S.current.haveSetCloudBackupService(validConfigs)
              : S.current.notCloudBackupService,
          onTap: () async {
            RouteUtil.pushCupertinoRoute(
              context,
              const CloudServiceScreen(),
              onThen: (value) {
                loadWebDavConfig();
              },
            );
          },
        ),
      ),
    ];
  }
}
