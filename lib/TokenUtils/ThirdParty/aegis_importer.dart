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

import 'dart:convert';
import 'dart:io';

import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Models/token_category_binding.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hashlib/hashlib.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';

import 'package:awesome_chewie/awesome_chewie.dart';
import '../../l10n/l10n.dart';

enum SlotType {
  Raw,
  Password,
  Biometric,
}

class Slot {
  SlotType type;
  String uuid;
  String key;
  KeyParams keyParams;
  int n;
  int r;
  int p;
  String salt;
  bool repaired;
  bool isBackup;

  Slot({
    required this.type,
    required this.uuid,
    required this.key,
    required this.keyParams,
    required this.n,
    required this.r,
    required this.p,
    required this.salt,
    required this.repaired,
    required this.isBackup,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      type: SlotType
          .values[(json['type'] as int).clamp(0, SlotType.values.length - 1)],
      uuid: json['uuid'],
      key: json['key'],
      keyParams: KeyParams.fromJson(json['key_params']),
      n: json['n'],
      r: json['r'],
      p: json['p'],
      salt: json['salt'],
      repaired: json['repaired'],
      isBackup: json['is_backup'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'uuid': uuid,
      'key': key,
      'key_params': keyParams.toJson(),
      'n': n,
      'r': r,
      'p': p,
      'salt': salt,
      'repaired': repaired,
      'is_backup': isBackup,
    };
  }
}

class KeyParams {
  String nonce;
  String tag;

  KeyParams({
    required this.nonce,
    required this.tag,
  });

  factory KeyParams.fromJson(Map<String, dynamic> json) {
    return KeyParams(
      nonce: json['nonce'] ?? "",
      tag: json['tag'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nonce': nonce,
      'tag': tag,
    };
  }
}

class AegisBackupHeader {
  List<Slot> slots;
  KeyParams? params;

  AegisBackupHeader({
    required this.slots,
    required this.params,
  });

  factory AegisBackupHeader.fromJson(Map<String, dynamic> json) {
    return AegisBackupHeader(
      slots: json['slots'] != null
          ? (json['slots'] as List).map((e) => Slot.fromJson(e)).toList()
          : [],
      params:
          json['params'] != null ? KeyParams.fromJson(json['params']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slots': List<dynamic>.from(slots.map((x) => x.toJson())),
      'params': params?.toJson(),
    };
  }
}

class AegisTokenOtp {
  String secret;
  int digits;
  int period;
  String algo;

  AegisTokenOtp({
    required this.secret,
    required this.digits,
    required this.algo,
    required this.period,
  });

  factory AegisTokenOtp.fromJson(Map<String, dynamic> json) {
    return AegisTokenOtp(
      secret: json['secret'] ?? "",
      digits: json['digits'] ?? 0,
      algo: json['algo'] ?? "SHA1",
      period: json['period'] ?? 0,
    );
  }
}

class AegisToken {
  String name;
  String type;
  String issuer;
  String note;
  bool favorite;
  AegisTokenOtp info;
  List<String> groups;
  String uuid;

  AegisToken({
    required this.name,
    required this.type,
    required this.issuer,
    required this.note,
    required this.favorite,
    required this.info,
    required this.groups,
    required this.uuid,
  });

  factory AegisToken.fromJson(Map<String, dynamic> json) {
    return AegisToken(
      name: json['name'],
      issuer: json['issuer'] ?? "",
      type: json['type'] ?? "TOTP",
      note: json['note'] ?? "",
      favorite: json['favorite'] ?? false,
      info: AegisTokenOtp.fromJson(json['info']),
      groups: json['groups'] != null
          ? (json['groups'] as List).map((e) => e.toString()).toList()
          : [],
      uuid: json['uuid'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'type': type,
      'note': note,
      'favorite': favorite,
      'info': info,
      'groups': groups,
      'uuid': uuid,
    };
  }

  OtpToken toOtpToken() {
    OtpToken token = OtpToken.init();
    token.uid = uuid;
    token.issuer = issuer;
    token.account = name;
    token.secret = info.secret;
    // token.counterString = info.digits > 0
    //     ? info.digits.toString()
    //     : token.tokenType.defaultDigits.toString();
    token.digits = info.digits > 0
        ? OtpDigits.fromString(info.digits.toString())
        : token.tokenType.defaultDigits;
    token.algorithm = OtpAlgorithm.fromString(info.algo);
    token.tokenType = OtpTokenType.fromString(type);
    token.periodString = info.period <= 0
        ? token.tokenType.defaultPeriod.toString()
        : info.period.toString();
    return token;
  }

  List<TokenCategoryBinding> getBindings() {
    return groups.map((e) {
      return TokenCategoryBinding(
        categoryUid: e,
        tokenUid: uuid,
      );
    }).toList();
  }
}

class AegisGroup {
  String uuid;
  String name;

