import 'dart:math';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:cloudotp/Resources/theme.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../Database/database_manager.dart';
import '../../Utils/app_provider.dart';
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
  bool _isValidated = true;
  final bool _allowDatabaseBiometric =
      HiveUtil.getBool(HiveUtil.allowDatabaseBiometricKey, defaultValue: false);
  String? canAuthenticateResponseString;
  CanAuthenticateResponse? canAuthenticateResponse;

  bool get _biometricAvailable => canAuthenticateResponse?.isSuccess ?? false;

  auth() async {
    try {
      canAuthenticateResponse = await BiometricUtil.canAuthenticate();
      canAuthenticateResponseString =
          await BiometricUtil.getCanAuthenticateResponseString();
      if (canAuthenticateResponse == CanAuthenticateResponse.success) {
        String? password = await BiometricUtil.getDatabasePassword();
        if (password == null) {
          setState(() {
            _isValidated = false;
            HiveUtil.put(HiveUtil.allowDatabaseBiometricKey, false);
          });
          IToast.showTop(S.current.biometricChanged);
          FocusScope.of(context).requestFocus(_focusNode);
        }
        if (password != null && password.isNotEmpty) {
          validateAsyncController.controller.text = password;
          onSubmit();
        }
      } else {
        IToast.showTop(canAuthenticateResponseString ?? "");
      }
    } catch (e, t) {
      ILogger.error("CloudOTP","Failed to authenticate with biometric", e, t);
      if (e is AuthException) {
        switch (e.code) {
          case AuthExceptionCode.userCanceled:
            IToast.showTop(S.current.biometricUserCanceled);
            break;
          case AuthExceptionCode.timeout:
            IToast.showTop(S.current.biometricTimeout);
            break;
          case AuthExceptionCode.unknown:
            IToast.showTop(S.current.biometricLockout);
            break;
          case AuthExceptionCode.canceled:
          default:
            IToast.showTop(S.current.biometricError);
            break;
        }
      } else {
        IToast.showTop(S.current.biometricError);
      }
    }
  }

  initBiometricAuthentication() async {
    canAuthenticateResponse = await BiometricUtil.canAuthenticate();
    canAuthenticateResponseString =
        await BiometricUtil.getCanAuthenticateResponseString();
    setState(() {});
    if (_biometricAvailable && _allowDatabaseBiometric) {
      auth();
    } else {
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  @override
  Future<void> onWindowResize() async {
    super.onWindowResize();
    windowManager.setMinimumSize(minimumSize);
    HiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowResized() async {
    super.onWindowResized();
    HiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowMove() async {
    super.onWindowMove();
    HiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  Future<void> onWindowMoved() async {
    super.onWindowMoved();
    HiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  void onWindowMaximize() {
    windowManager.setMinimumSize(minimumSize);
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    windowManager.setMinimumSize(minimumSize);
    setState(() {
      _isMaximized = false;
    });
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
            ILogger.error("CloudOTP",
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
            ItemBuilder.buildContextMenuOverlay(
                MainScreen(key: mainScreenKey))));
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_biometricAvailable)
              ItemBuilder.buildRoundButton(
                context,
                text: S.current.biometric,
                fontSizeDelta: 2,
                disabled: !(_allowDatabaseBiometric && _isValidated),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                onTap: () => auth(),
              ),
            if (_biometricAvailable) const SizedBox(width: 10),
            ItemBuilder.buildRoundButton(
              context,
              text: S.current.confirm,
              fontSizeDelta: 2,
              background: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
              onTap: onSubmit,
            ),
          ],
        ),
        const Spacer(),
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
