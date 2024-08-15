import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/onedrive_cloud_service.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
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
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  CloudServiceConfig? _oneDriveCloudServiceConfig;
  OneDriveCloudService? _oneDriveCloudService;

  CloudServiceConfig get currentConfig => _oneDriveCloudServiceConfig!;

  CloudService get currentService => _oneDriveCloudService!;

  bool get _configInitialized {
    return _oneDriveCloudServiceConfig != null;
  }

  @override
  void initState() {
    super.initState();
    loadConfig();
    initFields();
  }

  loadConfig() async {
    _oneDriveCloudServiceConfig =
        await CloudServiceConfigDao.getOneDriveConfig();
    if (_oneDriveCloudServiceConfig != null) {
      _endpointController.text = _oneDriveCloudServiceConfig!.endpoint ?? "";
      _accountController.text = _oneDriveCloudServiceConfig!.account ?? "";
      if (_oneDriveCloudServiceConfig!.isValid) {
        _oneDriveCloudService =
            OneDriveCloudService(context, _oneDriveCloudServiceConfig!);
      }
    } else {
      _oneDriveCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.OneDrive);
      await CloudServiceConfigDao.insertConfig(_oneDriveCloudServiceConfig!);
      _oneDriveCloudService =
          OneDriveCloudService(context, _oneDriveCloudServiceConfig!);
    }
    setState(() {});
  }

  initFields() {
    _endpointController.addListener(() {
      _oneDriveCloudServiceConfig!.endpoint = _endpointController.text;
    });
    _accountController.addListener(() {
      _oneDriveCloudServiceConfig!.account = _accountController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildBody();
  }

  ping({
    bool showLoading = true,
    bool showSuccessToast = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.webDavConnecting);
    }
    await currentService.authenticate().then((value) {
      setState(() {
        currentConfig.connected = value == CloudServiceStatus.success;
      });
      if (!currentConfig.connected) {
        switch (value) {
          case CloudServiceStatus.connectionError:
            IToast.show(S.current.webDavConnectionError);
            break;
          case CloudServiceStatus.unauthorized:
            IToast.show(S.current.webDavUnauthorized);
            break;
          default:
            IToast.show(S.current.webDavUnknownError);
            break;
        }
      } else {
        if (showSuccessToast) IToast.show(S.current.webDavAuthSuccess);
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
      title: S.current.enable,
      topRadius: true,
      bottomRadius: true,
      value: _oneDriveCloudServiceConfig?.enabled ?? false,
      onTap: () {
        setState(() {
          _oneDriveCloudServiceConfig!.enabled =
              !_oneDriveCloudServiceConfig!.enabled;
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
            controller: _endpointController,
            textInputAction: TextInputAction.next,
            leadingText: S.current.webDavServer,
            leadingType: InputItemLeadingType.text,
            topRadius: true,
            disabled: true,
            hint: S.current.webDavServerHint,
          ),
          InputItem(
            controller: _accountController,
            textInputAction: TextInputAction.next,
            leadingType: InputItemLeadingType.text,
            disabled: true,
            leadingText: S.current.webDavUsername,
            hint: S.current.webDavUsernameHint,
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
            onTap: () async {
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
              await _oneDriveCloudService!.signOut();
              setState(() {
                _oneDriveCloudServiceConfig!.connected = false;
                _oneDriveCloudService = null;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
