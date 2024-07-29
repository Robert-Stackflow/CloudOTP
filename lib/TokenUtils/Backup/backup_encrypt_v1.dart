import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
      throw ArgumentError("Cannot encrypt without a password");
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
      throw ArgumentError("Cannot decrypt without a password");
    }

    if (!canBeDecrypted(data)) {
      throw ArgumentError("Header does not match");
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
    } catch (e) {
      throw Exception("Invalid password or data corrupted");
    }

    final json = utf8.decode(unencryptedData);
    return Backup.fromJson(jsonDecode(json));
  }

  @override
  bool canBeDecrypted(Uint8List data) {
    final headerBytes = utf8.encode(header);
    final foundHeader = data.sublist(0, headerBytes.length);
    for (int i = 0; i < headerBytes.length; i++) {
      if (headerBytes[i] != foundHeader[i]) {
        return false;
      }
    }
    return true;
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
