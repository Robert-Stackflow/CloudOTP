import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:cloudotp/Models/Proto/OtpMigration/otp_migration.pb.dart';
import 'package:cloudotp/Models/Proto/OtpMigration/otp_migration.pbserver.dart';
import 'package:cloudotp/TokenUtils/token_image_util.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:otp/otp.dart';

import '../TokenUtils/check_token_util.dart';
import '../Utils/utils.dart';
import 'Proto/CloudOtpToken/cloudotp_token_payload.pb.dart';

enum OtpTokenType {
  TOTP("TOTP", "TOTP"),
  HOTP("HOTP", "HOTP"),
  MOTP("MOTP", "MOTP"),
  Steam("Steam", "Steam"),
  Yandex("Yandex", "Yandex");

  const OtpTokenType(this.key, this.label);

  final String key;
  final String label;

  static OtpTokenType fromOtpMigrationType(OtpMigrationType type) {
    switch (type) {
      case OtpMigrationType.TOTP:
        return OtpTokenType.TOTP;
      case OtpMigrationType.HOTP:
        return OtpTokenType.HOTP;
      default:
        throw Exception("Invalid OtpTokenType");
    }
  }

  static OtpTokenType fromCloudOtpTokenType(CloudOtpTokenType type) {
    switch (type) {
      case CloudOtpTokenType.TOTP:
        return OtpTokenType.TOTP;
      case CloudOtpTokenType.HOTP:
        return OtpTokenType.HOTP;
      case CloudOtpTokenType.MOTP:
        return OtpTokenType.MOTP;
      case CloudOtpTokenType.STEAM:
        return OtpTokenType.Steam;
      case CloudOtpTokenType.YANDEX:
        return OtpTokenType.Yandex;
      default:
        throw Exception("Invalid OtpTokenType");
    }
  }

  static OtpTokenType fromString(String label) {
    label = label.toUpperCase();
    switch (label) {
      case "TOTP":
        return OtpTokenType.TOTP;
      case "HOTP":
        return OtpTokenType.HOTP;
      case "MOTP":
        return OtpTokenType.MOTP;
      case "STEAM":
        return OtpTokenType.Steam;
      case "YAOTP":
        return OtpTokenType.Yandex;
      default:
        throw Exception("Invalid OtpTokenType");
    }
  }

  static OtpTokenType fromInt(int index) {
    switch (index) {
      case 0:
        return OtpTokenType.TOTP;
      case 1:
        return OtpTokenType.HOTP;
      case 2:
        return OtpTokenType.MOTP;
      case 3:
        return OtpTokenType.Steam;
      case 4:
        return OtpTokenType.Yandex;
      default:
        throw Exception("Invalid OtpTokenType");
    }
  }

  String get authority {
    return toAuthorities()[index];
  }

  static List<String> toAuthorities({bool toLowerCase = true}) {
    return [
      "TOTP",
      "HOTP",
      "MOTP",
      "Steam",
      "YaOTP",
    ].map((e) => toLowerCase ? e.toLowerCase() : e).toList();
  }

  static List<String> toLabels({bool toLowerCase = false}) {
    return OtpTokenType.values
        .map((e) => toLowerCase ? e.label.toLowerCase() : e.label)
        .toList();
  }

  int get defaultPeriod {
    switch (this) {
      case OtpTokenType.TOTP:
        return 30;
      case OtpTokenType.HOTP:
        return 0;
      case OtpTokenType.MOTP:
        return 30;
      case OtpTokenType.Steam:
        return 30;
      case OtpTokenType.Yandex:
        return 30;
    }
  }

  int get maxPinLength {
    switch (this) {
      case OtpTokenType.TOTP:
        return 0;
      case OtpTokenType.HOTP:
        return 0;
      case OtpTokenType.MOTP:
        return 4;
      case OtpTokenType.Steam:
        return 0;
      case OtpTokenType.Yandex:
        return 16;
    }
  }

