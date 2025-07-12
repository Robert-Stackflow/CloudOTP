import 'package:flutter/cupertino.dart';
import 'package:local_auth_android/local_auth_android.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

const double appBarWithTabBarHeight = 152;

const double maxMediaOrQuoteWidth = 480;

const double maxChatWidth = 800;

const double searchBarWidth = 400;

const double kLoadExtentOffset = 1000;

const Widget emptyWidget = SizedBox.shrink();

const bool defaultEnableSafeMode = true;

String windowsKeyPath = 'SOFTWARE\\Cloudchewie\\${ResponsiveUtil.appName}';
String downloadPkgsUrl =
    "https://pkgs.cloudchewie.com/${ResponsiveUtil.appName}";
String officialWebsite =
    "https://apps.cloudchewie.com/${ResponsiveUtil.appName.toLowerCase()}";
String repoUrl =
    "https://github.com/Robert-Stackflow/${ResponsiveUtil.appName}";
String releaseUrl =
    "https://github.com/Robert-Stackflow/${ResponsiveUtil.appName}/releases";
String issueUrl =
    "https://github.com/Robert-Stackflow/${ResponsiveUtil.appName}/issues";

AndroidAuthMessages androidAuthMessages = AndroidAuthMessages(
  cancelButton: ChewieS.current.biometricCancelButton,
  goToSettingsButton: ChewieS.current.biometricGoToSettingsButton,
  biometricNotRecognized: ChewieS.current.biometricNotRecognized,
  goToSettingsDescription: ChewieS.current.biometricGoToSettingsDescription,
  biometricHint: ResponsiveUtil.isWindows()
      ? ChewieS.current.biometricReasonWindows(ResponsiveUtil.appName)
      : ChewieS.current.biometricReason(ResponsiveUtil.appName),
  biometricSuccess: ChewieS.current.biometricSuccess,
  signInTitle: ChewieS.current.biometricSignInTitle,
  deviceCredentialsRequiredTitle:
      ChewieS.current.biometricDeviceCredentialsRequiredTitle,
);
