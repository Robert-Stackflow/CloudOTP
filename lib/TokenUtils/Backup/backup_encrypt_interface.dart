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

import 'dart:typed_data';

import '../../l10n/l10n.dart';
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
      return appLocalizations.cannotEncryptWithoutPassword;
    } else if (this is DecryptEmptyPasswordException) {
      return appLocalizations.cannotDecryptWithoutPassword;
    } else if (this is BackupVersionUnsupportException) {
      return appLocalizations.backupVersionUnsupport;
    } else if (this is FileNotBackupException) {
      return appLocalizations.fileNotBackup;
    } else if (this is InvalidPasswordOrDataCorruptedException) {
      return appLocalizations.invalidPasswordOrDataCorrupted;
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
