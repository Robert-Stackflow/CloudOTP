import 'dart:typed_data';

import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cloud/huaweicloud_response.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/huawei_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Widgets/BottomSheet/Backups/huawei_backups_bottom_sheet.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/progress_dialog.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

class HuaweiCloudServiceScreen extends StatefulWidget {
  const HuaweiCloudServiceScreen({
    super.key,
  });

  static const String routeName = "/service/huaweiCloud";

  @override
  State<HuaweiCloudServiceScreen> createState() => _HuaweiCloudServiceScreenState();
}

class _HuaweiCloudServiceScreenState extends State<HuaweiCloudServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  CloudServiceConfig? _huaweiCloudCloudServiceConfig;
  HuaweiCloudService? _huaweiCloudCloudService;
  bool inited = false;

  CloudServiceConfig get currentConfig => _huaweiCloudCloudServiceConfig!;

  CloudService get currentService => _huaweiCloudCloudService!;

  bool get _configInitialized {
    return _huaweiCloudCloudServiceConfig != null;
  }

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  loadConfig() async {
    _huaweiCloudCloudServiceConfig = await CloudServiceConfigDao.getHuaweiCloudConfig();
    if (_huaweiCloudCloudServiceConfig != null) {
      _sizeController.text = _huaweiCloudCloudServiceConfig!.size;
      _accountController.text = _huaweiCloudCloudServiceConfig!.account ?? "";
      _huaweiCloudCloudService = HuaweiCloudService(
        _huaweiCloudCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    } else {
      _huaweiCloudCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.HuaweiCloud);
      await CloudServiceConfigDao.insertConfig(_huaweiCloudCloudServiceConfig!);
      _huaweiCloudCloudService = HuaweiCloudService(
        _huaweiCloudCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    }
    if (_huaweiCloudCloudService != null) {
      _huaweiCloudCloudServiceConfig!.configured =
      await _huaweiCloudCloudService!.hasConfigured();
      _huaweiCloudCloudServiceConfig!.connected =
      await _huaweiCloudCloudService!.isConnected();
      if (_huaweiCloudCloudServiceConfig!.configured &&
          !_huaweiCloudCloudServiceConfig!.connected) {
        IToast.showTop(S.current.cloudConnectionError);
      }
      updateConfig(_huaweiCloudCloudServiceConfig!);
    }
    inited = true;
    setState(() {});
  }

  updateConfig(CloudServiceConfig config) {
    if (mounted) {
      setState(() {
        _huaweiCloudCloudServiceConfig = config;
      });
    }
    _sizeController.text = _huaweiCloudCloudServiceConfig!.size;
    _accountController.text = _huaweiCloudCloudServiceConfig!.account ?? "";
    CloudServiceConfigDao.updateConfig(_huaweiCloudCloudServiceConfig!);
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

  ping({
    bool showLoading = true,
    bool showSuccessToast = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.cloudConnecting);
    }
    await currentService.authenticate().then((value) async {
      setState(() {
        currentConfig.connected = (value == CloudServiceStatus.success);
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
        _huaweiCloudCloudServiceConfig!.configured = true;
        updateConfig(_huaweiCloudCloudServiceConfig!);
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
      title: S.current.enable + S.current.cloudTypeHuaweiCloud,
      topRadius: true,
      bottomRadius: true,
      value: _huaweiCloudCloudServiceConfig?.enabled ?? false,
      onTap: () {
        setState(() {
          _huaweiCloudCloudServiceConfig!.enabled =
          !_huaweiCloudCloudServiceConfig!.enabled;
          CloudServiceConfigDao.updateConfigEnabled(
              _huaweiCloudCloudServiceConfig!, _huaweiCloudCloudServiceConfig!.enabled);
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
            text: S.current.webDavSignin,
            background: Theme.of(context).primaryColor,
            fontSizeDelta: 2,
            onTap: () async {
              try {
                ping();
              } catch (e) {
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
            text: S.current.webDavPullBackup,
            padding: const EdgeInsets.symmetric(vertical: 12),
            outline: Theme.of(context).primaryColor,
            color: Theme.of(context).primaryColor,
            fontSizeDelta: 2,
            onTap: () async {
              CustomLoadingDialog.showLoading(title: S.current.webDavPulling);
              try {
                List<HuaweiCloudFileInfo>? files =
                await _huaweiCloudCloudService!.listBackups();
                if (files == null) {
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(S.current.webDavPullFailed);
                  return;
                }
                CloudServiceConfigDao.updateLastPullTime(
                    _huaweiCloudCloudServiceConfig!);
                CustomLoadingDialog.dismissLoading();
                files.sort((a, b) =>
                    b.lastModifiedDateTime.compareTo(a.lastModifiedDateTime));
                if (files.isNotEmpty) {
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    responsive: true,
                        (dialogContext) => HuaweiCloudBackupsBottomSheet(
                      files: files,
                      cloudService: _huaweiCloudCloudService!,
                      onSelected: (selectedFile) async {
                        var dialog = showProgressDialog(
                          msg: S.current.webDavPulling,
                          showProgress: true,
                        );
                        Uint8List? res =
                        await _huaweiCloudCloudService!.downloadFile(
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
                  IToast.show(S.current.webDavNoBackupFile);
                }
              } catch (e) {
                CustomLoadingDialog.dismissLoading();
                IToast.show(S.current.webDavPullFailed);
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
            text: S.current.webDavPushBackup,
            fontSizeDelta: 2,
            onTap: () async {
              ExportTokenUtil.backupEncryptToCloud(
                config: _huaweiCloudCloudServiceConfig!,
                cloudService: _huaweiCloudCloudService!,
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
            text: S.current.webDavLogout,
            fontSizeDelta: 2,
            onTap: () async {
              await _huaweiCloudCloudService!.signOut();
              setState(() {
                _huaweiCloudCloudServiceConfig!.connected = false;
                _huaweiCloudCloudServiceConfig!.account = "";
                _huaweiCloudCloudServiceConfig!.totalSize =
                    _huaweiCloudCloudServiceConfig!.remainingSize =
                    _huaweiCloudCloudServiceConfig!.usedSize = -1;
                updateConfig(_huaweiCloudCloudServiceConfig!);
              });
            },
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
