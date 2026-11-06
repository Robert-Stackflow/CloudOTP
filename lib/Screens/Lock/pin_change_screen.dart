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
import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/material.dart';

import '../../Utils/biometric_util.dart';
import '../../Utils/hive_util.dart';
import '../../l10n/l10n.dart';

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  static const String routeName = "/pin/change";

  @override
  PinChangeScreenState createState() => PinChangeScreenState();
}

class PinChangeScreenState extends BaseDynamicState<PinChangeScreen> {
  static const int _maxVerifyAttempts = 5;
  static const int _verifyLockoutSeconds = 60;
  int _verifyFailedAttempts = 0;
  bool _verifyLockedOut = false;
  Timer? _verifyLockoutTimer;
  int _verifyLockoutRemaining = 0;

  String _gesturePassword = "";
  bool _isEditMode =
      ChewieHiveUtil.getString(CloudOTPHiveUtil.guesturePasswdKey)
          .notNullOrEmpty;
  late final int _totalSteps = _isEditMode ? 3 : 2;
  int _currentStep = 1;
  late final bool _enableBiometric =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableBiometricKey);
  final bool _hideGestureTrail = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.hideGestureTrailKey,
      defaultValue: false);
  late final GestureNotifier _notifier = _isEditMode
      ? GestureNotifier(
          status: GestureStatus.verify,
          gestureText: appLocalizations.drawOldGestureLock)
      : GestureNotifier(
          status: GestureStatus.create,
          gestureText: appLocalizations.drawNewGestureLock);
  final GlobalKey<GestureState> _gestureUnlockView = GlobalKey();
  final GlobalKey<GestureUnlockIndicatorState> _indicator = GlobalKey();

  String? canAuthenticateResponseString;
  CanAuthenticateResponse? canAuthenticateResponse;

  bool get _biometricAvailable => canAuthenticateResponse?.isSuccess ?? false;

  @override
  void dispose() {
    _verifyLockoutTimer?.cancel();
    super.dispose();
  }

  void _startVerifyLockout() {
    _verifyLockedOut = true;
    _verifyLockoutRemaining = _verifyLockoutSeconds;
    _verifyLockoutTimer?.cancel();
    _verifyLockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _verifyLockoutRemaining--;
        if (_verifyLockoutRemaining <= 0) {
          _verifyLockedOut = false;
          _verifyFailedAttempts = 0;
          timer.cancel();
          _notifier.setStatus(
            status: GestureStatus.verify,
            gestureText: appLocalizations.drawOldGestureLock,
          );
        } else {
          _notifier.setStatus(
            status: GestureStatus.verifyFailedCountOverflow,
            gestureText:
                '${appLocalizations.gestureLockWrong} (${_verifyLockoutRemaining}s)',
          );
        }
      });
    });
    setState(() {
      _notifier.setStatus(
        status: GestureStatus.verifyFailedCountOverflow,
        gestureText:
            '${appLocalizations.gestureLockWrong} (${_verifyLockoutRemaining}s)',
      );
    });
  }

  @override
  void initState() {
    super.initState();
    initBiometricAuthentication();
  }

  initBiometricAuthentication() async {
    canAuthenticateResponse = await BiometricUtil.canAuthenticate();
    canAuthenticateResponseString =
        await BiometricUtil.getCanAuthenticateResponseString();
    if (_biometricAvailable && _enableBiometric && _isEditMode) {
      auth();
    }
  }

  void auth() async {
    void onAuthed() {
      IToast.showTop(appLocalizations.biometricVerifySuccess);
      setState(() {
        _notifier.setStatus(
          status: GestureStatus.create,
          gestureText: appLocalizations.drawNewGestureLock,
        );
        _isEditMode = false;
        _currentStep = 2;
      });
      _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
    }
    if (ResponsiveUtil.isIOS()) {
      if (await BiometricUtil.authenticateIOS() && mounted) onAuthed();
    } else {
      await ChewieUtils.localAuth(onAuthed: onAuthed);
    }
  }

  Widget _buildStepIndicator() {
    final primaryColor = ChewieTheme.primaryColor;
    final inactiveColor = Colors.grey.withOpacity(0.3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          final stepBefore = (i ~/ 2) + 1;
          final isCompleted = _currentStep > stepBefore;
          return Container(
            width: 32,
            height: 2,
            color: isCompleted ? primaryColor : inactiveColor,
          );
        }
        final step = (i ~/ 2) + 1;
        final isActive = step == _currentStep;
        final isCompleted = step < _currentStep;
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? primaryColor : inactiveColor,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        showBack: true,
        onTapBack: () => Navigator.pop(context),
        titleWidget: _buildStepIndicator(),
        centerTitle: true,
        showBorder: false,
        actions: const [
          BlankIconButton(),
          SizedBox(width: 5),
        ],
      ),
      body: SafeArea(
        right: false,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _notifier.gestureText,
                style: ChewieTheme.titleMedium,
              ),
              const SizedBox(height: 30),
              GestureUnlockIndicator(
                key: _indicator,
                size: 30,
                roundSpace: 4,
                defaultColor: Colors.grey.withOpacity(0.5),
                selectedColor: ChewieTheme.primaryColor.withOpacity(0.6),
              ),
              Flexible(
                child: GestureUnlockView(
                  key: _gestureUnlockView,
                  size: min(MediaQuery.sizeOf(context).width, 400),
                  padding: 60,
                  roundSpace: 40,
                  defaultColor: Colors.grey.withOpacity(0.5),
                  selectedColor: ChewieTheme.primaryColor,
                  failedColor: Theme.of(context).colorScheme.error,
                  disableColor: Colors.grey,
                  solidRadiusRatio: 0.3,
                  lineWidth: 2,
                  touchRadiusRatio: 0.3,
                  showLine: !_hideGestureTrail,
                  onCompleted: _gestureComplete,
                ),
              ),
              Visibility(
                visible: _isEditMode && _biometricAvailable && _enableBiometric,
                child: RoundIconTextButton(
                  text: ResponsiveUtil.isWindows()
                      ? appLocalizations.biometricVerifyPin
                      : appLocalizations.biometric,
                  onPressed: auth,
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  void _gestureComplete(List<int> selected, UnlockStatus status) async {
    switch (_notifier.status) {
      case GestureStatus.create:
      case GestureStatus.createFailed:
        if (selected.length < 4) {
          setState(() {
            _notifier.setStatus(
              status: GestureStatus.createFailed,
              gestureText: appLocalizations.atLeast4Points,
            );
          });
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
        } else {
          setState(() {
            _notifier.setStatus(
              status: GestureStatus.verify,
              gestureText: appLocalizations.drawGestureLockAgain,
            );
            _currentStep = _totalSteps;
          });
          _gesturePassword = GestureUnlockView.selectedToString(selected);
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.success);
          _indicator.currentState?.setSelectPoint(selected);
        }
        break;
      case GestureStatus.verify:
      case GestureStatus.verifyFailed:
        if (!_isEditMode) {
          String password = GestureUnlockView.selectedToString(selected);
          if (_gesturePassword == password) {
            IToast.showTop(appLocalizations.setGestureLockSuccess);
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verify,
                gestureText: appLocalizations.setGestureLockSuccess,
              );
              Navigator.pop(context);
            });
            CloudOTPHiveUtil.setGesturePassword(
                GestureUnlockView.selectedToString(selected));
          } else {
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verifyFailed,
                gestureText: appLocalizations.gestureLockNotMatch,
              );
            });
            _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
          }
        } else {
          if (_verifyLockedOut) return;
          String password = GestureUnlockView.selectedToString(selected);
          if (CloudOTPHiveUtil.verifyGesturePassword(password)) {
            _verifyFailedAttempts = 0;
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.create,
                gestureText: appLocalizations.drawNewGestureLock,
              );
              _isEditMode = false;
              _currentStep = 2;
            });
            _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
          } else {
            _verifyFailedAttempts++;
            if (_verifyFailedAttempts >= _maxVerifyAttempts) {
              _startVerifyLockout();
            } else {
              final remaining = _maxVerifyAttempts - _verifyFailedAttempts;
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
        }
        break;
      case GestureStatus.verifyFailedCountOverflow:
        break;
    }
  }
}
