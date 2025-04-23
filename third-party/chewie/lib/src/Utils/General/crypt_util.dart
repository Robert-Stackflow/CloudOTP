import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class CryptUtil {
  static dynamic encryptDataByAES(
    Map<String, dynamic> data,
    String rawKey,
    String rawIv,
  ) {
    final key = Key.fromUtf8(rawKey);
    final iv = IV.fromUtf8(rawIv);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(json.encode(data), iv: iv);
    return encrypted.base64;
  }

  static decryptDataByAES(
    List<int> encrypted,
    String rawKey,
    String rawIv,
  ) {
    final key = Key.fromUtf8(rawKey);
    final iv = IV.fromUtf8(rawIv);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final decrypted =
        encrypter.decrypt(Encrypted(Uint8List.fromList(encrypted)), iv: iv);
    return decrypted;
  }

  static String encryptDataByRSA(
    String data,
    String publicKey,
  ) {
    final key = RSAKeyParser().parse(
        "-----BEGIN PUBLIC KEY-----\n$publicKey\n-----END PUBLIC KEY-----");
    final encrypter = Encrypter(RSA(publicKey: key as RSAPublicKey));
    final encrypted = encrypter.encrypt(data);
    return encrypted.base64;
  }
}
