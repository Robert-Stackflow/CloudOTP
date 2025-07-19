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

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:pointycastle/export.dart';

import './backup_encrypt_interface.dart';
import 'backup.dart';

class BackupEncryptionV1 implements BackupEncryptInterface {
  static const String header = "CloudOTP-Backup-Encrypt-V01";

  static const int iterations = 3;
  static const int memorySize = 65536;
  static const int saltLength = 16;
  static const int keyLength = 32;

  static const String baseAlgorithm = "AES";
  static const String mode = "GCM";
  static const int ivLength = 12;
  static const int tagLength = 16;

  @override
  Future<Uint8List> encrypt(Backup backup, String password) async {
    if (password.isEmpty) {
      throw EncryptEmptyPasswordException();
    }

    final random = SecureRandom("Fortuna")
      ..seed(KeyParameter(Uint8List.fromList(List.generate(32, (_) => 1))));
    final salt = random.nextBytes(saltLength);
    final iv = random.nextBytes(ivLength);

    final key = deriveKey(password, salt);
    final parameters =
        AEADParameters(KeyParameter(key), tagLength * 8, iv, Uint8List(0));

    final cipher = GCMBlockCipher(AESEngine())..init(true, parameters);

    final unencryptedData = utf8.encode(backup.json);
    final encryptedData = cipher.process(Uint8List.fromList(unencryptedData));

    final headerBytes = utf8.encode(header);
    final output = Uint8List(
        headerBytes.length + saltLength + ivLength + encryptedData.length);

    output.setRange(0, headerBytes.length, headerBytes);
    output.setRange(headerBytes.length, headerBytes.length + saltLength, salt);
    output.setRange(headerBytes.length + saltLength,
        headerBytes.length + saltLength + ivLength, iv);
    output.setRange(headerBytes.length + saltLength + ivLength, output.length,
        encryptedData);

    return output;
  }

  @override
  Future<Backup> decrypt(Uint8List data, String password) async {
    if (password.isEmpty) {
      throw DecryptEmptyPasswordException();
    }

    if (!canBeDecrypted(data)) {
      throw BackupVersionUnsupportException();
    }

    final headerBytes = utf8.encode(header);
    final salt =
        data.sublist(headerBytes.length, headerBytes.length + saltLength);
    final iv = data.sublist(headerBytes.length + saltLength,
        headerBytes.length + saltLength + ivLength);
    final encryptedData =
        data.sublist(headerBytes.length + saltLength + ivLength);

    final key = deriveKey(password, salt);
    final parameters =
        AEADParameters(KeyParameter(key), tagLength * 8, iv, Uint8List(0));

    final cipher = GCMBlockCipher(AESEngine())..init(false, parameters);

    Uint8List unencryptedData;

    try {
      unencryptedData = cipher.process(encryptedData);
    } catch (e, t) {
      ILogger.error(
          "Failed to decrypt data (InvalidPasswordOrDataCorruptedException)",
          e,
          t);
      throw InvalidPasswordOrDataCorruptedException();
    }

    final json = utf8.decode(unencryptedData);
    Backup res = Backup.fromJson(jsonDecode(json));
    return res;
  }

  @override
  bool canBeDecrypted(Uint8List data) {
    try {
      final headerBytes = utf8.encode(header);
      final foundHeader = data.sublist(0, headerBytes.length);
      for (int i = 0; i < headerBytes.length; i++) {
        if (headerBytes[i] != foundHeader[i]) {
          return false;
        }
      }
      return true;
    } catch (e, t) {
      ILogger.error("Failed to decrypt (FileNotBackupException)", e, t);
      throw FileNotBackupException();
    }
  }

  Uint8List deriveKey(String password, Uint8List salt) {
    final argon2 = Argon2BytesGenerator();
    argon2.init(Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      iterations: iterations,
      memory: memorySize,
      desiredKeyLength: keyLength,
    ));
    final key = argon2.process(Uint8List.fromList(utf8.encode(password)));
    return Uint8List.fromList(key);
  }
}
