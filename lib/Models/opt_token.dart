import 'dart:convert';

import 'package:otp/otp.dart';

enum OtpTokenType {
  TOTP("TOTP", "TOTP"),
  HOTP("HOTP", "HOTP"),
  MOTP("MOTP", "MOTP"),
  Steam("Steam", "Steam"),
  Yandex("Yandex", "Yandex");

  const OtpTokenType(this.key, this.label);

  final String key;
  final String label;

  static OtpTokenType fromLabel(String label) {
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
      case "YANDEX":
        return OtpTokenType.Yandex;
      default:
        return OtpTokenType.TOTP;
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
        return OtpTokenType.TOTP;
    }
  }

  static List<String> labels({bool toLowerCase = false}) {
    return OtpTokenType.values
        .map((e) => toLowerCase ? e.label.toLowerCase() : e.label)
        .toList();
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

  static OtpDigits fromLabel(String label) {
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
        return OtpDigits.D6;
    }
  }
}

enum OtpAlgorithm {
  SHA1("SHA1", "SHA1"),
  SHA256("SHA256", "SHA256"),
  SHA512("SHA512", "SHA512");

  const OtpAlgorithm(this.key, this.label);

  final String key;
  final String label;

  static OtpAlgorithm fromLabel(String label) {
    label = label.toUpperCase();
    switch (label) {
      case "SHA1":
        return OtpAlgorithm.SHA1;
      case "SHA256":
        return OtpAlgorithm.SHA256;
      case "SHA512":
        return OtpAlgorithm.SHA512;
      default:
        return OtpAlgorithm.SHA1;
    }
  }
}

extension OtpDigitsExtension on OtpDigits {
  List<String> get strings {
    return OtpDigits.values.map((e) => e.label).toList();
  }

  int get digit {
    return key;
  }
}

extension OtpAlgorithmExtension on OtpAlgorithm {
  List<String> get strings {
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

extension IntToOtpTokenTypeExtension on int {
  OtpTokenType get otpTokenType {
    switch (this) {
      case 0:
        return OtpTokenType.TOTP;
      case 1:
        return OtpTokenType.HOTP;
      default:
        return OtpTokenType.TOTP;
    }
  }
}

extension IntToOtpDigitsExtension on int {
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
}

extension IntToOtpAlgorithmExtension on int {
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
      'create_time_stamp': createTimeStamp,
      'edit_time_stamp': editTimeStamp,
      'remark': jsonEncode(remark),
      'copy_times': copyTimes,
      'pin': pin,
      'last_copy_time_stamp': lastCopyTimeStamp,
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
      algorithm: OtpAlgorithm.fromLabel(map['algorithm']),
      digits: (map['digits'] as int).otpDigits,
      counterString: map['counter'].toString(),
      periodString: map['period'].toString(),
      pinned: map['pinned'] == 1,
      createTimeStamp: map['create_time_stamp'],
      editTimeStamp: map['edit_time_stamp'],
      remark: jsonDecode(map['remark'] ?? "{}"),
      copyTimes: map['copy_times'],
      lastCopyTimeStamp: map['last_copy_time_stamp'],
      pin: map['pin'],
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
}