  AegisGroup({
    required this.uuid,
    required this.name,
  });

  TokenCategory toTokenCategory() {
    return TokenCategory.title(
      tUid: uuid,
      title: name,
    );
  }

  factory AegisGroup.fromJson(Map<String, dynamic> json) {
    return AegisGroup(
      uuid: json['uuid'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
    };
  }
}

class AegisDatabase {
  List<AegisToken> entries;
  List<AegisGroup> groups;

  AegisDatabase({
    required this.entries,
    required this.groups,
  });

  factory AegisDatabase.fromJson(Map<String, dynamic> json) {
    return AegisDatabase(
      entries:
          (json['entries'] as List).map((e) => AegisToken.fromJson(e)).toList(),
      groups:
          (json['groups'] as List).map((e) => AegisGroup.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entries': List<dynamic>.from(entries.map((x) => x.toJson())),
      'groups': List<dynamic>.from(groups.map((x) => x.toJson())),
    };
  }
}

class AegisBackup {
  AegisBackupHeader header;
  AegisDatabase? db;
  String? dbString;
  String? password;

  AegisBackup({
    required this.header,
    this.db,
    this.dbString,
    this.password,
  });

  factory AegisBackup.fromJson(Map<String, dynamic> json) {
    bool isEncrypted = json['db'] is! Map<String, dynamic>;
    return AegisBackup(
      header: AegisBackupHeader.fromJson(json['header']),
      db: isEncrypted ? null : AegisDatabase.fromJson(json['db']),
      dbString: isEncrypted ? json['db'] ?? json['dbString'] : null,
      password: json['password'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'header': header.toJson(),
      'db': db?.toJson(),
      'dbString': dbString,
      'password': password,
    };
  }
}

class AegisTokenImporter implements BaseTokenImporter {
  static const String baseAlgorithm = "AES";
  static const String mode = "GCM";
  static const String padding = "NoPadding";
  static const String algorithmDescription = "$baseAlgorithm/$mode/$padding";

  static const int keyLength = 32;

  static dynamic decryptBackup(AegisBackup backup) {
    if (backup.dbString == null || backup.header.params == null) {
      return [
        DecryptResult.invalidPasswordOrDataCorrupted,
        null,
      ];
    }
    String password = backup.password ?? "";
    if (password.isEmpty) {
      return [
        DecryptResult.invalidPasswordOrDataCorrupted,
        null,
      ];
    }
    final masterKey = getMasterKeyFromSlots(backup.header.slots, password);

    if (masterKey == null) {
      return [
        DecryptResult.invalidPasswordOrDataCorrupted,
        null,
      ];
    }

    final databaseBytes = Uint8List.fromList(base64.decode(backup.dbString!));
    final ivBytes = Uint8List.fromList(hex.decode(backup.header.params!.nonce));
    final macBytes = Uint8List.fromList(hex.decode(backup.header.params!.tag));

    final decryptedBytes =
        decryptAesGcm(masterKey, ivBytes, databaseBytes, macBytes);
    final json = utf8.decode(decryptedBytes);
    final database = AegisDatabase.fromJson(jsonDecode(json));

    return [
      DecryptResult.success,
      AegisBackup(
        header: backup.header,
        db: database,
      ),
    ];
  }

