import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
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
      expect(decrypted.schemaVersion, Backup.currentSchemaVersion);
    });

    test('round trips versioned metadata and direct model maps', () async {
      final token = OtpToken.init(
        issuer: 'Issuer',
        secret: 'JBSWY3DPEHPK3PXP',
      )..account = 'metadata@example.com';
      final category = TokenCategory.title(title: 'Metadata')
        ..bindings = [token.uid];
      final cipher = BackupEncryptionV1();

      final encrypted = await cipher.encrypt(
        Backup(
          tokens: [token],
          categories: [category],
          createdAt: 1234,
          appVersion: '2.0.0',
          sourceDevice: 'test-device',
        ),
        'strong-password',
      );
      final decrypted = await cipher.decrypt(encrypted, 'strong-password');

      expect(decrypted.createdAt, 1234);
      expect(decrypted.appVersion, '2.0.0');
      expect(decrypted.sourceDevice, 'test-device');
      expect(decrypted.tokens.single.uid, token.uid);
      expect(decrypted.categories.single.bindings, [token.uid]);
    });

    test('reports a future data schema as unsupported', () async {
      final cipher = BackupEncryptionV1();
      final encrypted = await cipher.encrypt(
        Backup(
          tokens: const [],
          categories: const [],
          schemaVersion: Backup.currentSchemaVersion + 1,
        ),
        'strong-password',
      );

      expect(
        () => cipher.decrypt(encrypted, 'strong-password'),
        throwsA(isA<BackupVersionUnsupportException>()),
      );
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

  group('backup data compatibility', () {
    test('reads the legacy unversioned string-entry payload', () {
      final token = OtpToken.init(
        issuer: 'Legacy',
        secret: 'JBSWY3DPEHPK3PXP',
      )..account = 'legacy@example.com';
      final category = TokenCategory.title(title: 'Legacy')
        ..bindings = [token.uid];

      final backup = Backup.fromJson({
        'tokens': [token.toJson()],
        'categories': [category.toJsonWithBindings()],
      });

      expect(backup.schemaVersion, 1);
      expect(backup.createdAt, 0);
      expect(backup.tokens.single.uid, token.uid);
      expect(backup.categories.single.bindings, [token.uid]);
    });

    test('rejects metadata counts that do not match the content', () {
      final json = Backup(tokens: const [], categories: const []).toJson();
      json['tokenCount'] = 1;

      expect(
        () => Backup.fromJson(json),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}
