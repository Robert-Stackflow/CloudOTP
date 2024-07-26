import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:cloudotp/Utils/iprint.dart';
import 'package:cloudotp/Widgets/General/Unlock/gesture_notifier.dart';
import 'package:cloudotp/Widgets/General/Unlock/gesture_unlock_view.dart';
import 'package:cloudotp/Widgets/Window/window_caption.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../Utils/hive_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Widgets/Item/item_builder.dart';

class PinVerifyScreen extends StatefulWidget {
  const PinVerifyScreen(
      {super.key, this.onSuccess, this.isModal = true, this.autoAuth = true});

  final bool isModal;
  final bool autoAuth;
  final Function()? onSuccess;
  static const String routeName = "/pin/verify";

  @override
  PinVerifyScreenState createState() => PinVerifyScreenState();
}

AndroidAuthMessages andStrings = const AndroidAuthMessages(
  cancelButton: '取消',
  goToSettingsButton: '去设置',
  biometricNotRecognized: '指纹识别失败',
  goToSettingsDescription: '请设置指纹',
  biometricHint: '',
  biometricSuccess: '指纹识别成功',
  signInTitle: '指纹验证',
  deviceCredentialsRequiredTitle: '请先录入指纹!',
);

class PinVerifyScreenState extends State<PinVerifyScreen> {
  final String? _password = HiveUtil.getString(HiveUtil.guesturePasswdKey);
  late final bool _isUseBiometric =
      HiveUtil.getBool(HiveUtil.enableBiometricKey);
  late final GestureNotifier _notifier =
      GestureNotifier(status: GestureStatus.verify, gestureText: "验证密码");
  final GlobalKey<GestureState> _gestureUnlockView = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (_isUseBiometric && widget.autoAuth) {
      auth();
    }
  }

  void auth() async {
    LocalAuthentication localAuth = LocalAuthentication();
    try {
      String appName = (await PackageInfo.fromPlatform()).appName;
      await localAuth
          .authenticate(
        localizedReason: ResponsiveUtil.isWindows()
            ? '验证PIN以使用$appName'
            : '进行指纹验证以使用$appName',
        authMessages: [andStrings, andStrings, andStrings],
        options: const AuthenticationOptions(
          useErrorDialogs: false,
          stickyAuth: true,
        ),
      )
          .then((value) {
        if (value) {
          if (widget.onSuccess != null) widget.onSuccess!();
          Navigator.pop(context);
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
        }
      });
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        IPrint.debug("not avaliable");
      } else if (e.code == auth_error.notEnrolled) {
        IPrint.debug("not enrolled");
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        IPrint.debug("locked out");
      } else {
        IPrint.debug("other reason:$e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        right: false,
        child: Stack(
          children: [
            if (ResponsiveUtil.isDesktop()) const WindowMoveHandle(),
            Center(
              child: PopScope(
                canPop: !widget.isModal,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Text(
                      _notifier.gestureText,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 30),
                    Flexible(
                      child: GestureUnlockView(
                        key: _gestureUnlockView,
                        size: min(MediaQuery.sizeOf(context).width, 400),
                        padding: 60,
                        roundSpace: 40,
                        defaultColor: Colors.grey.withOpacity(0.5),
                        selectedColor: Theme.of(context).primaryColor,
                        failedColor: Colors.redAccent,
                        disableColor: Colors.grey,
                        solidRadiusRatio: 0.3,
                        lineWidth: 2,
                        touchRadiusRatio: 0.3,
                        onCompleted: _gestureComplete,
                      ),
                    ),
                    Visibility(
                      visible: _isUseBiometric,
                      child: GestureDetector(
                        onTap: () {
                          auth();
                        },
                        child: ItemBuilder.buildClickItem(
                          Text(
                            ResponsiveUtil.isWindows() ? "验证PIN" : "指纹识别",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _gestureComplete(List<int> selected, UnlockStatus status) async {
    switch (_notifier.status) {
      case GestureStatus.verify:
      case GestureStatus.verifyFailed:
        String password = GestureUnlockView.selectedToString(selected);
        if (_password == password) {
          if (widget.onSuccess != null) widget.onSuccess!();
          Navigator.pop(context);
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
        } else {
          setState(() {
            _notifier.setStatus(
              status: GestureStatus.verifyFailed,
              gestureText: "密码错误, 请重新绘制",
            );
          });
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
        }
        break;
      case GestureStatus.verifyFailedCountOverflow:
      case GestureStatus.create:
      case GestureStatus.createFailed:
        break;
    }
  }
}
