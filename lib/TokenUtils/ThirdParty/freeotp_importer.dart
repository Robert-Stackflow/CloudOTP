import 'dart:convert';
import 'dart:io';

import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Models/token_category_binding.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:cloudotp/Utils/Base32/base32.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Widgets/Dialog/progress_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/digests/sha1.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

//{f5d91a9f-da3f-49db-b432-e8a9dfc36408-token: {"algo":"SHA1","digits":6,"issuerExt":"Atlassian","label":"yutuan.victory@gmail.com","period":30,"type":"TOTP"}, 75f207ff-543b-40af-b145-4c39f5ebfce3: {"key":"{\"mCipher\":\"AES\/GCM\/NoPadding\",\"mCipherText\":[109,-51,-116,-11,-27,-107,-9,65,-117,59,4,58,117,-82,-115,87,-48,-104,95,53,-66,94,-67,-124,-84],\"mParameters\":[48,17,4,12,-10,-86,-14,-30,72,14,-119,100,-81,36,-57,-45,2,1,16],\"mToken\":\"HmacSHA1\"}"}, 75f207ff-543b-40af-b145-4c39f5ebfce3-token: {"algo":"SHA1","digits":6,"issuerExt":"Github","label":"demo@cloudchewie.com","period":30,"type":"TOTP"}, f5d91a9f-da3f-49db-b432-e8a9dfc36408: {"key":"{\"mCipher\":\"AES\/GCM\/NoPadding\",\"mCipherText\":[45,46,-18,-106,-76,75,104,-48,-19,-73,0,-88,-55,45,-59,56,73,85,-72,-108,100,9,58,27,-75,111,105,51,69,21,75,-91,117,-73,-32,-44],\"mParameters\":[48,17,4,12,-103,-45,-119,-57,43,-106,120,59,76,-49,-30,0,2,1,16],\"mToken\":\"HmacSHA1\"}"}, masterKey: {"mAlgorithm":"PBKDF2withHmacSHA512","mEncryptedKey":{"mCipher":"AES/GCM/NoPadding","mCipherText":[-55,34,16,112,-124,-47,-92,-93,4,51,98,-46,71,-20,-27,61,107,27,-101,-100,111,20,19,-63,32,73,62,103,-26,88,100,-31,-111,-16,-43,-117,118,-99,40,119,-101,-85,-51,102,108,-116,-74,113],"mParameters":[48,17,4,12,18,-68,53,-99,29,43,1,53,88,13,118,60,2,1,16],"mToken":"AES"},"mIterations":100000,"mSalt":[-107,127,8,71,13,-61,-41,-68,-57,19,-104,31,-107,60,-92,-61,-19,-11,-121,20,-53,32,-19,114,23,1,18,93,-110,-5,-65,123]}}
//据此构建MaterKey、EncryptedKey、TokenInfo、TokenKeyInfo类
class MasterKey {
  String algorithm;
  int iterations;
  List<int> salt;
  EncryptedKey encryptedKey;

  MasterKey({
    required this.algorithm,
    required this.iterations,
    required this.salt,
    required this.encryptedKey,
  });

  factory MasterKey.fromJson(Map<String, dynamic> json) {
    return MasterKey(
      algorithm: json['mAlgorithm'],
      iterations: json['mIterations'],
      salt: (json['mSalt'] as List).cast<int>(),
      encryptedKey: EncryptedKey.fromJson(json['mEncryptedKey']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mAlgorithm': algorithm,
      'mIterations': iterations,
      'mSalt': salt,
      'mEncryptedKey': encryptedKey.toJson(),
    };
  }
}

class EncryptedKey {
  String cipher;
  List<int> cipherText;
  List<int> parameters;
  String token;

  EncryptedKey({
    required this.cipher,
    required this.cipherText,
    required this.parameters,
    required this.token,
  });

  factory EncryptedKey.fromJson(Map<String, dynamic> json) {
    return EncryptedKey(
      cipher: json['mCipher'],
      cipherText: (json['mCipherText'] as List).cast<int>(),
      parameters: (json['mParameters'] as List).cast<int>(),
      token: json['mToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mCipher': cipher,
      'mCipherText': cipherText,
      'mParameters': parameters,
      'mToken': token,
    };
  }
}

class TokenInfo {
  String label;
  String account;
  String issuer;
  int digits;
  int period;
  String algorithm;
  String tokenType;

  TokenInfo({
    required this.label,
    required this.account,
    required this.issuer,
    required this.digits,
    required this.period,
    required this.algorithm,
    required this.tokenType,
  });

