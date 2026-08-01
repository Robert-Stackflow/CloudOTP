import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudotp/TokenUtils/Backup/backup.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_interface.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_old.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_v1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('legacy backup encryption', () {
    test('decrypts the historical base64 encoded format', () async {
      const password = 'legacy-password';
      final cipher = BackupEncryptionOld();
      final encoded = await cipher.getEncryptedData(password, []);
      final bytes = Uint8List.fromList(utf8.encode(encoded));

      expect(cipher.canBeDecrypted(bytes), isTrue);
      expect(await cipher.decrypt(bytes, password), isEmpty);
    });

    test('rejects data that is not a legacy backup', () async {
      final cipher = BackupEncryptionOld();
      final bytes = Uint8List.fromList(utf8.encode('not-base64!'));

      expect(cipher.canBeDecrypted(bytes), isFalse);
      expect(
        () => cipher.decrypt(bytes, 'password'),
        throwsA(isA<FileNotBackupException>()),
      );
    });
  });

  group('version 1 backup encryption', () {
    test('round trips an empty backup', () async {
      final cipher = BackupEncryptionV1();
      final encrypted = await cipher.encrypt(
        Backup(tokens: const [], categories: const []),
        'strong-password',
      );

      final decrypted = await cipher.decrypt(encrypted, 'strong-password');

      expect(decrypted.tokens, isEmpty);
      expect(decrypted.categories, isEmpty);
    });

    test('detects tampering', () async {
      final cipher = BackupEncryptionV1();
      final encrypted = await cipher.encrypt(
        Backup(tokens: const [], categories: const []),
        'strong-password',
      );
      encrypted[encrypted.length - 1] ^= 1;

      expect(
        () => cipher.decrypt(encrypted, 'strong-password'),
        throwsA(isA<InvalidPasswordOrDataCorruptedException>()),
      );
    });
  });
}
