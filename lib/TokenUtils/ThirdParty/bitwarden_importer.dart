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
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/argon2_native_int_impl.dart';
import 'package:pointycastle/key_derivators/hkdf.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/paddings/pkcs7.dart';

import 'package:awesome_chewie/awesome_chewie.dart';
import '../../l10n/l10n.dart';

class BitwardenFolder {
  String name;
  String uid;

  BitwardenFolder({
    required this.name,
    required this.uid,
  });

  factory BitwardenFolder.fromJson(Map<String, dynamic> json) {
    return BitwardenFolder(
      name: json['name'] ?? "",
      uid: json['id'] ?? StringUtil.generateUid(),
    );
  }
}

enum KdfType {
  Pbkdf2Sha256,
  Argon2Id,
}

enum VaultInvalidType {
  Valid,
  AccountRestricted,
  ParameterLoss,
  SaltLoss,
  DataLoss,
}

class Vault {
  List<BitwardenFolder> folders;
  List<BitwardenItem> items;
  String? encKeyValidation;
  bool encrypted;
  bool? passwordProtected;
  String? salt;
  KdfType? kdfType;
  int? kdfIterations;
  int? kdfMemory;
  int? kdfParallelism;
  String? data;

  Vault({
    required this.folders,
    required this.items,
    this.encKeyValidation,
    required this.encrypted,
    this.passwordProtected,
    this.salt,
    this.kdfType,
    this.kdfIterations,
    this.kdfMemory,
    this.kdfParallelism,
    this.data,
  });

  VaultInvalidType get isValidEncryt {
    if (encrypted &&
        (passwordProtected == null || passwordProtected == false)) {
      return VaultInvalidType.AccountRestricted;
    }
    if (data == null || data!.isEmpty) return VaultInvalidType.DataLoss;
    if (kdfType == null) return VaultInvalidType.ParameterLoss;
    if (salt == null || salt!.isEmpty) return VaultInvalidType.SaltLoss;
    switch (kdfType) {
      case KdfType.Pbkdf2Sha256:
        return kdfIterations != null
            ? VaultInvalidType.Valid
            : VaultInvalidType.ParameterLoss;
      case KdfType.Argon2Id:
        return kdfIterations != null &&
                kdfMemory != null &&
                kdfParallelism != null
            ? VaultInvalidType.Valid
            : VaultInvalidType.ParameterLoss;
      default:
        return VaultInvalidType.ParameterLoss;
    }
  }

  factory Vault.fromJson(Map<String, dynamic> json) {
    List<dynamic> items =
        json['items'] != null ? json['items'] as List<dynamic> : [];
    List<BitwardenItem> bitwardenItems = [];
    for (var item in items) {
      var tmp = BitwardenItem.fromJson(item);
      if (tmp != null) {
        bitwardenItems.add(tmp);
      }
    }
    return Vault(
      folders: json['folders'] != null
          ? (json['folders'] as List<dynamic>)
              .map((e) => BitwardenFolder.fromJson(e))
              .toList()
          : [],
      items: bitwardenItems,
      encKeyValidation: json['encKeyValidation_DO_NOT_EDIT'] as String?,
      encrypted: json['encrypted'] as bool,
      passwordProtected: json['passwordProtected'] as bool?,
      salt: json['salt'] as String?,
      kdfType: json['kdfType'] != null && json['kdfType'] is int
          ? KdfType.values[
              (json['kdfType'] as int).clamp(0, KdfType.values.length - 1)]
          : null,
      kdfIterations: json['kdfIterations'] as int?,
      kdfMemory: json['kdfMemory'] as int?,
      kdfParallelism: json['kdfParallelism'] as int?,
      data: json['data'] as String?,
    );
  }

  @override
  String toString() {
    return 'Vault{folders: $folders, items: $items, encKeyValidation: $encKeyValidation, encrypted: $encrypted, passwordProtected: $passwordProtected, salt: $salt, kdfType: $kdfType, kdfIterations: $kdfIterations, kdfMemory: $kdfMemory, kdfParallelism: $kdfParallelism, data: $data}';
  }
}

class BitwardenItem {
  String uid;
  String name;
  String? folderId;
  int type;
  String? totp;
  String? username;
  bool favorite;

