import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';

import '../../Utils/itoast.dart';
import '../../generated/l10n.dart';

// {
// "name": "GitHub",
// "secret": "KAVWPE6KSLJPXYGC",
// "updatedAt": 1724591267919,
// "serviceTypeID": "3ec08d85-d803-4b6a-a2f4-f5d24c9bba67",
// "otp": {
// "label": "Robert-Stackflow",
// "account": "Robert-Stackflow",
// "issuer": "GitHub",
// "digits": 6,
// "algorithm": "SHA1",
// "tokenType": "TOTP",
// "source": "Link"
// },
// "order": { "position": 0 },
// "icon": {
// "selected": "IconCollection",
// "iconCollection": { "id": "fff32440-f5be-4b9c-b471-f37d421f10c3" }
// }
// },
//据此json，生成TwoFASToken对象
class TwoFASTokenOtp {
  String label;
  String account;
  String issuer;
  int digits;
  int period;
  String algorithm;
  String tokenType;

  TwoFASTokenOtp({
    required this.label,
    required this.account,
    required this.issuer,
    required this.digits,
    required this.algorithm,
    required this.tokenType,
    required this.period,
  });

  factory TwoFASTokenOtp.fromJson(Map<String, dynamic> json) {
    return TwoFASTokenOtp(
      label: json['label'] ?? "",
      account: json['account'] ?? "",
      issuer: json['issuer'] ?? json['account'],
      digits: json['digits'],
      algorithm: json['algorithm'],
      tokenType: json['tokenType'],
      period: json['period'] ?? 0,
    );
  }
}

class TwoFASToken {
  String name;
  String secret;
  TwoFASTokenOtp otp;
  String groupId;

  TwoFASToken({
    required this.name,
    required this.secret,
    required this.otp,
    required this.groupId,
  });

  factory TwoFASToken.fromJson(Map<String, dynamic> json) {
    return TwoFASToken(
      name: json['name'],
      secret: json['secret'],
      otp: TwoFASTokenOtp.fromJson(json['otp']),
      groupId: json['groupId'] ?? "",
    );
  }

  OtpToken toOtpToken() {
    OtpToken token = OtpToken.init();
    token.issuer = otp.issuer;
    token.account = otp.account;
    token.secret = secret;
    token.counterString = otp.digits.toString();
    token.periodString = otp.period.toString();
    token.algorithm = OtpAlgorithm.fromString(otp.algorithm);
    token.tokenType = OtpTokenType.fromString(otp.tokenType);
    return token;
  }
}

class TwoFASGroup {
  String id;
  String name;

  TwoFASGroup({
    required this.id,
    required this.name,
  });

  TokenCategory toTokenCategory() {
    return TokenCategory.title(
      title: name,
    );
  }

  factory TwoFASGroup.fromJson(Map<String, dynamic> json) {
    return TwoFASGroup(
      id: json['id'],
      name: json['name'],
    );
  }
}

class TwoFASTokenImporter implements BaseTokenImporter {
  @override
  ImporterResult importFromData(Uint8List data) {
    return ImporterResult([], []);
  }

  @override
  Future<ImporterResult> importerFromPath(
    String path, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.importing);
    }
    List<OtpToken> tokens = [];
    List<TokenCategory> categories = [];
    try {
      File file = File(path);
      if (!file.existsSync()) {
        IToast.showTop(S.current.fileNotExist);
      } else {
        String content = file.readAsStringSync();
        Map<String, dynamic> json = jsonDecode(content);
        if (json.containsKey('servicesEncrypted')) {
          json['services'] = json['servicesEncrypted'];
        }
        List<TwoFASGroup> twoFASGroups = [];
        List<TwoFASToken> twoFASTokens = [];
        if (json.containsKey('services')) {
          for (var service in json['services']) {
            try {
              twoFASTokens.add(TwoFASToken.fromJson(service));
            } finally {}
          }
        }
        if (json.containsKey('groups')) {
          for (var service in json['groups']) {
            try {
              twoFASGroups.add(TwoFASGroup.fromJson(service));
            } finally {}
          }
        }
        categories = twoFASGroups.map((e) => e.toTokenCategory()).toList();
        tokens = twoFASTokens.map((e) => e.toOtpToken()).toList();
      }
    } catch (e, t) {
      print("$e\n$t");
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
    return ImporterResult(tokens, categories);
  }
}
