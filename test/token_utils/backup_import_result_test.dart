import 'dart:typed_data';

import 'package:cloudotp/TokenUtils/Backup/backup.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_v1.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rejects an oversized backup before decryption', () async {
    final result = await ImportTokenUtil.importUint8List(
      Uint8List(ImportTokenUtil.maxBackupFileBytes + 1),
      password: 'password',
    );

    expect(result.status, BackupImportStatus.fileTooLarge);
    expect(result.isSuccess, isFalse);
    expect(result.shouldRequestPassword, isFalse);
  });

  test('distinguishes invalid format from an invalid password', () async {
    final invalidFormat = await ImportTokenUtil.importUint8List(
      Uint8List.fromList([1, 2, 3]),
      password: 'password',
    );
    final encrypted = await BackupEncryptionV1().encrypt(
      Backup(tokens: const [], categories: const []),
      'correct-password',
    );
    final invalidPassword = await ImportTokenUtil.importUint8List(
      encrypted,
      password: 'wrong-password',
    );

    expect(invalidFormat.status, BackupImportStatus.invalidFormat);
    expect(
      invalidPassword.status,
      BackupImportStatus.invalidPasswordOrCorrupted,
    );
    expect(invalidPassword.shouldRequestPassword, isTrue);
  });

  test('distinguishes an unsupported data version', () async {
    final encrypted = await BackupEncryptionV1().encrypt(
      Backup(
        tokens: const [],
        categories: const [],
        schemaVersion: Backup.currentSchemaVersion + 1,
      ),
      'password',
    );

    final result = await ImportTokenUtil.importUint8List(
      encrypted,
      password: 'password',
    );

    expect(result.status, BackupImportStatus.unsupportedVersion);
    expect(result.shouldRequestPassword, isFalse);
  });

  test('rejects excessive entry counts before parsing every entry', () {
    expect(
      () => Backup.fromJson({
        'tokens': List<String>.filled(Backup.maxTokenEntries + 1, '{}'),
        'categories': const [],
      }),
      throwsA(isA<BackupLimitExceededException>()),
    );
  });
}
