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
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Screens/Backup/cloud_service_screen.dart';
import 'package:cloudotp/Screens/Setting/backup_log_screen.dart';
import 'package:cloudotp/TokenUtils/Cloud/webdav_cloud_service.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Utils/hive_util.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import '../../Widgets/BottomSheet/Backups/local_backups_bottom_sheet.dart';
import '../../generated/l10n.dart';
import 'base_setting_screen.dart';

class BackupSettingScreen extends BaseSettingScreen {
  const BackupSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
    this.jumpToAutoBackupPassword = false,
  });

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
  bool _enableAutoBackup =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableAutoBackupKey);
  bool _enableLocalBackup =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableLocalBackupKey);
  bool _useBackupPasswordToExportImport = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.useBackupPasswordToExportImportKey);
  String _autoBackupPath = "";
  String _autoBackupPassword = "";
  bool _enableCloudBackup =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableCloudBackupKey);
  CloudServiceConfig? _cloudServiceConfig;
  int _maxBackupsCount = CloudOTPHiveUtil.getMaxBackupsCount();
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
    CloudOTPHiveUtil.getBackupPath().then((path) {
      setState(() {
        _autoBackupPath = path;
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
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: S.current.backupSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscape(),
      padding: widget.padding,
      children: [
        ..._backupSettings(),
        const SizedBox(height: 30),
      ],
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
    return [currentLocalBackupsCount];
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
      SearchableCaptionItem(
        title: "备份密码",
        children: [
          EntryItem(
            key: _setAutoBackupPasswordKey,
            title: _autoBackupPassword.notNullOrEmpty
                ? S.current.editAutoBackupPassword
                : S.current.setAutoBackupPassword,
            trailing: LucideIcons.pencilLine,
            onTap: () {
              BottomSheetBuilder.showBottomSheet(
                context,
                responsive: true,
                useWideLandscape: true,
                (context) => InputBottomSheet(
                  title: _autoBackupPassword.notNullOrEmpty
                      ? S.current.editAutoBackupPassword
                      : S.current.setAutoBackupPassword,
                  text: _autoBackupPassword,
                  message: _autoBackupPassword.notNullOrEmpty
                      ? S.current.editAutoBackupPasswordTip
                      : S.current.setAutoBackupPasswordTip,
                  hint: S.current.inputAutoBackupPassword,
                  tailingConfig: InputItemLeadingTailingConfig(
                    type: InputItemLeadingTailingType.password,
                  ),
                  validator: (text) {
                    if (text.isEmpty) {
                      return S.current.autoBackupPasswordCannotBeEmpty;
                    }
                    return null;
                  },
                  inputFormatters: [
                    RegexInputFormatter.onlyNumberAndLetterAndSymbol,
                  ],
                  onConfirm: (text) async {},
                  onValidConfirm: (text) async {
                    IToast.showTop(_autoBackupPassword.notNullOrEmpty
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
          CheckboxItem(
            value: canBackup ? _useBackupPasswordToExportImport : false,
            title: S.current.useBackupPasswordToExportImport,
            description: S.current.useBackupPasswordToExportImportTip,
            disabled: _autoBackupPassword.isEmpty,
            onTap: () {
              setState(() {
                _useBackupPasswordToExportImport =
                    !_useBackupPasswordToExportImport;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.useBackupPasswordToExportImportKey,
                    _useBackupPasswordToExportImport);
              });
            },
          ),
        ],
      ),
      CaptionItem(
        title: "自动备份",
        children: [
          CheckboxItem(
            value: canBackup ? _enableAutoBackup : false,
            title: S.current.autoBackup,
            description: S.current.autoBackupTip,
            disabled: !canBackup || !canImmediateBackup,
            onTap: () {
              setState(() {
                _enableAutoBackup = !_enableAutoBackup;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.enableAutoBackupKey, _enableAutoBackup);
              });
            },
          ),
          Visibility(
            visible: canImmediateBackup,
            child: EntryItem(
              title: S.current.immediatelyBackup,
              description: S.current.immediatelyBackupTip,
              trailing: LucideIcons.cloudUpload,
              onTap: () async {
                ExportTokenUtil.autoBackup(
                    showToast: true, showLoading: true, force: true);
              },
            ),
          ),
          Visibility(
            visible: canImmediateBackup,
            child: EntryItem(
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
                  useWideLandscape: true,
                  (context) => InputBottomSheet(
                    title: S.current.maxBackupCount,
                    text: _maxBackupsCount.toString(),
                    message:
                        '${S.current.maxBackupCountTip}\n${S.current.currentBackupCountTip(counts[0])}',
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
                      try {
                        int count = int.parse(text);
                        onValid() {
                          ChewieHiveUtil.put(
                              CloudOTPHiveUtil.maxBackupsCountKey, count);
                          setState(() {
                            _maxBackupsCount = count;
                          });
                          deleteOldBackups(count);
                          validateAsyncController.doPop?.call();
                        }

                        if (count > 0 && (counts[0] > count)) {
                          DialogBuilder.showConfirmDialog(
                            context,
                            title: S.current.maxBackupCountWarning,
                            message: S.current
                                .maxBackupCountWarningMessage(counts[0]),
                            onTapConfirm: () {
                              onValid();
                            },
                            onTapCancel: () {},
                          );
                        } else {
                          onValid();
                        }
                      } catch (e, t) {
                        ILogger.error("Failed to change backups count", e, t);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      CaptionItem(
        title: "本地备份",
        children: [
          CheckboxItem(
            value: canBackup ? _enableLocalBackup : false,
            title: S.current.enableLocalBackup,
            description: S.current.enableLocalBackupTip,
            disabled: !canLocalBackup,
            onTap: () {
              setState(() {
                _enableLocalBackup = !_enableLocalBackup;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.enableLocalBackupKey, _enableLocalBackup);
              });
            },
          ),
          Visibility(
            visible: canBackup && _enableLocalBackup,
            child: EntryItem(
              title: S.current.autoBackupPath,
              description: _autoBackupPath,
              trailing: LucideIcons.ellipsis,
              onTap: () async {
                String? selectedDirectory = await FileUtil.getDirectoryPath(
                  dialogTitle: S.current.autoBackupPath,
                  lockParentWindow: true,
                );
                if (selectedDirectory != null) {
                  setState(() {
                    _autoBackupPath = selectedDirectory;
                    ChewieHiveUtil.put(
                        CloudOTPHiveUtil.backupPathKey, selectedDirectory);
                  });
                }
              },
            ),
          ),
          Visibility(
            visible: canBackup && _enableLocalBackup,
            child: EntryItem(
              title: S.current.viewLocalBackup,
              trailing: LucideIcons.squareArrowOutUpRight,
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
        ],
      ),
      CaptionItem(
        title: "云端备份",
        children: [
          CheckboxItem(
            value: canBackup ? _enableCloudBackup : false,
            title: S.current.enableCloudBackup,
            description: S.current.enableCloudBackupTip,
            disabled: !canCloudBackup,
            onTap: () {
              setState(() {
                _enableCloudBackup = !_enableCloudBackup;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.enableCloudBackupKey, _enableCloudBackup);
                appProvider.canShowCloudBackupButton = _enableCloudBackup;
              });
            },
          ),
          Visibility(
            visible: canBackup && _enableCloudBackup,
            child: EntryItem(
              title: S.current.cloudBackupServiceSetting,
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
        ],
      ),
    ];
  }
}
