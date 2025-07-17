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
  cancelButton: chewieLocalizations.biometricCancelButton,
  goToSettingsButton: chewieLocalizations.biometricGoToSettingsButton,
  biometricNotRecognized: chewieLocalizations.biometricNotRecognized,
  goToSettingsDescription: chewieLocalizations.biometricGoToSettingsDescription,
  biometricHint: ResponsiveUtil.isWindows()
      ? chewieLocalizations.biometricReasonWindows(ResponsiveUtil.appName)
      : chewieLocalizations.biometricReason(ResponsiveUtil.appName),
  biometricSuccess: chewieLocalizations.biometricSuccess,
  signInTitle: chewieLocalizations.biometricSignInTitle,
  deviceCredentialsRequiredTitle:
      chewieLocalizations.biometricDeviceCredentialsRequiredTitle,
);
