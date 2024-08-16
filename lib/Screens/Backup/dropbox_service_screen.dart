import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/dropbox_cloud_service.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
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
    loadConfig();
  }

  loadConfig() async {
    _dropboxCloudServiceConfig =
    await CloudServiceConfigDao.getDropboxConfig();
    if (_dropboxCloudServiceConfig != null) {
      _sizeController.text = _dropboxCloudServiceConfig!.size;
      _accountController.text = _dropboxCloudServiceConfig!.account ?? "";
      if (_dropboxCloudServiceConfig!.isValid) {
        _dropboxCloudService = DropboxCloudService(
          context,
          _dropboxCloudServiceConfig!,
          onConfigChanged: updateConfig,
        );
      }
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
      _dropboxCloudServiceConfig!.connected =
      await _dropboxCloudService!.isConnected();
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
    );
  }

  _buildUnsupportBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
    await currentService.authenticate().then((value) {
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
            leadingText: S.current.webDavUsername,
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
              ping();
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
            onTap: () async {},
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
              await _dropboxCloudService!.fetchInfo();
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
