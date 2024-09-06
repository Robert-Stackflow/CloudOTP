import 'dart:math';

import 'package:cloudotp/Resources/theme.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:window_manager/window_manager.dart';

import '../../Database/database_manager.dart';
import '../../Utils/biometric_util.dart';
import '../../Utils/constant.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/uri_util.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';
import '../main_screen.dart';

class DatabaseDecryptScreen extends StatefulWidget {
  const DatabaseDecryptScreen({super.key});

  @override
  DatabaseDecryptScreenState createState() => DatabaseDecryptScreenState();
}

class DatabaseDecryptScreenState extends State<DatabaseDecryptScreen>
    with WindowListener {
  final FocusNode _focusNode = FocusNode();
  late InputValidateAsyncController validateAsyncController;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isMaximized = false;
  bool _isStayOnTop = false;
  bool _biometricAvailable = false;
  final bool _enableDatabaseBiometric = HiveUtil.getBool(
      HiveUtil.enableDatabaseBiometricKey,
      defaultValue: false);

  auth() async {
    String? password = await BiometricUtil.getDatabasePassword();
    if (password != null && password.isNotEmpty) {
      validateAsyncController.controller.text = password;
      onSubmit();
    }
  }

  initBiometricAuthentication() async {
    LocalAuthentication localAuth = LocalAuthentication();
    bool available = await localAuth.canCheckBiometrics;
    setState(() {
      _biometricAvailable = available;
    });
    if (_biometricAvailable && _enableDatabaseBiometric) {
      auth();
    }
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  Future<void> onWindowResized() async {
    super.onWindowResized();
    HiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowMoved() async {
    super.onWindowMoved();
    HiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  void dispose() {
    super.dispose();
    windowManager.removeListener(this);
  }

  @override
  void initState() {
    super.initState();
    initBiometricAuthentication();
    windowManager.addListener(this);
    Future.delayed(const Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
    validateAsyncController = InputValidateAsyncController(
      listen: false,
      validator: (text) async {
        if (text.isNotEmpty) {
          try {
            await DatabaseManager.initDataBase(text);
            if (DatabaseManager.initialized) {
              return null;
            }
          } catch (e, t) {
            ILogger.error(
                "Failed to decrypt database with wrong password", e, t);
            return S.current.encryptDatabasePasswordWrong;
          }
        }
        return null;
      },
      controller: TextEditingController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      backgroundColor: MyTheme.getBackground(context),
      appBar: ResponsiveUtil.isDesktop()
          ? PreferredSize(
              preferredSize: const Size(0, 86),
              child: ItemBuilder.buildWindowTitle(
                context,
                forceClose: true,
                backgroundColor: MyTheme.getBackground(context),
                isStayOnTop: _isStayOnTop,
                isMaximized: _isMaximized,
                onStayOnTopTap: () {
                  setState(() {
                    _isStayOnTop = !_isStayOnTop;
                    windowManager.setAlwaysOnTop(_isStayOnTop);
                  });
                },
              ),
            )
          : null,
      bottomNavigationBar: Container(
        height: 86,
        color: MyTheme.getBackground(context),
      ),
      body: SafeArea(
        right: false,
        child: Center(
          child:
              DatabaseManager.lib != null ? _buildBody() : _buildFailedBody(),
        ),
      ),
    );
  }

  onSubmit() async {
    CustomLoadingDialog.showLoading(
        title: S.current.decryptingDatabasePassword);
    String? error = await validateAsyncController.validate();
    bool isValidAsync = (error == null);
    CustomLoadingDialog.dismissLoading();
    if (isValidAsync) {
      if (DatabaseManager.initialized) {
        Navigator.of(context).pushReplacement(RouteUtil.getFadeRoute(
            ItemBuilder.buildContextMenuOverlay(const MainScreen())));
      }
    } else {
      _focusNode.requestFocus();
    }
  }

  _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Text(S.current.decryptDatabasePassword,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 30),
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Form(
            key: formKey,
            child: InputItem(
              validator: (value) {
                if (value.isEmpty) {
                  return S.current.encryptDatabasePasswordCannotBeEmpty;
                }
                return null;
              },
              validateAsyncController: validateAsyncController,
              focusNode: _focusNode,
              maxLines: 1,
              obscureText: true,
              onSubmit: (_) => onSubmit(),
              textInputAction: TextInputAction.done,
              backgroundColor: Colors.transparent,
              tailingType: InputItemTailingType.password,
              leadingType: InputItemLeadingType.none,
              hint: S.current.inputEncryptDatabasePassword,
              topRadius: true,
              bottomRadius: true,
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetter,
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        ItemBuilder.buildRoundButton(
          context,
          text: S.current.confirm,
          fontSizeDelta: 2,
          background: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
          onTap: onSubmit,
        ),
        const Spacer(),
        ItemBuilder.buildClickItem(
          clickable: _biometricAvailable && _enableDatabaseBiometric,
          GestureDetector(
            onTap: _biometricAvailable && _enableDatabaseBiometric
                ? () {
                    auth();
                  }
                : null,
            child: Text(
              _biometricAvailable && _enableDatabaseBiometric
                  ? S.current.biometric
                  : "",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  _buildFailedBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IgnorePointer(
          child: Text(
            S.current.loadSqlcipherFailed,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 30),
        IgnorePointer(
          child: SizedBox(
            width: min(MediaQuery.sizeOf(context).width - 40, 500),
            child: Text(
              S.current.loadSqlcipherFailedMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 30),
        ItemBuilder.buildRoundButton(
          context,
          text: S.current.loadSqlcipherFailedLearnMore,
          fontSizeDelta: 2,
          background: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
          onTap: () {
            UriUtil.launchUrlUri(context, sqlcipherLearnMore);
          },
        ),
      ],
    );
  }
}
