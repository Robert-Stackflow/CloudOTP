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
import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pointycastle;

import '../../Models/opt_token.dart';
import '../../Utils/ilogger.dart';
import 'backup.dart';
import 'backup_encrypt_interface.dart';

class BackupEncryptionOld implements BackupEncryptInterface {
  Future<String> getEncryptedData(
      String password, List<OtpToken> otpTokens) async {
    final json = jsonEncode(otpTokens.map((token) => token.toJson()).toList());
    final key =
        await AESStringCipher.generateKeyFromPassword(password, password);
    final encryptedData = AESStringCipher.encrypt(json, key);
    return encryptedData;
  }

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
    final decryptedJson = AESStringCipher.decrypt(encryptedData, key);
    if (decryptedJson.isEmpty) return null;
    final List<dynamic> jsonList = jsonDecode(decryptedJson);
    return jsonList.map((json) => OtpToken.fromJson(json)).toList();
  }

  @override
  bool canBeDecrypted(Uint8List data) {
    try {
      base64.decode(utf8.decode(data));
      return true;
    } catch (e, t) {
      ILogger.error(
          "CloudOTP", "Failed to decrypt from wrong format data", e, t);
      return false;
    }
  }
}

class AESStringCipher {
  static const int IV_LENGTH_BYTES = 16;
  static const int AES_KEY_LENGTH_BITS = 128;
  static const int HMAC_KEY_LENGTH_BITS = 128;

  static Future<Uint8List> generateKeyFromPassword(
    String password,
    String salt,
  ) async {
    final pbkdf2 = pointycastle.PBKDF2KeyDerivator(
        pointycastle.HMac(pointycastle.SHA256Digest(), HMAC_KEY_LENGTH_BITS))
      ..init(pointycastle.Pbkdf2Parameters(
        utf8.encode(salt),
        1000,
        AES_KEY_LENGTH_BITS ~/ 8,
      ));
    return pbkdf2.process(utf8.encode(password));
  }

  static Uint8List _generateIv(int length) {
    final random = pointycastle.SecureRandom("Fortuna")
      ..seed(pointycastle.KeyParameter(
          Uint8List.fromList(List.generate(32, (_) => 1))));
    return random.nextBytes(length);
  }

  static String encrypt(String plaintext, Uint8List key) {
    final iv = _generateIv(IV_LENGTH_BYTES);
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
    final iv = data.sublist(0, IV_LENGTH_BYTES);
    final encryptedData = data.sublist(IV_LENGTH_BYTES);
    final cipher = pointycastle.GCMBlockCipher(pointycastle.AESEngine())
      ..init(
          false,
          pointycastle.AEADParameters(pointycastle.KeyParameter(key),
              AES_KEY_LENGTH_BITS, iv, Uint8List(0)));

    try {
      final decryptedData = cipher.process(encryptedData);
      return utf8.decode(decryptedData);
    } catch (e, t) {
      ILogger.error("CloudOTP", "Failed to decrypt data", e, t);
    }
    return "";
  }
}