  factory TokenInfo.fromJson(Map<String, dynamic> json) {
    return TokenInfo(
      label: json['label'],
      account: json['account'],
      issuer: json['issuer'],
      digits: json['digits'],
      period: json['period'],
      algorithm: json['algo'],
      tokenType: json['type'],
    );
  }
}

class TokenKeyInfo {
  String key;

  TokenKeyInfo({
    required this.key,
  });

  factory TokenKeyInfo.fromJson(Map<String, dynamic> json) {
    return TokenKeyInfo(
      key: json['key'],
    );
  }
}

class FreeOTPToken {
  String uid;
  String secret;
  TokenInfo otp;

  FreeOTPToken({
    required this.uid,
    required this.secret,
    required this.otp,
  });

  List<TokenCategoryBinding> getBindings() {
    return [];
  }

  OtpToken toOtpToken() {
    OtpToken token = OtpToken.init();
    token.uid = uid;
    token.account = otp.label;
    token.secret = secret;
    token.issuer = otp.issuer;
    token.algorithm = OtpAlgorithm.fromString(otp.algorithm);
    // token.counterString = otp.digits > 0
    //     ? otp.digits.toString()
    //     : token.tokenType.defaultDigits.toString();
    token.digits = otp.digits > 0
        ? OtpDigits.fromString(otp.digits.toString())
        : token.tokenType.defaultDigits;
    token.tokenType = OtpTokenType.fromString(otp.tokenType);
    token.periodString = otp.period <= 0
        ? token.tokenType.defaultPeriod.toString()
        : otp.period.toString();
    return token;
  }
}

class JvmStringDecoder {
  String getString(Uint8List bytes) {
    return utf8.decode(bytes);
  }
}

class FreeOTPTokenImporter implements BaseTokenImporter {
  static const int MasterKeyBytes = 32;

  Map<String, String> deserialise(Uint8List data) {
    final memoryStream = ByteData.sublistView(data);
    final result = <String, String>{};
    final stringDecoder = JvmStringDecoder();

    bool startParsing = false;
    String? key;

    int position = 0;

    while (position < memoryStream.lengthInBytes) {
      final item = memoryStream.getUint8(position);
      position++;

      if (!startParsing) {
        // TC_BLOCKDATA
        if (item == 0x77) {
          startParsing = true;
        }
        continue;
      }

      // TC_STRING
      if (item == 0x74) {
        final length = memoryStream.getUint16(position, Endian.big);
        position += 2;
        final stringBytes = data.sublist(position, position + length);
        position += length;

        final decoded = stringDecoder.getString(stringBytes);

        if (key == null) {
          key = decoded;
        } else {
          result[key] = decoded;
          key = null;
        }
      }
    }

    return result;
  }

  static dynamic decryptAndConvert(
    Map<String, String> values,
    String password,
  ) {
    try {
      final masterKeyInfo =
          MasterKey.fromJson(jsonDecode(values['masterKey']!));
      final masterKey = decryptMasterKey(masterKeyInfo, password);
      if (masterKey == null) {
        return [
          DecryptResult.invalidPasswordOrDataCorrupted,
          null,
        ];
      }

      final List<FreeOTPToken> authenticators = [];

      values.forEach((key, value) {
        if (!key.endsWith('-token')) return;

        final uid = key.replaceAll('-token', '');
        final info = TokenInfo.fromJson(jsonDecode(value));
        final keyJson = values[uid]!;
        final keyInfo = TokenKeyInfo.fromJson(jsonDecode(keyJson));
        final encryptedKey = EncryptedKey.fromJson(jsonDecode(keyInfo.key));
        final secret = decryptEncryptedKey(encryptedKey, masterKey);

        if (secret == null) return;

        FreeOTPToken token = FreeOTPToken(
          uid: uid,
          secret: base32.encode(secret),
          otp: info,
        );
        authenticators.add(token);
      });

      return [
        DecryptResult.success,
        authenticators,
      ];
    } catch (e, t) {
      debugPrint("$e\n$t");
      return [
        DecryptResult.invalidPasswordOrDataCorrupted,
        null,
      ];
    }
  }

  static KeyParameter? decryptMasterKey(MasterKey masterKey, String password) {
    final salt = masterKey.salt.cast<int>();
    print(masterKey.toJson());
    final key = deriveKey(
        password, masterKey.algorithm, masterKey.iterations ~/ 100, salt);
    final master = decryptEncryptedKey(masterKey.encryptedKey, key);
    print(master);
    if (master == null) {
      return null;
    }
    return KeyParameter(master);
  }