  OtpDigits get defaultDigits {
    switch (this) {
      case OtpTokenType.TOTP:
        return OtpDigits.D6;
      case OtpTokenType.HOTP:
        return OtpDigits.D6;
      case OtpTokenType.MOTP:
        return OtpDigits.D6;
      case OtpTokenType.Steam:
        return OtpDigits.D5;
      case OtpTokenType.Yandex:
        return OtpDigits.D8;
    }
  }

  CloudOtpTokenType get cloudOtpTokenType {
    switch (this) {
      case OtpTokenType.TOTP:
        return CloudOtpTokenType.TOTP;
      case OtpTokenType.HOTP:
        return CloudOtpTokenType.HOTP;
      case OtpTokenType.MOTP:
        return CloudOtpTokenType.MOTP;
      case OtpTokenType.Steam:
        return CloudOtpTokenType.STEAM;
      case OtpTokenType.Yandex:
        return CloudOtpTokenType.YANDEX;
    }
  }

  OtpMigrationType get otpMigrationType {
    switch (this) {
      case OtpTokenType.TOTP:
        return OtpMigrationType.TOTP;
      case OtpTokenType.HOTP:
        return OtpMigrationType.HOTP;
      case OtpTokenType.MOTP:
      case OtpTokenType.Steam:
      case OtpTokenType.Yandex:
        throw Exception("Invalid OtpTokenType");
    }
  }
}

enum OtpDigits {
  D5(5, "5"),
  D6(6, "6"),
  D7(7, "7"),
  D8(8, "8");

  const OtpDigits(this.key, this.label);

  final int key;
  final String label;

  int get digit {
    return key;
  }

  static OtpDigits fromOtpMigrationDigitCount(
      OtpMigrationDigitCount digitCount) {
    switch (digitCount) {
      case OtpMigrationDigitCount.SIX:
        return OtpDigits.D6;
      case OtpMigrationDigitCount.EIGHT:
        return OtpDigits.D8;
      default:
        throw Exception("Invalid OtpDigits");
    }
  }

  static OtpDigits fromCloudOtpTokenDigitCount(
      CloudOtpTokenDigitCount digitCount) {
    switch (digitCount) {
      case CloudOtpTokenDigitCount.FIVE:
        return OtpDigits.D5;
      case CloudOtpTokenDigitCount.SIX:
        return OtpDigits.D6;
      case CloudOtpTokenDigitCount.SEVEN:
        return OtpDigits.D7;
      case CloudOtpTokenDigitCount.EIGHT:
        return OtpDigits.D8;
      default:
        throw Exception("Invalid OtpDigits");
    }
  }

  static OtpDigits froMString(String label) {
    label = label.toUpperCase();
    switch (label) {
      case "5":
        return OtpDigits.D5;
      case "6":
        return OtpDigits.D6;
      case "7":
        return OtpDigits.D7;
      case "8":
        return OtpDigits.D8;
      default:
        throw Exception("Invalid OtpDigits");
    }
  }

  CloudOtpTokenDigitCount get cloudOtpTokenDigitCount {
    switch (this) {
      case OtpDigits.D5:
        return CloudOtpTokenDigitCount.FIVE;
      case OtpDigits.D6:
        return CloudOtpTokenDigitCount.SIX;
      case OtpDigits.D7:
        return CloudOtpTokenDigitCount.SEVEN;
      case OtpDigits.D8:
        return CloudOtpTokenDigitCount.EIGHT;
    }
  }

  OtpMigrationDigitCount get otpMigrationDigitCount {
    switch (this) {
      case OtpDigits.D6:
        return OtpMigrationDigitCount.SIX;
      case OtpDigits.D8:
        return OtpMigrationDigitCount.EIGHT;
      case OtpDigits.D5:
      case OtpDigits.D7:
        throw Exception("Invalid OtpDigits");
    }
  }

  static List<String> toStrings() {
    return OtpDigits.values.map((e) => e.label).toList();
  }
}

enum OtpAlgorithm {
  SHA1("SHA1", "SHA1"),
  SHA256("SHA256", "SHA256"),
  SHA512("SHA512", "SHA512");

  const OtpAlgorithm(this.key, this.label);

  final String key;
  final String label;

