import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Screens/Backup/cloud_service_screen.dart';
import 'package:cloudotp/TokenUtils/Cloud/webdav_cloud_service.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/input_item.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
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
  bool _enableCloudBackup = HiveUtil.getBool(HiveUtil.enableCloudBackupKey);
  bool _useBackupPasswordToExportImport =
      HiveUtil.getBool(HiveUtil.useBackupPasswordToExportImportKey);
  String _autoBackupPath = HiveUtil.getString(HiveUtil.backupPathKey) ?? "";
  String _autoBackupPassword = "";
  bool _cloudBackupConfigured = false;
  CloudServiceConfig? _cloudServiceConfig;
  int _maxBackupsCount = HiveUtil.getMaxBackupsCount();
  final GlobalKey _setAutoBackupPasswordKey = GlobalKey();

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
                title: S.current.setting,
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
                  S.current.setting,
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
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
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

  bool get canCloudBackup =>
      _cloudBackupConfigured && _autoBackupPassword.isNotEmpty;

  bool get canImmediateBackup =>
      canBackup &&
      ((canLocalBackup && _enableLocalBackup) ||
          (canCloudBackup && _enableCloudBackup));

  loadWebDavConfig() async {
    _cloudServiceConfig = await CloudServiceConfigDao.getWebdavConfig();
    setState(() {
      _cloudBackupConfigured = (_cloudServiceConfig != null &&
          Utils.isNotEmpty(_cloudServiceConfig!.account) &&
          Utils.isNotEmpty(_cloudServiceConfig!.secret) &&
          Utils.isNotEmpty(_cloudServiceConfig!.endpoint));
    });
  }

  getBackupsCount() async {
    int currentLocalBackupsCount = await ExportTokenUtil.getBackupsCount();
    late int currentCloudBackupsCount;
    if (!_enableCloudBackup ||
        !_cloudBackupConfigured ||
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
        _cloudBackupConfigured &&
        _cloudServiceConfig != null) {
      WebDavCloudService webDavCloudService =
          WebDavCloudService(_cloudServiceConfig!);
      await webDavCloudService.deleteOldBackup(maxBackupsCount);
    }
  }

  _backupSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.backupSetting),
      ItemBuilder.buildEntryItem(
        key: _setAutoBackupPasswordKey,
        context: context,
        title: Utils.isNotEmpty(_autoBackupPassword)
            ? S.current.editAutoBackupPassword
            : S.current.setAutoBackupPassword,
        onTap: () {
          TextEditingController controller = TextEditingController();
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
              controller: controller,
              stateController: InputStateController(
                validate: (text) {
                  if (text.isEmpty) {
                    return Future.value(
                        S.current.autoBackupPasswordCannotBeEmpty);
                  }
                  return Future.value(null);
                },
              ),
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
                });
              },
            ),
          );
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
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
      ItemBuilder.buildRadioItem(
        context: context,
        value: canBackup ? _enableAutoBackup : false,
        title: S.current.autoBackup,
        description: S.current.autoBackupTip,
        disabled: !canBackup,
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
          title: S.current.maxBackupCount,
          description: S.current.maxBackupCountTip,
          tip: _maxBackupsCount.toString(),
          onTap: () async {
            var stateController = InputStateController(
              validate: (text) {
                if (text.isEmpty) {
                  return Future.value(S.current.maxBackupCountCannotBeEmpty);
                }
                if (int.tryParse(text) == null) {
                  return Future.value(S.current.maxBackupCountTooLong);
                }
                return Future.value(null);
              },
            );
            CustomLoadingDialog.showLoading(title: S.current.loading);
            List<int> counts = await getBackupsCount();
            CustomLoadingDialog.dismissLoading();
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
                stateController: stateController,
                onConfirm: (text) async {},
                onValidConfirm: (text) async {
                  int count = int.parse(text);
                  onValid() {
                    HiveUtil.put(HiveUtil.maxBackupsCountKey, count);
                    setState(() {
                      _maxBackupsCount = count;
                    });
                    stateController.pop?.call();
                    deleteOldBackups(count);
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
      ItemBuilder.buildRadioItem(
        context: context,
        value: canBackup ? _enableLocalBackup : false,
        title: S.current.enableLocalBackup,
        description: S.current.enableLocalBackupTip,
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
      ItemBuilder.buildRadioItem(
        context: context,
        value: canBackup ? _enableCloudBackup : false,
        title: S.current.enableCloudBackup,
        description: S.current.enableCloudBackupTip,
        bottomRadius: !_enableCloudBackup || !canBackup,
        disabled: !canCloudBackup,
        onTap: () {
          setState(() {
            _enableCloudBackup = !_enableCloudBackup;
            HiveUtil.put(HiveUtil.enableCloudBackupKey, _enableCloudBackup);
          });
        },
      ),
      Visibility(
        visible: canBackup && _enableCloudBackup,
        child: ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.cloudBackupServiceSetting,
          bottomRadius: true,
          description: _cloudBackupConfigured
              ? S.current.haveSetCloudBackupService("WebDav")
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
