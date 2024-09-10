import 'dart:typed_data';

import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/BottomSheet/Backups/onedrive_backups_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cloud/onedrive_response.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/onedrive_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Utils/ilogger.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/progress_dialog.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

class OneDriveServiceScreen extends StatefulWidget {
  const OneDriveServiceScreen({
    super.key,
  });

  static const String routeName = "/service/onedrive";

  @override
  State<OneDriveServiceScreen> createState() => _OneDriveServiceScreenState();
}

class _OneDriveServiceScreenState extends State<OneDriveServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  CloudServiceConfig? _oneDriveCloudServiceConfig;
  OneDriveCloudService? _oneDriveCloudService;
  bool inited = false;

  CloudServiceConfig get currentConfig => _oneDriveCloudServiceConfig!;

  CloudService get currentService => _oneDriveCloudService!;

  bool get _configInitialized {
    return _oneDriveCloudServiceConfig != null;
  }

  @override
  void initState() {
    super.initState();
    try {
      loadConfig();
    } catch (e) {
      inited = true;
      IToast.show(S.current.cloudConnectionError);
    }
  }

  loadConfig() async {
    _oneDriveCloudServiceConfig =
        await CloudServiceConfigDao.getOneDriveConfig();
    if (_oneDriveCloudServiceConfig != null) {
      _sizeController.text = _oneDriveCloudServiceConfig!.size;
      _accountController.text = _oneDriveCloudServiceConfig!.account ?? "";
      _emailController.text = _oneDriveCloudServiceConfig!.email ?? "";
      _oneDriveCloudService = OneDriveCloudService(
        _oneDriveCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    } else {
      _oneDriveCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.OneDrive);
      await CloudServiceConfigDao.insertConfig(_oneDriveCloudServiceConfig!);
      _oneDriveCloudService = OneDriveCloudService(
        _oneDriveCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    }
    if (_oneDriveCloudService != null) {
      _oneDriveCloudServiceConfig!.configured =
          await _oneDriveCloudService!.hasConfigured();
      _oneDriveCloudServiceConfig!.connected =
          await _oneDriveCloudService!.isConnected();
      if (_oneDriveCloudServiceConfig!.configured &&
          !_oneDriveCloudServiceConfig!.connected) {
        IToast.showTop(S.current.cloudConnectionError);
      }
      updateConfig(_oneDriveCloudServiceConfig!);
    }
    inited = true;
    if (mounted) setState(() {});
  }

  updateConfig(CloudServiceConfig config) {
    if (mounted) {
      setState(() {
        _oneDriveCloudServiceConfig = config;
      });
    }
    _sizeController.text = _oneDriveCloudServiceConfig!.size;
    _accountController.text = _oneDriveCloudServiceConfig!.account ?? "";
    _emailController.text = _oneDriveCloudServiceConfig!.email ?? "";
    CloudServiceConfigDao.updateConfig(_oneDriveCloudServiceConfig!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return inited
        ? _buildBody()
        : ItemBuilder.buildLoadingDialog(
            context,
            background: Colors.transparent,
            text: S.current.cloudConnecting,
            mainAxisAlignment: MainAxisAlignment.start,
            topPadding: 100,
          );
  }

  _buildUnsupportBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          Text(S.current.cloudTypeNotSupport(S.current.cloudTypeOneDrive)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  ping({
    bool showLoading = true,
    bool showSuccessToast = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.cloudConnecting);
    }
    await currentService.authenticate().then((value) async {
      setState(() {
        currentConfig.connected = value == CloudServiceStatus.success;
      });
      if (!currentConfig.connected) {
        switch (value) {
          case CloudServiceStatus.connectionError:
            IToast.show(S.current.cloudConnectionError);
            break;
          case CloudServiceStatus.unauthorized:
            IToast.show(S.current.cloudOauthFailed);
            break;
          default:
            IToast.show(S.current.cloudUnknownError);
            break;
        }
      } else {
        _oneDriveCloudServiceConfig!.configured = true;
        updateConfig(_oneDriveCloudServiceConfig!);
        if (showSuccessToast) IToast.show(S.current.cloudAuthSuccess);
      }
    });
    if (showLoading) CustomLoadingDialog.dismissLoading();
  }

  _buildBody() {
    return Column(
      children: [
        if (_configInitialized) _enableInfo(),
        const SizedBox(height: 10),
        if (_configInitialized && currentConfig.connected) _accountInfo(),
        const SizedBox(height: 30),
        if (_configInitialized && !currentConfig.connected) _loginButton(),
        if (_configInitialized && currentConfig.connected) _operationButtons(),
      ],
    );
  }

  _enableInfo() {
    return ItemBuilder.buildRadioItem(
      context: context,
      title: S.current.enable + S.current.cloudTypeOneDrive,
      description: S.current.cloudTypeOneDriveTip,
      topRadius: true,
      bottomRadius: true,
      value: _oneDriveCloudServiceConfig?.enabled ?? false,
      onTap: () {
        setState(() {
          _oneDriveCloudServiceConfig!.enabled =
              !_oneDriveCloudServiceConfig!.enabled;
          CloudServiceConfigDao.updateConfigEnabled(
              _oneDriveCloudServiceConfig!,
              _oneDriveCloudServiceConfig!.enabled);
        });
      },
    );
  }

  _accountInfo() {
    return ItemBuilder.buildContainerItem(
      context: context,
      topRadius: true,
      bottomRadius: true,
      padding: const EdgeInsets.only(top: 15, bottom: 5, right: 10),
      child: Column(
        children: [
          InputItem(
            controller: _accountController,
            textInputAction: TextInputAction.next,
            leadingType: InputItemLeadingType.text,
            disabled: true,
            leadingText: S.current.cloudDisplayName,
          ),
          InputItem(
            controller: _emailController,
            textInputAction: TextInputAction.next,
            leadingType: InputItemLeadingType.text,
            disabled: true,
            leadingText: S.current.cloudEmail,
          ),
          InputItem(
            controller: _sizeController,
            textInputAction: TextInputAction.next,
            leadingType: InputItemLeadingType.text,
            disabled: true,
            leadingText: S.current.cloudSize,
          ),
        ],
      ),
    );
  }

  _loginButton() {
    return Row(
      children: [
        const SizedBox(width: 10),
        Expanded(
          child: ItemBuilder.buildRoundButton(
            context,
            text: S.current.cloudSignin,
            background: Theme.of(context).primaryColor,
            fontSizeDelta: 2,
            onTap: () async {
              try {
                ping();
              } catch (e, t) {
                ILogger.error("CloudOTP","Failed to connect to onedrive", e, t);
                IToast.show(S.current.cloudConnectionError);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  _operationButtons() {
    return Row(
      children: [
        const SizedBox(width: 10),
        Expanded(
          child: ItemBuilder.buildFramedButton(
            context,
            text: S.current.cloudPullBackup,
            padding: const EdgeInsets.symmetric(vertical: 12),
            outline: Theme.of(context).primaryColor,
            color: Theme.of(context).primaryColor,
            fontSizeDelta: 2,
            onTap: () async {
              CustomLoadingDialog.showLoading(title: S.current.cloudPulling);
              try {
                List<OneDriveFileInfo>? files =
                    await _oneDriveCloudService!.listBackups();
                if (files == null) {
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(S.current.cloudPullFailed);
                  return;
                }
                CloudServiceConfigDao.updateLastPullTime(
                    _oneDriveCloudServiceConfig!);
                CustomLoadingDialog.dismissLoading();
                files.sort((a, b) =>
                    b.lastModifiedDateTime.compareTo(a.lastModifiedDateTime));
                if (files.isNotEmpty) {
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    responsive: true,
                    (dialogContext) => OneDriveBackupsBottomSheet(
                      files: files,
                      cloudService: _oneDriveCloudService!,
                      onSelected: (selectedFile) async {
                        var dialog = showProgressDialog(
                          msg: S.current.cloudPulling,
                          showProgress: true,
                        );
                        Uint8List? res =
                            await _oneDriveCloudService!.downloadFile(
                          selectedFile.id,
                          onProgress: (c, t) {
                            dialog.updateProgress(progress: c / t);
                          },
                        );
                        ImportTokenUtil.importFromCloud(context, res, dialog);
                      },
                    ),
                  );
                } else {
                  IToast.show(S.current.cloudNoBackupFile);
                }
              } catch (e, t) {
                ILogger.error("CloudOTP","Failed to pull from onedrive", e, t);
                CustomLoadingDialog.dismissLoading();
                IToast.show(S.current.cloudPullFailed);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ItemBuilder.buildRoundButton(
            context,
            padding: const EdgeInsets.symmetric(vertical: 12),
            background: Theme.of(context).primaryColor,
            text: S.current.cloudPushBackup,
            fontSizeDelta: 2,
            onTap: () async {
              ExportTokenUtil.backupEncryptToCloud(
                config: _oneDriveCloudServiceConfig!,
                cloudService: _oneDriveCloudService!,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ItemBuilder.buildRoundButton(
            context,
            padding: const EdgeInsets.symmetric(vertical: 12),
            background: Colors.red,
            text: S.current.cloudLogout,
            fontSizeDelta: 2,
            onTap: () async {
              DialogBuilder.showConfirmDialog(context,
                  title: S.current.cloudLogout,
                  message: S.current.cloudLogoutMessage,
                  onTapConfirm: () async {
                CustomLoadingDialog.showLoading(
                    title: S.current.cloudLoggingOut);
                await _oneDriveCloudService!.signOut();
                setState(() {
                  _oneDriveCloudServiceConfig!.connected = false;
                  _oneDriveCloudServiceConfig!.account = "";
                  _oneDriveCloudServiceConfig!.email = "";
                  _oneDriveCloudServiceConfig!.totalSize =
                      _oneDriveCloudServiceConfig!.remainingSize =
                          _oneDriveCloudServiceConfig!.usedSize = -1;
                  updateConfig(_oneDriveCloudServiceConfig!);
                });
                CustomLoadingDialog.dismissLoading();
                IToast.show(S.current.cloudLogoutSuccess);
              });
            },
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
