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

import 'dart:math';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:cloudotp/Utils/shortcuts_util.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../Database/database_manager.dart';
import '../../Utils/biometric_util.dart';
import '../../Utils/constant.dart';
import '../../Utils/hive_util.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import '../../Utils/lottie_util.dart';
import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';

class DatabaseDecryptScreen extends StatefulWidget {
  const DatabaseDecryptScreen({super.key});

  @override
  DatabaseDecryptScreenState createState() => DatabaseDecryptScreenState();
}

class DatabaseDecryptScreenState extends BaseDynamicState<DatabaseDecryptScreen>
    with WindowListener, TrayListener {
  final FocusNode _focusNode = FocusNode();
  late InputValidateAsyncController validateAsyncController;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isMaximized = false;
  bool _isStayOnTop = false;
  bool _isValidated = true;
  final bool _allowDatabaseBiometric = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.allowDatabaseBiometricKey,
      defaultValue: false);
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
            ChewieHiveUtil.put(
                CloudOTPHiveUtil.allowDatabaseBiometricKey, false);
          });
          IToast.showTop(appLocalizations.biometricChanged);
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
      ILogger.error("Failed to authenticate with biometric", e, t);
      if (e is AuthException) {
        switch (e.code) {
          case AuthExceptionCode.userCanceled:
            IToast.showTop(appLocalizations.biometricUserCanceled);
            break;
          case AuthExceptionCode.timeout:
            IToast.showTop(appLocalizations.biometricTimeout);
            break;
          case AuthExceptionCode.unknown:
            IToast.showTop(appLocalizations.biometricLockout);
            break;
          case AuthExceptionCode.canceled:
          default:
            IToast.showTop(appLocalizations.biometricError);
            break;
        }
      } else {
        IToast.showTop(appLocalizations.biometricError);
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
    }
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Future<void> onWindowResize() async {
    super.onWindowResize();
    windowManager.setMinimumSize(ChewieProvider.minimumWindowSize);
    ChewieHiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowResized() async {
    super.onWindowResized();
    ChewieHiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowMove() async {
    super.onWindowMove();
    ChewieHiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  Future<void> onWindowMoved() async {
    super.onWindowMoved();
    ChewieHiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  void onWindowMaximize() {
    windowManager.setMinimumSize(ChewieProvider.minimumWindowSize);
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    windowManager.setMinimumSize(ChewieProvider.minimumWindowSize);
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }

  @override
  void initState() {
    super.initState();
    chewieProvider.loadingWidgetBuilder = (size, forceDark) => LottieFiles.load(
        LottieFiles.getLoadingPath(chewieProvider.rootContext),
        scale: 1.5);
    initBiometricAuthentication();
    trayManager.addListener(this);
    windowManager.addListener(this);
    Utils.initSimpleTray();
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
            return appLocalizations.encryptDatabasePasswordWrong;
          }
        }
        return null;
      },
      controller: TextEditingController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    chewieProvider.rootContext = context;
    ChewieUtils.setSafeMode(ChewieHiveUtil.getBool(
        CloudOTPHiveUtil.enableSafeModeKey,
        defaultValue: defaultEnableSafeMode));
    return Stack(
      children: [
        MyScaffold(
          backgroundColor: ChewieTheme.scaffoldBackgroundColor,
          appBar: ResponsiveUtil.isDesktop()
              ? ResponsiveAppBar(
                  title: appLocalizations.appName,
                  showBack: false,
                  titleLeftMargin: 15,
                  actions: const [
                    BlankIconButton(),
                  ],
                )
              : null,
          bottomNavigationBar: Container(
            height: 86,
            color: ChewieTheme.scaffoldBackgroundColor,
          ),
          body: SafeArea(
            right: false,
            child: Center(
              child: DatabaseManager.lib != null
                  ? _buildBody()
                  : _buildFailedBody(),
            ),
          ),
        ),
        if (ResponsiveUtil.isDesktop())
          Positioned(
            top: 0,
            right: 0,
            child: WindowTitleWrapper(
              height: 48,
              forceClose: true,
              backgroundColor: Colors.transparent,
              isStayOnTop: _isStayOnTop,
              isMaximized: _isMaximized,
              onStayOnTopTap: () {
                setState(() {
                  _isStayOnTop = !_isStayOnTop;
                  windowManager.setAlwaysOnTop(_isStayOnTop);
                });
              },
            ),
          ),
      ],
    );
  }

  onSubmit() async {
    CustomLoadingDialog.showLoading(
        title: appLocalizations.decryptingDatabasePassword);
    String? error = await validateAsyncController.validate();
    bool isValidAsync = (error == null);
    CustomLoadingDialog.dismissLoading();
    if (isValidAsync) {
      if (DatabaseManager.initialized) {
        ShortcutsUtil.jumpToMain();
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
        Text(appLocalizations.decryptDatabasePassword,
            style: ChewieTheme.titleLarge),
        const SizedBox(height: 30),
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: 18,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: ChewieTheme.canvasColor,
            borderRadius: ChewieDimens.borderRadius8,
          ),
          child: Form(
            key: formKey,
            child: InputItem(
              validator: (value) {
                if (value.isEmpty) {
                  return appLocalizations.encryptDatabasePasswordCannotBeEmpty;
                }
                return null;
              },
              validateAsyncController: validateAsyncController,
              focusNode: _focusNode,
              style: InputItemStyle(
                obscure: true,
                maxLines: 1,
              ),
              onSubmit: (_) => onSubmit(),
              textInputAction: TextInputAction.done,
              tailingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.password,
              ),
              hint: appLocalizations.inputEncryptDatabasePassword,
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetterAndSymbol,
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_biometricAvailable)
              RoundIconTextButton(
                text: appLocalizations.biometric,
                fontSizeDelta: 2,
                disabled: !(_allowDatabaseBiometric && _isValidated),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                onPressed: () => auth(),
              ),
            if (_biometricAvailable) const SizedBox(width: 10),
            RoundIconTextButton(
              text: appLocalizations.confirm,
              fontSizeDelta: 2,
              background: ChewieTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
              onPressed: onSubmit,
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
            appLocalizations.loadSqlcipherFailed,
            textAlign: TextAlign.center,
            style: ChewieTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 30),
        IgnorePointer(
          child: SizedBox(
            width: min(MediaQuery.sizeOf(context).width - 40, 500),
            child: Text(
              appLocalizations.loadSqlcipherFailedMessage,
              textAlign: TextAlign.center,
              style: ChewieTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 30),
        RoundIconTextButton(
          text: appLocalizations.loadSqlcipherFailedLearnMore,
          fontSizeDelta: 2,
          height: 48,
          background: ChewieTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
          onPressed: () {
            UriUtil.launchUrlUri(context, sqlcipherLearnMore);
          },
        ),
      ],
    );
  }

  @override
  void onTrayIconMouseDown() {
    ChewieUtils.displayApp();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    Utils.processTrayMenuItemClick(context, menuItem, true);
  }
}
