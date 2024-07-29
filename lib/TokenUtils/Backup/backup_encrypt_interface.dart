import 'dart:convert';
import 'dart:typed_data';


import './backup.dart';

abstract class BackupEncryptInterface {
  Future<Uint8List> encrypt(Backup backup, String password);

  Future<dynamic> decrypt(Uint8List data, String password);

  bool canBeDecrypted(Uint8List data);
}