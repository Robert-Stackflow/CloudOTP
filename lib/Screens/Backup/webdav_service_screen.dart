import 'dart:typed_data';

import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/webdav_cloud_service.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

class WebDavServiceScreen extends StatefulWidget {
  const WebDavServiceScreen({
    super.key,
  });

  static const String routeName = "/service/webdav";

  @override
  State<WebDavServiceScreen> createState() => _WebDavServiceScreenState();
}

class _WebDavServiceScreenState extends State<WebDavServiceScreen>
    with TickerProviderStateMixin {
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();
  late final InputStateController _endpointStateController;
  late final InputStateController _secretStateController;
  late final InputStateController _accountStateController;
  CloudServiceConfig? _cloudServiceConfig;
  WebDavCloudService? _webDavCloudService;
  bool connected = false;

  @override
  void initState() {
    super.initState();
    loadConfig();
    RegExp urlRegex = RegExp(
        r"^((((H|h)(T|t)|(F|f))(T|t)(P|p)((S|s)?))\://)?(www.|[a-zA-Z0-9].)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,6}(\:[0-9]{1,5})*(/($|[a-zA-Z0-9\.\,\;\?\'\\\+&amp;%\$#\=~_\-@]+))*");
    _endpointController.addListener(() {
      _cloudServiceConfig!.endpoint = _endpointController.text;
    });
    _accountController.addListener(() {
      _cloudServiceConfig!.account = _accountController.text;
    });
    _secretController.addListener(() {
      _cloudServiceConfig!.secret = _secretController.text;
    });
    _endpointStateController = InputStateController(
      controller: _endpointController,
      validate: (text) {
        if (text.isEmpty) {
          return Future.value(S.current.webDavServerCannotBeEmpty);
        }
        if (!urlRegex.hasMatch(text)) {
          return Future.value(S.current.webDavServerInvalid);
        }
        return Future.value(null);
      },
    );
    _secretStateController = InputStateController(
      controller: _secretController,
      validate: (text) {
        if (text.isEmpty) {
          return Future.value(S.current.webDavPasswordCannotBeEmpty);
        }
        return Future.value(null);
      },
    );
    _accountStateController = InputStateController(
      controller: _accountController,
      validate: (text) {
        if (text.isEmpty) {
          return Future.value(S.current.webDavUsernameCannotBeEmpty);
        }
        return Future.value(null);
      },
    );
  }

  loadConfig() async {
    // https://dav.jianguoyun.com/dav/
    // 2014027378@qq.com
    // a2uk28sqhdijtbet
    _cloudServiceConfig = await CloudServiceConfigDao.getWebdavConfig();
    if (_cloudServiceConfig != null) {
      _endpointController.text = _cloudServiceConfig!.endpoint ?? "";
      _accountController.text = _cloudServiceConfig!.account ?? "";
      _secretController.text = _cloudServiceConfig!.secret ?? "";
      if (Utils.isEmpty(_cloudServiceConfig!.endpoint) ||
          Utils.isEmpty(_cloudServiceConfig!.account) ||
          Utils.isEmpty(_cloudServiceConfig!.secret)) {
        return;
      } else {
        _webDavCloudService = WebDavCloudService(_cloudServiceConfig!);
        ping(showSuccessToast: false);
      }
    } else {
      _cloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.Webdav);
      await CloudServiceConfigDao.insertConfig(_cloudServiceConfig!);
    }
  }

  Future<bool> isValid() async {
    bool issuerValid = await _endpointStateController.isValid();
    bool secretValid = await _secretStateController.isValid();
    bool accountValid = await _accountStateController.isValid();
    return issuerValid && secretValid && accountValid;
  }

  resetState() {
    _endpointStateController.reset();
    _secretStateController.reset();
    _accountStateController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ItemBuilder.buildAppBar(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        forceShowClose: true,
        leading: Icons.close_rounded,
        onLeadingTap: () {
          if (ResponsiveUtil.isLandscape()) {
            dialogNavigatorState?.popPage();
          } else {
            Navigator.pop(context);
          }
        },
        title: Text(
          S.current.webDavSetting,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.apply(fontWeightDelta: 2),
        ),
        center: true,
        actions: [
          ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(
              Icons.info_outline_rounded,
              color: Theme.of(context).iconTheme.color,
            ),
            onTap: () {
              DialogBuilder.showInfoDialog(
                context,
                title: S.current.webDav,
                message: S.current.webDavTip,
                customDialogType: CustomDialogType.normal,
                onTapDismiss: () {},
              );
            },
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: _buildBody(),
    );
  }

  ping({
    bool showLoading = true,
    bool showSuccessToast = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.webDavConnecting);
    }
    await _webDavCloudService!.ping().then((value) {
      setState(() {
        connected = value == CloudServiceStatus.success;
      });
      if (!connected) {
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
    return ListView(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      children: [
        Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 82),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.grey.withOpacity(0.1), width: 0.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/logo.png',
                  height: 80,
                  width: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ItemBuilder.buildContainerItem(
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
                    readOnly: connected,
                    stateController: _endpointStateController,
                    hint: S.current.webDavServerHint,
                    inputFormatters: [
                      RegexInputFormatter.onlyUrl,
                    ],
                  ),
                  InputItem(
                    controller: _accountController,
                    stateController: _accountStateController,
                    textInputAction: TextInputAction.next,
                    leadingType: InputItemLeadingType.text,
                    readOnly: connected,
                    leadingText: S.current.webDavUsername,
                    hint: S.current.webDavUsernameHint,
                  ),
                  InputItem(
                    controller: _secretController,
                    textInputAction: TextInputAction.next,
                    leadingType: InputItemLeadingType.text,
                    leadingText: S.current.webDavPassword,
                    tailingType: InputItemTailingType.password,
                    readOnly: connected,
                    hint: S.current.webDavPasswordHint,
                    inputFormatters: [
                      RegexInputFormatter.onlyNumberAndLetter,
                    ],
                    stateController: _secretStateController,
                    bottomRadius: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (!connected)
              Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: ItemBuilder.buildRoundButton(
                      context,
                      text: S.current.webDavSignin,
                      background: Theme.of(context).primaryColor,
                      fontSizeDelta: 2,
                      onTap: () async {
                        if (await isValid()) {
                          await CloudServiceConfigDao.updateConfig(
                              _cloudServiceConfig!);
                          _webDavCloudService =
                              WebDavCloudService(_cloudServiceConfig!);
                          ping();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            if (connected)
              Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: ItemBuilder.buildFramedButton(
                      context,
                      text: S.current.webDavPullBackup,
                      outline: Theme.of(context).primaryColor,
                      color: Theme.of(context).primaryColor,
                      fontSizeDelta: 2,
                      onTap: () async {
                        CustomLoadingDialog.showLoading(
                            title: S.current.webDavPulling);
                        List<webdav.File> files =
                            await _webDavCloudService!.listFiles();
                        CustomLoadingDialog.dismissLoading();
                        if (files.isNotEmpty) {
                        } else {
                          IToast.show(S.current.webDavNoBackupFile);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ItemBuilder.buildRoundButton(
                      context,
                      background: Theme.of(context).primaryColor,
                      text: S.current.webDavPushBackup,
                      fontSizeDelta: 2,
                      onTap: () async {
                        CustomLoadingDialog.showLoading(
                            title: S.current.backuping);
                        Uint8List? encryptedData =
                            await ExportTokenUtil.getBackupFile();
                        if (encryptedData == null) {
                          IToast.showTop(S.current.backupFailed);
                          return;
                        } else {
                          CustomLoadingDialog.dismissLoading();
                          CustomLoadingDialog.showLoading(
                              title: S.current.webDavPushing);
                          await _webDavCloudService!.uploadFile(
                            ExportTokenUtil.getExportFileName("bin"),
                            encryptedData,
                          );
                          CustomLoadingDialog.dismissLoading();
                          IToast.showTop(S.current.backupSuccess);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ItemBuilder.buildRoundButton(
                      context,
                      background: Colors.red,
                      text: S.current.webDavLogout,
                      fontSizeDelta: 2,
                      onTap: () async {
                        setState(() {
                          connected = false;
                          _webDavCloudService = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
