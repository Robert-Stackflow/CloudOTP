import 'dart:math';

import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/General/Unlock/gesture_notifier.dart';
import 'package:cloudotp/Widgets/General/Unlock/gesture_unlock_indicator.dart';
import 'package:cloudotp/Widgets/General/Unlock/gesture_unlock_view.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';

import '../../Utils/hive_util.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  static const String routeName = "/pin/change";

  @override
  PinChangeScreenState createState() => PinChangeScreenState();
}

class PinChangeScreenState extends State<PinChangeScreen> {
  String _gesturePassword = "";
  final String? _oldPassword = HiveUtil.getString(HiveUtil.guesturePasswdKey);
  bool _isEditMode = HiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
      HiveUtil.getString(HiveUtil.guesturePasswdKey)!.isNotEmpty;
  late final bool _isUseBiometric =
      _isEditMode && HiveUtil.getBool(HiveUtil.enableBiometricKey);
  late final GestureNotifier _notifier = _isEditMode
      ? GestureNotifier(
          status: GestureStatus.verify,
          gestureText: S.current.drawOldGestureLock)
      : GestureNotifier(
          status: GestureStatus.create,
          gestureText: S.current.drawNewGestureLock);
  final GlobalKey<GestureState> _gestureUnlockView = GlobalKey();
  final GlobalKey<GestureUnlockIndicatorState> _indicator = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (_isUseBiometric) {
      auth();
    }
  }

  void auth() async {
    await Utils.localAuth(onAuthed: () {
      IToast.showTop(S.current.biometricVerifySuccess);
      setState(() {
        _notifier.setStatus(
          status: GestureStatus.create,
          gestureText: S.current.drawNewGestureLock,
        );
        _isEditMode = false;
      });
      _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        right: false,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 50),
              Text(
                _notifier.gestureText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 30),
              GestureUnlockIndicator(
                key: _indicator,
                size: 30,
                roundSpace: 4,
                defaultColor: Colors.grey.withOpacity(0.5),
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.6),
              ),
              Flexible(
                child: GestureUnlockView(
                  key: _gestureUnlockView,
                  size: min(MediaQuery.sizeOf(context).width, 400),
                  padding: 60,
                  roundSpace: 40,
                  defaultColor: Colors.grey.withOpacity(0.5),
                  selectedColor: Theme.of(context).primaryColor,
                  failedColor: Theme.of(context).colorScheme.error,
                  disableColor: Colors.grey,
                  solidRadiusRatio: 0.3,
                  lineWidth: 2,
                  touchRadiusRatio: 0.3,
                  onCompleted: _gestureComplete,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_isEditMode && _isUseBiometric) {
                    auth();
                  }
                },
                child: ItemBuilder.buildClickItem(
                  clickable: _isEditMode && _isUseBiometric,
                  Text(
                    _isEditMode && _isUseBiometric
                        ? (ResponsiveUtil.isWindows()
                            ? S.current.biometricVerifyPin
                            : S.current.biometricVerifyFingerprint)
                        : "",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
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
              gestureText: S.current.atLeast4Points,
            );
          });
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
        } else {
          setState(() {
            _notifier.setStatus(
              status: GestureStatus.verify,
              gestureText: S.current.drawGestureLockAgain,
            );
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
            IToast.showTop(S.current.setGestureLockSuccess);
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verify,
                gestureText: S.current.setGestureLockSuccess,
              );
              Navigator.pop(context);
            });
            HiveUtil.put(HiveUtil.guesturePasswdKey,
                GestureUnlockView.selectedToString(selected));
          } else {
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verifyFailed,
                gestureText: S.current.gestureLockNotMatch,
              );
            });
            _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
          }
        } else {
          String password = GestureUnlockView.selectedToString(selected);
          if (_oldPassword == password) {
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.create,
                gestureText: S.current.drawNewGestureLock,
              );
              _isEditMode = false;
            });
            _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
          } else {
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verifyFailed,
                gestureText: S.current.gestureLockWrong,
              );
            });
            _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
          }
        }
        break;
      case GestureStatus.verifyFailedCountOverflow:
        break;
    }
  }
}