  static OtpAlgorithm fromOtpMigrationAlgorithm(
      OtpMigrationAlgorithm algorithm) {
    switch (algorithm) {
      case OtpMigrationAlgorithm.SHA1:
        return OtpAlgorithm.SHA1;
      case OtpMigrationAlgorithm.SHA256:
        return OtpAlgorithm.SHA256;
      case OtpMigrationAlgorithm.SHA512:
        return OtpAlgorithm.SHA512;
      default:
        throw Exception("Invalid OtpAlgorithm");
    }
  }

  static OtpAlgorithm fromCloudOtpTokenAlgorithm(
      CloudOtpTokenAlgorithm algorithm) {
    switch (algorithm) {
      case CloudOtpTokenAlgorithm.SHA1:
        return OtpAlgorithm.SHA1;
      case CloudOtpTokenAlgorithm.SHA256:
        return OtpAlgorithm.SHA256;
      case CloudOtpTokenAlgorithm.SHA512:
        return OtpAlgorithm.SHA512;
      default:
        throw Exception("Invalid OtpAlgorithm");
    }
  }

  static OtpAlgorithm fromString(String label) {
    label = label.toUpperCase();
    switch (label) {
      case "SHA1":
        return OtpAlgorithm.SHA1;
      case "SHA256":
        return OtpAlgorithm.SHA256;
      case "SHA512":
        return OtpAlgorithm.SHA512;
      default:
        throw Exception("Invalid OtpAlgorithm");
    }
  }

  CloudOtpTokenAlgorithm get cloudOtpTokenAlgorithm {
    switch (this) {
      case OtpAlgorithm.SHA1:
        return CloudOtpTokenAlgorithm.SHA1;
      case OtpAlgorithm.SHA256:
        return CloudOtpTokenAlgorithm.SHA256;
      case OtpAlgorithm.SHA512:
        return CloudOtpTokenAlgorithm.SHA512;
    }
  }

  OtpMigrationAlgorithm get otpMigrationAlgorithm {
    switch (this) {
      case OtpAlgorithm.SHA1:
        return OtpMigrationAlgorithm.SHA1;
      case OtpAlgorithm.SHA256:
        return OtpMigrationAlgorithm.SHA256;
      case OtpAlgorithm.SHA512:
        return OtpMigrationAlgorithm.SHA512;
    }
  }

  static List<String> toStrings() {
    return OtpAlgorithm.values.map((e) => e.label).toList();
  }

  Algorithm get algorithm {
    switch (this) {
      case OtpAlgorithm.SHA1:
        return Algorithm.SHA1;
      case OtpAlgorithm.SHA256:
        return Algorithm.SHA256;
      case OtpAlgorithm.SHA512:
        return Algorithm.SHA512;
    }
  }
}

extension IntToOtpEnumExtension on int {
  OtpTokenType get otpTokenType {
    switch (this) {
      case 0:
        return OtpTokenType.TOTP;
      case 1:
        return OtpTokenType.HOTP;
      case 2:
        return OtpTokenType.MOTP;
      case 3:
        return OtpTokenType.Steam;
      case 4:
        return OtpTokenType.Yandex;
      default:
        return OtpTokenType.TOTP;
    }
  }

  OtpDigits get otpDigits {
    switch (this) {
      case 5:
        return OtpDigits.D5;
      case 6:
        return OtpDigits.D6;
      case 7:
        return OtpDigits.D7;
      case 8:
        return OtpDigits.D8;
      default:
        return OtpDigits.D6;
    }
  }

  OtpAlgorithm get otpAlgorithm {
    switch (this) {
      case 0:
        return OtpAlgorithm.SHA1;
      case 1:
        return OtpAlgorithm.SHA256;
      case 2:
        return OtpAlgorithm.SHA512;
      default:
        return OtpAlgorithm.SHA1;
    }
  }
}

class OtpToken {
  int id;
  int seq;
  String issuer;
  String secret;
  String account;
  String imagePath;
  OtpTokenType tokenType;
  OtpAlgorithm algorithm;
  OtpDigits digits;
  int createTimeStamp;
  int editTimeStamp;
  String counterString;
  String periodString;
  bool pinned;
  Map<String, dynamic> remark;
  int copyTimes;
  int lastCopyTimeStamp;
  String pin;