  static Uint8List? getMasterKeyFromSlots(List<Slot> slots, String password) {
    final passwordBytes = utf8.encode(password);

    for (var slot in slots.where((slot) => slot.type == SlotType.Password)) {
      try {
        return decryptSlot(slot, passwordBytes);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Uint8List decryptSlot(Slot slot, Uint8List password) {
    final saltBytes = hex.decode(slot.salt);
    final derivedKey = Scrypt(
            salt: saltBytes,
            cost: slot.n,
            blockSize: slot.r,
            parallelism: slot.p,
            derivedKeyLength: keyLength)
        .convert(password)
        .bytes;

    final ivBytes = Uint8List.fromList(hex.decode(slot.keyParams.nonce));
    final keyBytes = Uint8List.fromList(hex.decode(slot.key));
    final macBytes = Uint8List.fromList(hex.decode(slot.keyParams.tag));

    return decryptAesGcm(derivedKey, ivBytes, keyBytes, macBytes);
  }

  static Uint8List decryptAesGcm(
      Uint8List key, Uint8List iv, Uint8List data, Uint8List mac) {
    final cipher = GCMBlockCipher(AESEngine());
    final aeadParams = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
    cipher.init(false, aeadParams);

    final authenticatedBytes = getAuthenticatedBytes(data, mac);
    return cipher.process(authenticatedBytes);
  }

  static Uint8List getAuthenticatedBytes(Uint8List payload, Uint8List mac) {
    final result = Uint8List(payload.length + mac.length);
    result.setRange(0, payload.length, payload);
    result.setRange(payload.length, result.length, mac);
    return result;
  }

  Future<void> import(AegisBackup backup) async {
    List<OtpToken> tokens = [];
    List<TokenCategory> categories = [];
    List<TokenCategoryBinding> bindings = [];
    List<AegisGroup> aegisGroups = [];
    List<AegisToken> aegisTokens = [];
    if (backup.db != null) {
      aegisTokens = backup.db!.entries;
      aegisGroups = backup.db!.groups;
    }
    categories = aegisGroups.map((e) => e.toTokenCategory()).toList();
    tokens = aegisTokens.map((e) => e.toOtpToken()).toList();
    bindings = aegisTokens.expand((e) => e.getBindings()).toList();
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
          showProgressDialog(appLocalizations.importing, showProgress: false);
    }
    try {
      File file = File(path);
      if (!file.existsSync()) {
        IToast.showTop(appLocalizations.fileNotExist);
      } else {
        String content = file.readAsStringSync();
        Map<String, dynamic> json = jsonDecode(content);
        AegisBackup backup = AegisBackup.fromJson(json);
        if (backup.dbString != null) {
          if (showLoading) dialog.dismiss();
          InputValidateAsyncController validateAsyncController =
              InputValidateAsyncController(
            listen: false,
            validator: (text) async {
              if (text.isEmpty) {
                return appLocalizations.autoBackupPasswordCannotBeEmpty;
              }
              if (showLoading) {
                dialog.show(
                    msg: appLocalizations.importing, showProgress: false);
              }
              backup.password = text;
              var res = await compute(
                (receiveMessage) {
                  AegisBackup backup = AegisBackup.fromJson(receiveMessage);
                  return decryptBackup(backup);
                },
                backup.toJson(),
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
                return appLocalizations.invalidPasswordOrDataCorrupted;
              }
            },
            controller: TextEditingController(),
          );
          BottomSheetBuilder.showBottomSheet(
            chewieProvider.rootContext,
            responsive: true,
            (context) => InputBottomSheet(
              validator: (value) {
                if (value.isEmpty) {
                  return appLocalizations.autoBackupPasswordCannotBeEmpty;
                }
                return null;
              },
              checkSyncValidator: false,
              validateAsyncController: validateAsyncController,
              title: appLocalizations.inputImportPasswordTitle,
              message: appLocalizations.inputImportPasswordTip,
              hint: appLocalizations.inputImportPasswordHint,
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetterAndSymbol,
              ],
              tailingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.password,
              ),
              onValidConfirm: (password) async {},
            ),
          );
        } else {
          await import(backup);
        }
      }
    } catch (e, t) {
      ILogger.error("Failed to import from 2FAS", e, t);
      IToast.showTop(appLocalizations.importFailed);
    } finally {
      if (showLoading) {
        dialog.dismiss();
      }
    }
  }
}
