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
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pointycastle;

import '../../Models/opt_token.dart';
import 'backup.dart';
import 'backup_encrypt_interface.dart';

@Deprecated('Legacy format — only used for decrypting old backups. '
    'New backups must use BackupEncryptionV1.')
class BackupEncryptionOld implements BackupEncryptInterface {
  @Deprecated('Do not encrypt with this format — uses password as salt.')
  Future<String> getEncryptedData(
      String password, List<OtpToken> otpTokens) async {
    final json = jsonEncode(otpTokens.map((token) => token.toJson()).toList());
    final key =
        await AESStringCipher.generateKeyFromPassword(password, password);
    final encryptedData = AESStringCipher.encrypt(json, key);
    return encryptedData;
  }

  @Deprecated('Do not encrypt with this format — uses password as salt.')
  @override
  Future<Uint8List> encrypt(Backup backup, String password) async {
    final key =
        await AESStringCipher.generateKeyFromPassword(password, password);
    final encryptedData = AESStringCipher.encrypt(backup.json, key);
    return Uint8List.fromList(utf8.encode(encryptedData));
  }

  @override
  Future<dynamic> decrypt(Uint8List encryptedData, String password) async {
    final key =
        await AESStringCipher.generateKeyFromPassword(password, password);
    Uint8List decodedData;
    try {
      decodedData = base64.decode(utf8.decode(encryptedData));
    } on FormatException {
      throw FileNotBackupException();
    }
    final decryptedJson = AESStringCipher.decrypt(decodedData, key);
    if (decryptedJson.isEmpty) return null;
    final List<dynamic> jsonList = jsonDecode(decryptedJson);
    return jsonList.map((json) => OtpToken.fromJson(json)).toList();
  }

  @override
  bool canBeDecrypted(Uint8List data) {
    try {
      base64.decode(utf8.decode(data));
      return true;
    } catch (_) {
      return false;
    }
  }
}

class AESStringCipher {
  static const int ivLengthBytes = 16;
  static const int aesKeyLengthBits = 128;
  static const int hmacKeyLengthBits = 128;

  static Future<Uint8List> generateKeyFromPassword(
    String password,
    String salt,
  ) async {
    final pbkdf2 = pointycastle.PBKDF2KeyDerivator(
        pointycastle.HMac(pointycastle.SHA256Digest(), hmacKeyLengthBits))
      ..init(pointycastle.Pbkdf2Parameters(
        utf8.encode(salt),
        1000,
        aesKeyLengthBits ~/ 8,
      ));
    return pbkdf2.process(utf8.encode(password));
  }

  static Uint8List _generateIv(int length) {
    final secureRandom = Random.secure();
    return Uint8List.fromList(
        List.generate(length, (_) => secureRandom.nextInt(256)));
  }

  static String encrypt(String plaintext, Uint8List key) {
    final iv = _generateIv(ivLengthBytes);
    final cipher = pointycastle.GCMBlockCipher(pointycastle.AESEngine())
      ..init(
          true,
          pointycastle.AEADParameters(
              pointycastle.KeyParameter(key), 128, iv, Uint8List(0)));
    final encryptedData =
        cipher.process(Uint8List.fromList(utf8.encode(plaintext)));

    final combined = Uint8List(iv.length + encryptedData.length);
    combined
      ..setRange(0, iv.length, iv)
      ..setRange(iv.length, combined.length, encryptedData);

    return base64.encode(combined);
  }

  static String decrypt(Uint8List data, Uint8List key) {
    final iv = data.sublist(0, ivLengthBytes);
    final encryptedData = data.sublist(ivLengthBytes);
    final cipher = pointycastle.GCMBlockCipher(pointycastle.AESEngine())
      ..init(
          false,
          pointycastle.AEADParameters(pointycastle.KeyParameter(key),
              aesKeyLengthBits, iv, Uint8List(0)));

    try {
      final decryptedData = cipher.process(encryptedData);
      return utf8.decode(decryptedData);
    } catch (_) {}
    return "";
  }
}
