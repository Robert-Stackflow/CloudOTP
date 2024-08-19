import 'dart:typed_data';

import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropbox/dropbox_response.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/dropbox_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/dropbox_backups_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/progress_dialog.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

class DropboxServiceScreen extends StatefulWidget {
  const DropboxServiceScreen({
    super.key,
  });

  static const String routeName = "/service/dropbox";

  @override
  State<DropboxServiceScreen> createState() => _DropboxServiceScreenState();
}

class _DropboxServiceScreenState extends State<DropboxServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  CloudServiceConfig? _dropboxCloudServiceConfig;
  DropboxCloudService? _dropboxCloudService;
  bool inited = false;

  CloudServiceConfig get currentConfig => _dropboxCloudServiceConfig!;

  CloudService get currentService => _dropboxCloudService!;

  bool get _configInitialized {
    return _dropboxCloudServiceConfig != null;
  }

  @override
  void initState() {
    super.initState();
    if (!ResponsiveUtil.isDesktop()) loadConfig();
  }

  loadConfig() async {
    _dropboxCloudServiceConfig = await CloudServiceConfigDao.getDropboxConfig();
    if (_dropboxCloudServiceConfig != null) {
      _sizeController.text = _dropboxCloudServiceConfig!.size;
      _accountController.text = _dropboxCloudServiceConfig!.account ?? "";
      _emailController.text = _dropboxCloudServiceConfig!.email ?? "";
      _dropboxCloudService = DropboxCloudService(
        context,
        _dropboxCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    } else {
      _dropboxCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.Dropbox);
      await CloudServiceConfigDao.insertConfig(_dropboxCloudServiceConfig!);
      _dropboxCloudService = DropboxCloudService(
        context,
        _dropboxCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    }
    if (_dropboxCloudService != null) {
      _dropboxCloudServiceConfig!.configured = _dropboxCloudServiceConfig!
          .connected = await _dropboxCloudService!.isConnected();
      if (!_dropboxCloudServiceConfig!.connected) {
        IToast.showTop(S.current.cloudConnectionError);
      }
      updateConfig(_dropboxCloudServiceConfig!);
    }
    inited = true;
    setState(() {});
  }

  updateConfig(CloudServiceConfig config) {
    setState(() {
      _dropboxCloudServiceConfig = config;
    });
    _sizeController.text = _dropboxCloudServiceConfig!.size;
    _accountController.text = _dropboxCloudServiceConfig!.account ?? "";
    _emailController.text = _dropboxCloudServiceConfig!.email ?? "";
    CloudServiceConfigDao.updateConfig(_dropboxCloudServiceConfig!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ResponsiveUtil.isDesktop()
        ? _buildUnsupportBody()
        : inited
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
          Text(S.current.cloudTypeNotSupport(S.current.cloudTypeDropbox)),
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
        _dropboxCloudServiceConfig!.configured = true;
        updateConfig(_dropboxCloudServiceConfig!);
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
        if (_configInitialized) _accountInfo(),
        const SizedBox(height: 30),
        if (_configInitialized && !currentConfig.connected) _loginButton(),
        if (_configInitialized && currentConfig.connected) _operationButtons(),
      ],
    );
  }

  _enableInfo() {
    return ItemBuilder.buildRadioItem(
      context: context,
      title: S.current.enable + S.current.cloudTypeDropbox,
      topRadius: true,
      bottomRadius: true,
      value: _dropboxCloudServiceConfig?.enabled ?? false,
      onTap: () {
        setState(() {
          _dropboxCloudServiceConfig!.enabled =
              !_dropboxCloudServiceConfig!.enabled;
          CloudServiceConfigDao.updateConfigEnabled(
              _dropboxCloudServiceConfig!, _dropboxCloudServiceConfig!.enabled);
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
                List<DropboxFileInfo>? files =
                    await _dropboxCloudService!.listBackups();
                if (files == null) {
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(S.current.webDavPullFailed);
                  return;
                }
                CloudServiceConfigDao.updateLastPullTime(
                    _dropboxCloudServiceConfig!);
                CustomLoadingDialog.dismissLoading();
                files.sort((a, b) =>
                    b.lastModifiedDateTime.compareTo(a.lastModifiedDateTime));
                if (files.isNotEmpty) {
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    responsive: true,
                    (dialogContext) => DropboxBackupsBottomSheet(
                      files: files,
                      cloudService: _dropboxCloudService!,
                      onSelected: (selectedFile) async {
                        var dialog = showProgressDialog(
                          msg: S.current.webDavPulling,
                          showProgress: true,
                        );
                        Uint8List? res =
                            await _dropboxCloudService!.downloadFile(
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
                config: _dropboxCloudServiceConfig!,
                cloudService: _dropboxCloudService!,
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
              await _dropboxCloudService!.signOut();
              setState(() {
                _dropboxCloudServiceConfig!.connected = false;
                _dropboxCloudServiceConfig!.account = "";
                _dropboxCloudServiceConfig!.email = "";
                _dropboxCloudServiceConfig!.totalSize =
                    _dropboxCloudServiceConfig!.remainingSize =
                        _dropboxCloudServiceConfig!.usedSize = -1;
                updateConfig(_dropboxCloudServiceConfig!);
              });
            },
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
