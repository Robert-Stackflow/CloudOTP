import 'dart:convert';
import 'dart:typed_data';

import './backup.dart';

abstract class BackupEncryptInterface {
  Future<Uint8List> encrypt(Backup backup, String password);

  Future<dynamic> decrypt(Uint8List data, String password);

  bool canBeDecrypted(Uint8List data);
}

class BackupBaseException implements Exception {
  final String message;

  BackupBaseException(this.message);
}

class EmptyPasswordException extends BackupBaseException {
  EmptyPasswordException(super.message);
}

class BackupVersionUnsupportException extends BackupBaseException {
  BackupVersionUnsupportException(super.message);
}

class FileNotBackupException extends BackupBaseException {
  FileNotBackupException(super.message);
}


class InvalidPasswordOrDataCorruptedException extends BackupBaseException {
  InvalidPasswordOrDataCorruptedException(super.message);
}
