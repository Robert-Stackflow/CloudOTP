import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/googledrive_cloud_service.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

class GoogleDriveServiceScreen extends StatefulWidget {
  const GoogleDriveServiceScreen({
    super.key,
  });

  static const String routeName = "/service/googledrive";

  @override
  State<GoogleDriveServiceScreen> createState() => _GoogleDriveServiceScreenState();
}

class _GoogleDriveServiceScreenState extends State<GoogleDriveServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  CloudServiceConfig? _googleDriveCloudServiceConfig;
  GoogleDriveCloudService? _googleDriveCloudService;
  bool inited = false;

  CloudServiceConfig get currentConfig => _googleDriveCloudServiceConfig!;

  CloudService get currentService => _googleDriveCloudService!;

  bool get _configInitialized {
    return _googleDriveCloudServiceConfig != null;
  }

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  loadConfig() async {
    _googleDriveCloudServiceConfig =
    await CloudServiceConfigDao.getGoogleDriveConfig();
    if (_googleDriveCloudServiceConfig != null) {
      _sizeController.text = _googleDriveCloudServiceConfig!.size;
      _accountController.text = _googleDriveCloudServiceConfig!.account ?? "";
      if (_googleDriveCloudServiceConfig!.isValid) {
        _googleDriveCloudService = GoogleDriveCloudService(
          context,
          _googleDriveCloudServiceConfig!,
          onConfigChanged: updateConfig,
        );
      }
    } else {
      _googleDriveCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.GoogleDrive);
      await CloudServiceConfigDao.insertConfig(_googleDriveCloudServiceConfig!);
      _googleDriveCloudService = GoogleDriveCloudService(
        context,
        _googleDriveCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    }
    if (_googleDriveCloudService != null) {
      _googleDriveCloudServiceConfig!.connected =
      await _googleDriveCloudService!.isConnected();
    }
    inited = true;
    setState(() {});
  }

  updateConfig(CloudServiceConfig config) {
    setState(() {
      _googleDriveCloudServiceConfig = config;
    });
    _sizeController.text = _googleDriveCloudServiceConfig!.size;
    _accountController.text = _googleDriveCloudServiceConfig!.account ?? "";
    CloudServiceConfigDao.updateConfig(_googleDriveCloudServiceConfig!);
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
          Text(S.current.cloudTypeNotSupport(S.current.cloudTypeGoogleDrive)),
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
      title: S.current.enable + S.current.cloudTypeGoogleDrive,
      topRadius: true,
      bottomRadius: true,
      value: _googleDriveCloudServiceConfig?.enabled ?? false,
      onTap: () {
        setState(() {
          _googleDriveCloudServiceConfig!.enabled =
          !_googleDriveCloudServiceConfig!.enabled;
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
              await _googleDriveCloudService!.fetchInfo();
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
              await _googleDriveCloudService!.signOut();
              setState(() {
                _googleDriveCloudServiceConfig!.connected = false;
                _googleDriveCloudServiceConfig!.account = "";
                _googleDriveCloudServiceConfig!.totalSize =
                    _googleDriveCloudServiceConfig!.remainingSize =
                    _googleDriveCloudServiceConfig!.usedSize = -1;
                updateConfig(_googleDriveCloudServiceConfig!);
              });
            },
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