  BitwardenItem({
    required this.uid,
    required this.name,
    required this.folderId,
    required this.type,
    this.totp,
    this.username,
    required this.favorite,
  });

  static BitwardenItem? fromJson(Map<String, dynamic> json) {
    if (json['login'] == null ||
        json['login']['totp'] == null ||
        json['login']['totp'].isEmpty) {
      return null;
    }
    return BitwardenItem(
      favorite: json['favorite'] as bool,
      uid: json['id'] ?? StringUtil.generateUid(),
      name: json['name'] as String,
      folderId: json['folderId'] as String?,
      type: json['type'] as int,
      totp: json['login']['totp'] as String?,
      username: json['login']['username'] as String?,
    );
  }

  List<TokenCategoryBinding> getBindings() {
    return folderId != null
        ? [
            TokenCategoryBinding(
              tokenUid: uid,
              categoryUid: folderId!,
            ),
          ]
        : [];
  }

  OtpToken? toOtpToken() {
    if (totp == null || totp!.isEmpty) {
      return null;
    }
    OtpToken token = OtpToken.init();
    if (totp!.startsWith("otpauth://")) {
      return OtpTokenParser.parseOtpauthUri(Uri.parse(totp!));
    } else if (totp!.startsWith("steam://")) {
      token.tokenType = OtpTokenType.Steam;
      totp = totp!.substring(8);
    } else {
      token.tokenType = OtpTokenType.TOTP;
    }
    token.digits = token.tokenType.defaultDigits;
    token.periodString = token.tokenType.defaultPeriod.toString();
    token.uid = uid;
    token.account = username ?? "";
    token.issuer = name;
    token.pinned = favorite;
    token.secret = totp ?? "";
    return token;
  }
}

class BitwardenTokenImporter implements BaseTokenImporter {
  static const String BaseAlgorithm = "AES";
  static const String Mode = "CBC";
  static const String Padding = "PKCS7";
  static const String AlgorithmDescription = "$BaseAlgorithm/$Mode/$Padding";

  static const int loginType = 1;
  static const int pbkdf2Iterations = 6000;
  static const int argon2IdIterations = 3;
  static const int keyLength = 32;
  static const int saltLength = 16;

  static Vault? decrypt(Vault vault, String password) {
    try {
      var parts = vault.data!.split(".");
      var data = parts[1].split("|");

      if (data.length < 3) {
        debugPrint("Data format is invalid");
        return null;
      }

      Uint8List? key = deriveMainKey(vault, password);
      if (key == null) {
        debugPrint("Failed to derive key");
        return null;
      }

      var iv = base64.decode(data[0]);
      var payload = base64.decode(data[1]);
      var mac = base64.decode(data[2]);

      var encryptionKey = hkdfExpand(key, "enc");
      var macKey = hkdfExpand(key, "mac");

      if (!verifyMac(macKey, iv, payload, mac)) {
        debugPrint("MAC verification failed");
        return null;
      }

      var keyParameter = ParametersWithIV(KeyParameter(encryptionKey), iv);
      var cipher = CBCBlockCipher(AESEngine())..init(false, keyParameter);

      Uint8List decryptedBytes;
      try {
        final decrypted = Uint8List(payload.length);
        var offset = 0;
        while (offset < payload.length) {
          offset += cipher.processBlock(payload, offset, decrypted, offset);
        }
        final padding = PKCS7Padding();
        final padCount = padding.padCount(decrypted);
        decryptedBytes = decrypted.sublist(0, decrypted.length - padCount);
      } catch (e) {
        return null;
      }

      var json = utf8.decode(decryptedBytes);
      return Vault.fromJson(jsonDecode(json));
    } catch (e, t) {
      debugPrint("Failed to decrypt vault: $e\n$t");
      return null;
    }
  }

  static bool verifyMac(
      Uint8List key, Uint8List iv, Uint8List payload, Uint8List expected) {
    var material = Uint8List(iv.length + payload.length);
    material.setRange(0, iv.length, iv);
    material.setRange(iv.length, iv.length + payload.length, payload);

    var hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
    var hash = hmac.process(material);

    return constantTimeAreEqual(hash, expected);
  }

