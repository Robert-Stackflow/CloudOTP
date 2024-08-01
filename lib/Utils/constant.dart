import 'package:flutter/cupertino.dart';
import 'package:local_auth_android/local_auth_android.dart';

import '../generated/l10n.dart';

const defaultPhone = "";
const defaultPassword = "";
const defaultLofterID = "";

const defaultMaxBackupCount = 50;

const double kLoadExtentOffset = 1000;

const Widget emptyWidget = SizedBox.shrink();

const defaultWindowSize = Size(1120, 740);

const minimumSize = Size(660, 700);

String shareAppText = S.current.shareAppText(officialWebsite);
const String feedbackEmail = "2014027378@qq.com";
String feedbackSubject = S.current.feedbackSubject;
const String feedbackBody = "";
const String officialWebsite = "https://apps.cloudchewie.com/cloudotp";
const String telegramLink = "https://t.me/CloudOTP";
const String repoUrl = "https://github.com/Robert-Stackflow/CloudOTP";
const String releaseUrl =
    "https://github.com/Robert-Stackflow/CloudOTP/releases";
const String issueUrl = "https://github.com/Robert-Stackflow/CloudOTP/issues";

AndroidAuthMessages androidAuthMessages = AndroidAuthMessages(
  cancelButton: S.current.biometricCancelButton,
  goToSettingsButton: S.current.biometricGoToSettingsButton,
  biometricNotRecognized: S.current.biometricNotRecognized,
  goToSettingsDescription: S.current.biometricGoToSettingsDescription,
  biometricHint: S.current.biometricHint,
  biometricSuccess: S.current.biometricSuccess,
  signInTitle: S.current.biometricSignInTitle,
  deviceCredentialsRequiredTitle:
      S.current.biometricDeviceCredentialsRequiredTitle,
);
