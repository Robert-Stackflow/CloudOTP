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

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:cloudotp/Utils/constant.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../Utils/biometric_util.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/lottie_util.dart';
import '../../Utils/shortcuts_util.dart';
import '../../l10n/l10n.dart';

class PinVerifyScreen extends StatefulWidget {
  const PinVerifyScreen({
    super.key,
    this.onSuccess,
    this.isModal = true,
    this.autoAuth = true,
    this.jumpToMain = false,
    this.showWindowTitle = false,
  });

  final bool isModal;
  final bool autoAuth;
  final bool jumpToMain;
  final bool showWindowTitle;
  final Function()? onSuccess;
  static const String routeName = "/pin/verify";

  @override
  PinVerifyScreenState createState() => PinVerifyScreenState();
}

class PinVerifyScreenState extends BaseWindowState<PinVerifyScreen>
    with TrayListener {
  static const int _maxFailedAttempts = 5;

  @override
  Future<void> onWindowClose() async {
    exit(0);
  }

  static const int _lockoutDurationSeconds = 30;
  static const int _extendedLockoutDurationSeconds = 300;
  static const int _extendedLockoutThreshold = 10;

  late final bool _enableBiometric =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableBiometricKey);
  final bool _hideGestureTrail = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.hideGestureTrailKey,
      defaultValue: false);
  late final GestureNotifier _notifier = GestureNotifier(
      status: GestureStatus.verify,
      gestureText: appLocalizations.verifyGestureLock);
  final GlobalKey<GestureState> _gestureUnlockView = GlobalKey();
  String? canAuthenticateResponseString;
  CanAuthenticateResponse? canAuthenticateResponse;
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  Timer? _lockoutTimer;
  int _lockoutRemaining = 0;

  void _restoreLockoutState() {
    _failedAttempts = ChewieHiveUtil.getInt(
        CloudOTPHiveUtil.gestureFailedAttemptsKey,
        defaultValue: 0);
    final lockoutEnd = ChewieHiveUtil.getInt(
        CloudOTPHiveUtil.gestureLockoutEndKey,
        defaultValue: 0);
    if (lockoutEnd > 0) {
      final remaining =
          (lockoutEnd - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
      if (remaining > 0) {
        _lockoutRemaining = remaining;
        _isLockedOut = true;
        _lockoutTimer?.cancel();
        _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _lockoutRemaining--;
            if (_lockoutRemaining <= 0) {
              _isLockedOut = false;
              timer.cancel();
              ChewieHiveUtil.put(CloudOTPHiveUtil.gestureLockoutEndKey, 0);
              _notifier.setStatus(
                status: GestureStatus.verify,
                gestureText: appLocalizations.verifyGestureLock,
              );
            } else {
              _notifier.setStatus(
                status: GestureStatus.verifyFailedCountOverflow,
                gestureText:
                    '${appLocalizations.gestureLockWrong} (${_lockoutRemaining}s)',
              );
            }
          });
        });
      } else {
        ChewieHiveUtil.put(CloudOTPHiveUtil.gestureLockoutEndKey, 0);
      }
    }
  }

  bool get _biometricAvailable => canAuthenticateResponse?.isSuccess ?? false;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }

  @override
  void initState() {
    if (widget.isModal) {
      trayManager.addListener(this);
      Utils.initSimpleTray();
    }
    windowManager.addListener(this);
    super.initState();
    if (ResponsiveUtil.isMacOS()) {
      WidgetsBinding.instance.platformMenuDelegate.setMenus([]);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        chewieProvider.loadingWidgetBuilder = (size, forceDark) =>
            LottieFiles.load(
                LottieFiles.getLoadingPath(chewieProvider.rootContext),
                scale: 1.5,
                delegates:
                    LottieFiles.loadingDelegates(ChewieTheme.primaryColor));
      }
    });
    _restoreLockoutState();
    initBiometricAuthentication();
  }

  initBiometricAuthentication() async {
    canAuthenticateResponse = await BiometricUtil.canAuthenticate();
    canAuthenticateResponseString =
        await BiometricUtil.getCanAuthenticateResponseString();
    setState(() {});
    if (_biometricAvailable && _enableBiometric && widget.autoAuth) {
      localAuth();
    }
  }

  void localAuth() async {
    if (ResponsiveUtil.isIOS()) {
      if (await BiometricUtil.authenticateIOS() && mounted) success();
    } else {
      ChewieUtils.localAuth(onAuthed: success);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtil.isMacOS()) {
      WidgetsBinding.instance.platformMenuDelegate.setMenus([]);
    }
    chewieProvider.resetRootContext();
    ChewieUtils.setSafeMode(ChewieHiveUtil.getBool(
        CloudOTPHiveUtil.enableSafeModeKey,
        defaultValue: defaultEnableSafeMode));
    Widget body = Stack(
      children: [
        Scaffold(
          backgroundColor: ChewieTheme.scaffoldBackgroundColor,
          appBar: ResponsiveUtil.isDesktop() && widget.showWindowTitle
              ? ResponsiveAppBar(
                  title: appLocalizations.verifyGestureLock,
                  showBack: false,
                  titleLeftMargin:
                      ResponsiveUtil.isMacOS() ? macosTitleBarLeftMargin : 15,
                  actions: const [
                    BlankIconButton(),
                  ],
                )
              : !widget.isModal
                  ? ResponsiveAppBar(
                      showBack: true,
                      onTapBack: () => Navigator.pop(context),
                      showBorder: false,
                    )
                  : null,
          bottomNavigationBar: widget.showWindowTitle
              ? Container(
                  height: 86,
                  color: ChewieTheme.scaffoldBackgroundColor,
                )
              : null,
          body: SafeArea(
            right: false,
            child: Center(
              child: PopScope(
                canPop: !widget.isModal,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      _notifier.gestureText,
                      style: ChewieTheme.titleMedium,
                    ),
                    const SizedBox(height: 30),
                    Semantics(
                      label: appLocalizations.verifyGestureLock,
                      child: GestureUnlockView(
                        key: _gestureUnlockView,
                        size: min(MediaQuery.sizeOf(context).width, 400),
                        padding: 60,
                        roundSpace: 40,
                        defaultColor: Colors.grey.withOpacity(0.5),
                        selectedColor: ChewieTheme.primaryColor,
                        failedColor: Colors.redAccent,
                        disableColor: Colors.grey,
                        solidRadiusRatio: 0.3,
                        lineWidth: 2,
                        touchRadiusRatio: 0.3,
                        showLine: !_hideGestureTrail,
                        onCompleted: _gestureComplete,
                      ),
                    ),
                    Visibility(
                      visible: _biometricAvailable && _enableBiometric,
                      child: RoundIconTextButton(
                        text: ResponsiveUtil.isWindows()
                            ? appLocalizations.biometricVerifyPin
                            : appLocalizations.biometric,
                        onPressed: localAuth,
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (ResponsiveUtil.isDesktop() && widget.showWindowTitle)
          Positioned(
            top: 0,
            right: 0,
            child: WindowTitleWrapper(
              height: 48,
              forceClose: true,
              backgroundColor: Colors.transparent,
              isStayOnTop: isStayOnTop,
              isMaximized: isMaximized,
              onStayOnTopTap: () {
                setState(() {
                  isStayOnTop = !isStayOnTop;
                  windowManager.setAlwaysOnTop(isStayOnTop);
                });
              },
            ),
          ),
      ],
    );
    return body;
  }

  void _startLockout() {
    final duration = _failedAttempts >= _extendedLockoutThreshold
        ? _extendedLockoutDurationSeconds
        : _lockoutDurationSeconds;
    _isLockedOut = true;
    _lockoutRemaining = duration;
    ChewieHiveUtil.put(CloudOTPHiveUtil.gestureLockoutEndKey,
        DateTime.now().millisecondsSinceEpoch + duration * 1000);
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _lockoutRemaining--;
        if (_lockoutRemaining <= 0) {
          _isLockedOut = false;
          timer.cancel();
          ChewieHiveUtil.put(CloudOTPHiveUtil.gestureLockoutEndKey, 0);
          _notifier.setStatus(
            status: GestureStatus.verify,
            gestureText: appLocalizations.verifyGestureLock,
          );
        } else {
          _notifier.setStatus(
            status: GestureStatus.verifyFailedCountOverflow,
            gestureText:
                '${appLocalizations.gestureLockWrong} (${_lockoutRemaining}s)',
          );
        }
      });
    });
    setState(() {
      _notifier.setStatus(
        status: GestureStatus.verifyFailedCountOverflow,
        gestureText:
            '${appLocalizations.gestureLockWrong} (${_lockoutRemaining}s)',
      );
    });
  }

  success() {
    _failedAttempts = 0;
    ChewieHiveUtil.put(CloudOTPHiveUtil.gestureFailedAttemptsKey, 0);
    ChewieHiveUtil.put(CloudOTPHiveUtil.gestureLockoutEndKey, 0);
    if (widget.onSuccess != null) widget.onSuccess!();
    if (widget.jumpToMain) {
      ShortcutsUtil.jumpToMain();
    } else {
      Navigator.of(context).pop();
    }
    Utils.initTray();
    _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
  }

  void _gestureComplete(List<int> selected, UnlockStatus status) async {
    if (_isLockedOut) return;
    switch (_notifier.status) {
      case GestureStatus.verify:
      case GestureStatus.verifyFailed:
        String password = GestureUnlockView.selectedToString(selected);
        if (CloudOTPHiveUtil.verifyGesturePassword(password)) {
          success();
        } else {
          _failedAttempts++;
          ChewieHiveUtil.put(
              CloudOTPHiveUtil.gestureFailedAttemptsKey, _failedAttempts);
          if (_failedAttempts >= _maxFailedAttempts) {
            _startLockout();
          } else {
            final remaining = _maxFailedAttempts - _failedAttempts;
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verifyFailed,
                gestureText:
                    '${appLocalizations.gestureLockWrong} ($remaining)',
              );
            });
          }
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
        }
        break;
      case GestureStatus.verifyFailedCountOverflow:
      case GestureStatus.create:
      case GestureStatus.createFailed:
        break;
    }
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