  static Uint8List? deriveMainKey(Vault vault, String password) {
    var passwordBytes = utf8.encode(password);
    final sha256 = SHA256Digest();
    final saltBytes = Uint8List.fromList(utf8.encode(vault.salt!));
    sha256.update(saltBytes, 0, saltBytes.length);
    final saltHash = Uint8List(sha256.digestSize);
    sha256.doFinal(saltHash, 0);

    switch (vault.kdfType) {
      case KdfType.Pbkdf2Sha256:
        return derivePbkdf2Sha256(
          passwordBytes,
          vault.kdfIterations,
          saltBytes,
        );

      case KdfType.Argon2Id:
        return deriveArgon2Id(
          passwordBytes,
          iterations: vault.kdfIterations,
          memory: (vault.kdfMemory ?? 64) * 1024,
          parallelism: vault.kdfParallelism,
          keyLength: keyLength,
          saltHash,
        );

      default:
        throw ArgumentError("Unsupported KDF type");
    }
  }

  static Uint8List derivePbkdf2Sha256(
    Uint8List password,
    int? iterations,
    Uint8List salt,
  ) {
    var generator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations ?? pbkdf2Iterations, keyLength));
    return generator.process(password);
  }

  static Uint8List deriveArgon2Id(
    Uint8List password,
    Uint8List salt, {
    int? memory,
    int? parallelism,
    int? iterations,
    int? keyLength,
  }) {
    final argon2 = Argon2BytesGenerator();
    argon2.init(Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      lanes: parallelism ?? 4,
      iterations: iterations ?? BitwardenTokenImporter.argon2IdIterations,
      memory: memory,
      desiredKeyLength: keyLength ?? BitwardenTokenImporter.keyLength,
    ));
    return argon2.process(password);
  }

  static Uint8List hkdfExpand(Uint8List key, String info) {
    HKDFKeyDerivator generator = HKDFKeyDerivator(SHA256Digest());
    var infoBytes = utf8.encode(info);
    generator.init(HkdfParameters(key, keyLength, null, infoBytes, true));
    final output = Uint8List(keyLength);
    generator.deriveKey(null, 0, output, 0);
    return output;
  }

  static bool constantTimeAreEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  Future<void> import(Vault vault) async {
    List<OtpToken> tokens = [];
    List<TokenCategory> categories = [];
    List<String> usedCategoryUids = [];
    List<TokenCategoryBinding> bindings = [];
    for (var service in vault.items) {
      try {
        OtpToken? token = service.toOtpToken();
        if (token != null) {
          tokens.add(token);
        }
      } finally {}
    }
    bindings = vault.items.expand((e) => e.getBindings()).toList();
    for (var binding in bindings) {
      if (!usedCategoryUids.contains(binding.categoryUid)) {
        usedCategoryUids.add(binding.categoryUid);
      }
    }
    for (var folder in vault.folders) {
      if (usedCategoryUids.contains(folder.uid)) {
        categories.add(TokenCategory.title(
          tUid: folder.uid,
          title: folder.name,
        ));
      }
    }
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
        Vault vault = Vault.fromJson(jsonDecode(content));
        if (vault.encrypted) {
          if (showLoading) dialog.dismiss();
          VaultInvalidType type = vault.isValidEncryt;
          switch (type) {
            case VaultInvalidType.AccountRestricted:
              IToast.showTop(
                  appLocalizations.cannotImportFromBitwardenAccountRestricted);
              return;
            case VaultInvalidType.ParameterLoss:
              IToast.showTop(
                  appLocalizations.cannotImportFromBitwardenParameterLoss);
              return;
            case VaultInvalidType.DataLoss:
              IToast.showTop(
                  appLocalizations.cannotImportFromBitwardenDataLoss);
              return;
            default:
              break;
          }
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
              Vault? res = await compute(
                (receiveMessage) {
                  Vault vault = Vault.fromJson(receiveMessage['data']);
                  return decrypt(vault, receiveMessage["password"] as String);
                },
                {
                  'data': jsonDecode(content),
                  'password': text,
                },
              );
              if (res != null) {
                await import(res);
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
          await import(vault);
        }
      }
    } catch (e, t) {
      ILogger.error("Failed to import from Bitwarden", e, t);
      IToast.showTop(appLocalizations.importFailed);
    } finally {
      if (showLoading) {
        dialog.dismiss();
      }
    }
  }
}