  int get pinnedInt => pinned ? 1 : 0;

  int get counter => int.tryParse(counterString) ?? 0;

  int get period => int.tryParse(periodString) ?? 30;

  String get title {
    return "$issuer${account.isNotEmpty ? " - $account" : ""}";
  }

  String get keyString {
    return "$issuer - $account - $secret - $tokenType - $algorithm - $digits - $counterString - $periodString - $pinned - $pin";
  }

  OtpToken({
    required this.id,
    required this.seq,
    required this.issuer,
    required this.secret,
    required this.account,
    required this.imagePath,
    required this.tokenType,
    required this.algorithm,
    required this.digits,
    required this.counterString,
    required this.periodString,
    required this.pinned,
    required this.createTimeStamp,
    required this.editTimeStamp,
    required this.remark,
    this.copyTimes = 0,
    this.lastCopyTimeStamp = 0,
    this.pin = "",
  });

  OtpToken.init({
    String? secret,
    String? issuer,
  })  : id = 0,
        seq = 0,
        issuer = issuer ?? "",
        secret = secret ?? "",
        account = "",
        imagePath = "",
        tokenType = OtpTokenType.TOTP,
        algorithm = OtpAlgorithm.SHA1,
        digits = OtpDigits.D6,
        counterString = "0",
        periodString = "30",
        pinned = false,
        remark = {},
        copyTimes = 0,
        lastCopyTimeStamp = 0,
        pin = "",
        createTimeStamp = DateTime.now().millisecondsSinceEpoch,
        editTimeStamp = DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seq': seq,
      'issuer': issuer,
      'secret': secret,
      'account': account,
      'image_path': imagePath,
      'token_type': tokenType.index,
      'algorithm': algorithm.key,
      'digits': digits.key,
      'counter': counter,
      'period': period,
      'pinned': pinned ? 1 : 0,
      'create_timestamp': createTimeStamp,
      'edit_timestamp': editTimeStamp,
      'remark': jsonEncode(remark),
      'copy_times': copyTimes,
      'pin': pin,
      'last_copy_timestamp': lastCopyTimeStamp,
    };
  }

  factory OtpToken.fromMap(Map<String, dynamic> map) {
    return OtpToken(
      id: map['id'],
      seq: map['seq'],
      issuer: map['issuer'],
      secret: map['secret'],
      account: map['account'],
      imagePath: map['image_path'],
      tokenType: (map['token_type'] as int).otpTokenType,
      algorithm: OtpAlgorithm.fromString(map['algorithm']),
      digits: (map['digits'] as int).otpDigits,
      counterString: map['counter'].toString(),
      periodString: map['period'].toString(),
      pinned: map['pinned'] == 1,
      createTimeStamp: map['create_timestamp'] ?? 0,
      editTimeStamp: map['edit_timestamp'] ?? 0,
      remark: jsonDecode(map['remark'] ?? "{}"),
      copyTimes: map['copy_times'],
      lastCopyTimeStamp: map['last_copy_timestamp'] ?? 0,
      pin: map['pin'],
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory OtpToken.fromJson(String source) {
    return OtpToken.fromMap(jsonDecode(source));
  }

  CloudOtpTokenParameters toCloudOtpTokenParameters() {
    return CloudOtpTokenParameters(
      secret: utf8.encode(secret),
      issuer: issuer,
      account: account,
      pin: pin,
      algorithm: algorithm.cloudOtpTokenAlgorithm,
      digits: digits.cloudOtpTokenDigitCount,
      type: tokenType.cloudOtpTokenType,
      period: $fixnum.Int64(period),
      counter: $fixnum.Int64(counter),
      pinned: $fixnum.Int64(pinned ? 1 : 0),
      copyTimes: $fixnum.Int64(copyTimes),
      lastCopyTimeStamp: $fixnum.Int64(lastCopyTimeStamp),
      remark: jsonEncode(remark),
      imagePath: imagePath,
    );
  }

  factory OtpToken.fromCloudOtpParameters(
      CloudOtpTokenParameters cloudOtpParameters) {
    return OtpToken(
      id: 0,
      seq: 0,
      issuer: cloudOtpParameters.issuer,
      secret: utf8.decode(cloudOtpParameters.secret),
      account: cloudOtpParameters.account,
      imagePath: cloudOtpParameters.imagePath,
      tokenType: OtpTokenType.fromCloudOtpTokenType(cloudOtpParameters.type),
      algorithm:
          OtpAlgorithm.fromCloudOtpTokenAlgorithm(cloudOtpParameters.algorithm),
      digits: OtpDigits.fromCloudOtpTokenDigitCount(cloudOtpParameters.digits),
      counterString: cloudOtpParameters.counter.toString(),
      periodString: cloudOtpParameters.period.toString(),
      pinned: cloudOtpParameters.pinned.toInt() == 1,
      createTimeStamp: DateTime.now().millisecondsSinceEpoch,
      editTimeStamp: DateTime.now().millisecondsSinceEpoch,
      remark: jsonDecode(cloudOtpParameters.remark),
      copyTimes: cloudOtpParameters.copyTimes.toInt(),
      lastCopyTimeStamp: cloudOtpParameters.lastCopyTimeStamp.toInt(),
      pin: cloudOtpParameters.pin,
    );
  }

  bool get isGoogleAuthenticatorCompatible {
    return (tokenType == OtpTokenType.TOTP || tokenType == OtpTokenType.HOTP) &&
        algorithm == OtpAlgorithm.SHA1 &&
        (digits == OtpDigits.D6 || digits == OtpDigits.D8) &&
        CheckTokenUtil.isSecretBase32(secret);
  }

  static OtpToken? fromOtpMigrationParameters(OtpMigrationParameters param) {
    OtpToken token = OtpToken.init();
    token.secret = base32.encode(Uint8List.fromList(param.secret));
    if (!CheckTokenUtil.isSecretBase32(token.secret)) return null;
    token.issuer = Utils.isEmpty(param.issuer) ? param.account : param.issuer;
    token.account = param.account;
    token.algorithm = OtpAlgorithm.fromOtpMigrationAlgorithm(param.algorithm);
    token.digits = OtpDigits.fromOtpMigrationDigitCount(param.digits);
    token.tokenType = OtpTokenType.fromOtpMigrationType(param.type);
    token.imagePath = TokenImageUtil.matchBrandLogo(token) ?? "";
    return token;
  }

  OtpMigrationParameters toOtpMigrationParameters() {
    return OtpMigrationParameters(
      secret: base32.decode(secret.toUpperCase()),
      issuer: issuer,
      account: account,
      algorithm: algorithm.otpMigrationAlgorithm,
      digits: digits.otpMigrationDigitCount,
      type: tokenType.otpMigrationType,
    );
  }

  clone() {
    return OtpToken(
      id: id,
      seq: seq,
      issuer: issuer,
      secret: secret,
      account: account,
      imagePath: imagePath,
      tokenType: tokenType,
      algorithm: algorithm,
      digits: digits,
      counterString: counterString,
      periodString: periodString,
      pinned: pinned,
      createTimeStamp: createTimeStamp,
      editTimeStamp: editTimeStamp,
      remark: Map<String, dynamic>.from(remark),
      copyTimes: copyTimes,
      lastCopyTimeStamp: lastCopyTimeStamp,
      pin: pin,
    );
  }

  copyFrom(OtpToken token) {
    id = token.id;
    seq = token.seq;
    issuer = token.issuer;
    secret = token.secret;
    account = token.account;
    imagePath = token.imagePath;
    tokenType = token.tokenType;
    algorithm = token.algorithm;
    digits = token.digits;
    counterString = token.counterString;
    periodString = token.periodString;
    pinned = token.pinned;
    createTimeStamp = token.createTimeStamp;
    editTimeStamp = token.editTimeStamp;
    remark = Map<String, dynamic>.from(token.remark);
    copyTimes = token.copyTimes;
    lastCopyTimeStamp = token.lastCopyTimeStamp;
    pin = token.pin;
  }
}