  static Uint8List? decryptEncryptedKey(
      EncryptedKey encryptedKey, KeyParameter key) {
    final encodedParams =
        Uint8List.fromList(encryptedKey.parameters.cast<int>());
    final encryptedData =
        Uint8List.fromList(encryptedKey.cipherText.cast<int>());

    final parameters =
        readAsn1Parameters(key, encodedParams, encryptedKey.token);

    final cipher = PaddedBlockCipher(encryptedKey.cipher)
      ..init(false, parameters);

    try {
      return cipher.process(encryptedData);
    } catch (e) {
      return null;
    }
  }

  static AEADParameters readAsn1Parameters(
      KeyParameter key, Uint8List encodedParameters, String associatedText) {
    final ASN1Sequence sequence = ASN1Sequence.fromBytes(encodedParameters);
    final Uint8List iv = (sequence.elements![0] as ASN1OctetString).octets!;
    final int macLength =
        (sequence.elements![1] as ASN1Integer).integer!.toInt();
    final Uint8List associatedBytes = utf8.encode(associatedText);

    return AEADParameters(key, macLength * 8, iv, associatedBytes);
  }

  static KeyParameter deriveKey(
      String password, String algorithm, int iterations, List<int> salt) {
    Digest digest;
    switch (algorithm) {
      case 'PBKDF2withHmacSHA1':
        digest = SHA1Digest();
        break;
      case 'PBKDF2withHmacSHA512':
        digest = SHA512Digest();
        break;
      default:
        throw ArgumentError('Unsupported algorithm $algorithm');
    }

    final passwordBytes = utf8.encode(password);
    final generator = PBKDF2KeyDerivator(HMac(digest, 64))
      ..init(Pbkdf2Parameters(
          Uint8List.fromList(salt), iterations, MasterKeyBytes * 8));

    return KeyParameter(generator.process(Uint8List.fromList(passwordBytes)));
  }

  Future<void> import(List<FreeOTPToken> twoFASTokens) async {
    List<OtpToken> tokens = [];
    List<TokenCategory> categories = [];
    List<TokenCategoryBinding> bindings = [];
    tokens = twoFASTokens.map((e) => e.toOtpToken()).toList();
    bindings = twoFASTokens.expand((e) => e.getBindings()).toList();
    await BaseTokenImporter.importResult(
        ImporterResult(tokens, categories, bindings));
  }

  @override
  Future<void> importFromPath(
    String path, {
    bool showLoading = true,
  }) async {
    late ProgressDialog dialog;
    if (showLoading) {
      dialog =
          showProgressDialog(msg: S.current.importing, showProgress: false);
    }
    try {
      File file = File(path);
      if (!file.existsSync()) {
        IToast.showTop(S.current.fileNotExist);
      } else {
        Map<String, dynamic> json = deserialise(file.readAsBytesSync());
        if (showLoading) dialog.dismiss();
        InputValidateAsyncController validateAsyncController =
            InputValidateAsyncController(
          listen: false,
          validator: (text) async {
            if (text.isEmpty) {
              return S.current.autoBackupPasswordCannotBeEmpty;
            }
            if (showLoading) {
              dialog.show(msg: S.current.importing, showProgress: false);
            }
            var res = await compute(
              (receiveMessage) {
                return decryptAndConvert(
                    receiveMessage["payload"] as Map<String, String>,
                    receiveMessage["password"] as String);
              },
              {
                'payload': json,
                'password': text,
              },
            );
            DecryptResult decryptResult = res[0];
            if (decryptResult == DecryptResult.success) {
              await import(res[1]);
              if (showLoading) {
                dialog.dismiss();
              }
              return null;
            } else {
              if (showLoading) {
                dialog.dismiss();
              }
              return S.current.invalidPasswordOrDataCorrupted;
            }
          },
          controller: TextEditingController(),
        );
        BottomSheetBuilder.showBottomSheet(
          rootContext,
          responsive: true,
          useWideLandscape: true,
          (context) => InputBottomSheet(
            validator: (value) {
              if (value.isEmpty) {
                return S.current.autoBackupPasswordCannotBeEmpty;
              }
              return null;
            },
            checkSyncValidator: false,
            validateAsyncController: validateAsyncController,
            title: S.current.inputImportPasswordTitle,
            message: S.current.inputImportPasswordTip,
            hint: S.current.inputImportPasswordHint,
            inputFormatters: [
              RegexInputFormatter.onlyNumberAndLetterAndSymbol,
            ],
            tailingType: InputItemTailingType.password,
            onValidConfirm: (password) async {},
          ),
        );
      }
    } catch (e, t) {
      ILogger.error("Failed to import from FreeOTP", e, t);
      IToast.showTop(S.current.importFailed);
    } finally {
      if (showLoading) {
        dialog.dismiss();
      }
    }
  }
}
