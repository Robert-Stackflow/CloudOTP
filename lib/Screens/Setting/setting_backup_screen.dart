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
import '../../Widgets/BottomSheet/Backups/local_backups_bottom_sheet.dart';
import '../../l10n/l10n.dart';
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

class _BackupSettingScreenState extends BaseDynamicState<BackupSettingScreen>
    with TickerProviderStateMixin {
  bool inited = false;
  bool _enableAutoBackup =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableAutoBackupKey);
  bool _enableLocalBackup =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableLocalBackupKey);
  bool _useBackupPasswordToExportImport = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.useBackupPasswordToExportImportKey);
  String _autoBackupPath = "";
  String _defaultBackupPath = "";
  String _autoBackupPassword = "";
  bool _enableCloudBackup =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableCloudBackupKey);
  CloudServiceConfig? _cloudServiceConfig;
  int _maxBackupsCount = CloudOTPHiveUtil.getMaxBackupsCount();
  bool _enableBackupOnLaunch =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableBackupOnLaunchKey,
          defaultValue: false);
  final GlobalKey _setAutoBackupPasswordKey = GlobalKey();
  String validConfigs = "";

  @override
  void initState() {
    super.initState();
    ConfigDao.getConfig().then((config) {
      setState(() {
        _autoBackupPassword = config.backupPassword;
        inited = true;
      });
    });
    CloudOTPHiveUtil.getBackupPath().then((path) {
      setState(() {
        _autoBackupPath = path;
      });
    });
    FileUtil.getBackupDir().then((path) {
      _defaultBackupPath = path;
    });
    loadWebDavConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.jumpToAutoBackupPassword) {
        scrollToSetAutoBackupPassword();
      }
      _checkBackupMethodsEnabled();
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

  void _checkBackupMethodsEnabled() {
    if (!_enableLocalBackup && !_enableCloudBackup) {
      setState(() {
        _enableLocalBackup = true;
        ChewieHiveUtil.put(
            CloudOTPHiveUtil.enableLocalBackupKey, true);
      });
      DialogBuilder.showInfoDialog(
        context,
        message: appLocalizations.bothBackupDisabledWarning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.backupSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        if (inited && !canBackup) ...[
          const SizedBox(height: 10),
          TipBanner(message: appLocalizations.notSetBackupPasswordTip),
        ],
        ..._backupSettings(),
        const SizedBox(height: 30),
      ],
    );
  }

  bool get canBackup => _autoBackupPassword.isNotEmpty;

  loadWebDavConfig() async {
    List<CloudServiceConfig> configs =
        await CloudServiceConfigDao.getValidConfigs();
    setState(() {
      validConfigs = configs.map((e) => e.displayName).join(", ");
    });
  }

  Future<int> getBackupsCount() async {
    return await ExportTokenUtil.getBackupsCount();
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
        title: appLocalizations.backupPasswordSettings,
        children: [
          EntryItem(
            key: _setAutoBackupPasswordKey,
            title: _autoBackupPassword.notNullOrEmpty
                ? appLocalizations.editAutoBackupPassword
                : appLocalizations.setAutoBackupPassword,
            trailing: LucideIcons.pencilLine,
            onTap: () {
              BottomSheetBuilder.showBottomSheet(
                context,
                responsive: true,
                (context) => InputBottomSheet(
                  title: _autoBackupPassword.notNullOrEmpty
                      ? appLocalizations.editAutoBackupPassword
                      : appLocalizations.setAutoBackupPassword,
                  text: _autoBackupPassword,
                  message: _autoBackupPassword.notNullOrEmpty
                      ? appLocalizations.editAutoBackupPasswordTip
                      : appLocalizations.setAutoBackupPasswordTip,
                  hint: appLocalizations.inputAutoBackupPassword,
                  tailingConfig: InputItemLeadingTailingConfig(
                    type: InputItemLeadingTailingType.password,
                  ),
                  validator: (text) {
                    if (text.isEmpty) {
                      return appLocalizations.autoBackupPasswordCannotBeEmpty;
                    }
                    return null;
                  },
                  inputFormatters: [
                    RegexInputFormatter.onlyNumberAndLetterAndSymbol,
                  ],
                  onConfirm: (text) async {},
                  onValidConfirm: (text) async {
                    IToast.showTop(_autoBackupPassword.notNullOrEmpty
                        ? appLocalizations.editSuccess
                        : appLocalizations.setSuccess);
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
            title: appLocalizations.useBackupPasswordToExportImport,
            description: appLocalizations.useBackupPasswordToExportImportTip,
            disabled: !canBackup,
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
        title: appLocalizations.autoBackupSettings,
        children: [
          CheckboxItem(
            value: canBackup ? _enableAutoBackup : false,
            title: appLocalizations.autoBackup,
            description: appLocalizations.autoBackupTip,
            disabled: !canBackup,
            onTap: () {
              setState(() {
                _enableAutoBackup = !_enableAutoBackup;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.enableAutoBackupKey, _enableAutoBackup);
              });
            },
          ),
          if (_enableAutoBackup && canBackup)
            CheckboxItem(
              value: _enableBackupOnLaunch,
              title: appLocalizations.backupOnLaunch,
              description: appLocalizations.backupOnLaunchTip,
              onTap: () {
                setState(() {
                  _enableBackupOnLaunch = !_enableBackupOnLaunch;
                  ChewieHiveUtil.put(CloudOTPHiveUtil.enableBackupOnLaunchKey,
                      _enableBackupOnLaunch);
                });
              },
            ),
          if (canBackup)
            EntryItem(
              title: appLocalizations.immediatelyBackup,
              description: appLocalizations.immediatelyBackupTip,
              trailing: LucideIcons.cloudUpload,
              onTap: () async {
                ExportTokenUtil.autoBackup(
                    showToast: true, showLoading: true, force: true);
              },
            ),
          if (canBackup)
            EntryItem(
              title: appLocalizations.maxBackupCount,
              description: appLocalizations.maxBackupCountTip,
              tip: _maxBackupsCount.toString(),
              onTap: () async {
                CustomLoadingDialog.showLoading(
                    title: appLocalizations.loading);
                int currentCount = await getBackupsCount();
                CustomLoadingDialog.dismissLoading();
                if (!mounted) return;
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
                    title: appLocalizations.maxBackupCount,
                    text: _maxBackupsCount.toString(),
                    message:
                        '${appLocalizations.maxBackupCountTip}\n${appLocalizations.currentBackupCountTip(currentCount)}',
                    hint: appLocalizations.inputMaxBackupCount,
                    inputFormatters: [RegexInputFormatter.onlyNumber],
                    preventPop: true,
                    validateAsyncController: validateAsyncController,
                    validator: (text) {
                      if (text.isEmpty) {
                        return appLocalizations.maxBackupCountCannotBeEmpty;
                      }
                      int? count = int.tryParse(text);
                      if (count == null) {
                        return appLocalizations.maxBackupCountTooLong;
                      }
                      if (count > maxBackupCountThrehold) {
                        return appLocalizations
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

                        if (count > 0 && (currentCount > count)) {
                          DialogBuilder.showConfirmDialog(
                            context,
                            title: appLocalizations.maxBackupCountWarning,
                            message: appLocalizations
                                .maxBackupCountWarningMessage(currentCount),
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
          if (canBackup)
            EntryItem(
              title: appLocalizations.backupLogs,
              trailing: LucideIcons.history,
              onTap: () async {
                BackupLogScreen.show(context);
              },
            ),
        ],
      ),
      CaptionItem(
        title: appLocalizations.localBackupSettings,
        children: [
          CheckboxItem(
            value: canBackup ? _enableLocalBackup : false,
            title: appLocalizations.enableLocalBackup,
            description: appLocalizations.enableLocalBackupTip,
            disabled: !canBackup ||
                (_enableLocalBackup &&
                    (!_enableCloudBackup || validConfigs.isEmpty)),
            onTap: () {
              setState(() {
                _enableLocalBackup = !_enableLocalBackup;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.enableLocalBackupKey, _enableLocalBackup);
              });
            },
          ),
          if (canBackup && _enableLocalBackup)
            EntryItem(
              title: appLocalizations.autoBackupPath,
              description: _autoBackupPath,
              trailing: LucideIcons.ellipsis,
              onTap: () async {
                String? selectedDirectory = await FileUtil.getDirectoryPath(
                  dialogTitle: appLocalizations.autoBackupPath,
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
          if (canBackup &&
              _enableLocalBackup &&
              _defaultBackupPath.isNotEmpty &&
              _autoBackupPath != _defaultBackupPath)
            EntryItem(
              title: appLocalizations.restoreDefaultBackupPath,
              description: appLocalizations.restoreDefaultBackupPathTip,
              trailing: LucideIcons.rotateCcw,
              onTap: () {
                setState(() {
                  _autoBackupPath = _defaultBackupPath;
                  ChewieHiveUtil.put(
                      CloudOTPHiveUtil.backupPathKey, "");
                });
              },
            ),
          if (canBackup && _enableLocalBackup)
            EntryItem(
              title: appLocalizations.viewLocalBackup,
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
        ],
      ),
      CaptionItem(
        title: appLocalizations.cloudBackupSettings,
        children: [
          CheckboxItem(
            value: canBackup ? _enableCloudBackup : false,
            title: appLocalizations.enableCloudBackup,
            description: appLocalizations.enableCloudBackupTip,
            disabled: !canBackup ||
                (_enableCloudBackup && !_enableLocalBackup),
            onTap: () {
              setState(() {
                _enableCloudBackup = !_enableCloudBackup;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.enableCloudBackupKey, _enableCloudBackup);
                appProvider.canShowCloudBackupButton = _enableCloudBackup;
              });
            },
          ),
          if (canBackup && _enableCloudBackup)
            EntryItem(
              title: appLocalizations.cloudBackupServiceSetting,
              description: validConfigs.isNotEmpty
                  ? appLocalizations.haveSetCloudBackupService(validConfigs)
                  : appLocalizations.notCloudBackupService,
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
        ],
      ),
    ];
  }
}
