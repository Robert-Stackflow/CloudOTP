import 'dart:convert';
import 'dart:typed_data';

import '../../generated/l10n.dart';
import './backup.dart';

abstract class BackupEncryptInterface {
  Future<Uint8List> encrypt(Backup backup, String password);

  Future<dynamic> decrypt(Uint8List data, String password);

  bool canBeDecrypted(Uint8List data);
}

class BackupBaseException implements Exception {
  final String? message;

  String get intlMessage {
    if (this is EncryptEmptyPasswordException) {
      return S.current.cannotEncryptWithoutPassword;
    } else if (this is DecryptEmptyPasswordException) {
      return S.current.cannotDecryptWithoutPassword;
    } else if (this is BackupVersionUnsupportException) {
      return S.current.backupVersionUnsupport;
    } else if (this is FileNotBackupException) {
      return S.current.fileNotBackup;
    } else if (this is InvalidPasswordOrDataCorruptedException) {
      return S.current.invalidPasswordOrDataCorrupted;
    }
    return message ?? "";
  }

  BackupBaseException({this.message});
}

class EncryptEmptyPasswordException extends BackupBaseException {
  EncryptEmptyPasswordException({super.message});
}

class DecryptEmptyPasswordException extends BackupBaseException {
  DecryptEmptyPasswordException({super.message});
}

class BackupVersionUnsupportException extends BackupBaseException {
  BackupVersionUnsupportException({super.message});
}

class FileNotBackupException extends BackupBaseException {
  FileNotBackupException({super.message});
}

class InvalidPasswordOrDataCorruptedException extends BackupBaseException {
  InvalidPasswordOrDataCorruptedException({super.message});
}
