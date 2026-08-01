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
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/Database/create_table_sql.dart';
import 'package:cloudotp/Database/database_migrations.dart';
import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Models/token_category_binding.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

import '../Utils/hive_util.dart';

enum EncryptDatabaseStatus { defaultPassword, customPassword }

class DatabaseManager {
  static const _dbName = "cloudotp.db";
  static const _unencrypedFileHeader = "SQLite format 3";
  static const _dbVersion = 9;
  static Database? _database;
  static final dbFactory = createDatabaseFactoryFfi();
  static DynamicLibrary? lib = loadSqlcipher();
  static final cipherDbFactory = createDatabaseFactoryFfi(ffiInit: () {
    if (lib != null) open.overrideForAll(() => lib!);
  });
  static bool isDatabaseEncrypted = false;
  static bool isNewDatabase = false;

  static const List<String> _dataTables = [
    'otp_token',
    'token_category',
    'cloudotp_config',
    'cloud_service_config',
    'auto_update_log',
    'token_category_binding',
  ];

  static bool get initialized => _database != null;

  static Future<Database> getDataBase() async {
    if (_database == null) {
      await initDataBase("");
    }
    return _database!;
  }

  static resetDatabase() async {
    await _database?.close();
    _database = null;
  }

  static Future<void> initDataBase(String password) async {
    if (_database != null) {
      await ConfigDao.initConfig();
      return;
    }

    final path = await _getDatabasePath();
    final file = File(path);
    isNewDatabase = !file.existsSync();

    if (isNewDatabase) {
      password = await CloudOTPHiveUtil.regeneratePassword();
      isDatabaseEncrypted = true;
      _database = await _openDatabase(path, password, encrypted: true);
      await CloudOTPHiveUtil.setEncryptDatabaseStatus(
          EncryptDatabaseStatus.defaultPassword);
      ILogger.info('Created a new encrypted database');
    } else if (await _hasPlaintextHeader(file)) {
      isDatabaseEncrypted = false;
      _database = await _openDatabase(path, '', encrypted: false);
      ILogger.warning('Opened a legacy unencrypted SQLite database');
    } else {
      isDatabaseEncrypted = true;
      try {
        _database = await _openDatabase(path, password, encrypted: true);
        await _clearUnusedPendingPassword();
      } catch (activePasswordError) {
        final pending = await CloudOTPHiveUtil.getPendingDatabasePassword();
        if (pending == null || pending.isEmpty || pending == password) {
          rethrow;
        }
        ILogger.warning(
            'Active database password failed; trying recoverable pending key');
        _database = await _openDatabase(path, pending, encrypted: true);
        await CloudOTPHiveUtil.promotePendingDatabasePassword();
        password = pending;
        ILogger.info('Recovered database password after interrupted rekey');
      }
    }

    appProvider.currentDatabasePassword = password;
    await ConfigDao.initConfig();
  }

  static Future<String> _getDatabasePath() async =>
      join(await FileUtil.getDatabaseDir(), _dbName);

  static Future<bool> _hasPlaintextHeader(File file) async {
    if (await file.length() < _unencrypedFileHeader.length) return false;
    final bytes = await file
        .openRead(0, _unencrypedFileHeader.length)
        .fold<List<int>>([], (previous, element) => previous..addAll(element));
    return String.fromCharCodes(bytes) == _unencrypedFileHeader;
  }

  static Future<Database> _openDatabase(
    String path,
    String password, {
    required bool encrypted,
    bool singleInstance = true,
  }) async {
    if (encrypted && lib == null) throw const SqlCipherUnavailableException();
    Database? candidate;
    try {
      candidate = await (encrypted ? cipherDbFactory : dbFactory).openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          singleInstance: singleInstance,
          onConfigure: (db) async {
            if (encrypted) await _configureEncryptedDatabase(db, password);
          },
          onUpgrade: _onUpgrade,
          onCreate: _onCreate,
        ),
      );
      await candidate.rawQuery('SELECT count(*) FROM sqlite_master');
      if (encrypted) await _verifyIntegrity(candidate);
      return candidate;
    } catch (_) {
      await candidate?.close();
      rethrow;
    }
  }

  static Future<void> _assertSqlCipher(Database db) async {
    final result = await db.rawQuery('PRAGMA cipher_version');
    if (result.isEmpty || result.first.values.every((value) => value == null)) {
      throw const SqlCipherUnavailableException();
    }
  }

  static Future<void> _verifyIntegrity(Database db) async {
    final result = await db.rawQuery('PRAGMA integrity_check');
    if (result.isEmpty || result.first.values.first.toString() != 'ok') {
      throw DatabaseIntegrityException(result.toString());
    }
  }

  static Future<void> _clearUnusedPendingPassword() async {
    try {
      final pending = await CloudOTPHiveUtil.getPendingDatabasePassword();
      if (pending != null && pending.isNotEmpty) {
        await CloudOTPHiveUtil.clearPendingDatabasePassword();
        ILogger.info('Cleared an unused pending database password');
      }
    } catch (e, t) {
      ILogger.warning('Failed to clear pending database password', e, t);
    }
  }

  static Future<void> clearSampleDataFlag() async {
    if (_database == null) return;
    final db = _database!;
    final tokens =
        await db.query('otp_token', where: "remark LIKE '%is_example%'");
    for (final row in tokens) {
      final remark = Map<String, dynamic>.from(
          jsonDecode(row['remark'] as String? ?? '{}'));
      remark.remove('is_example');
      await db.update(
        'otp_token',
        {'remark': jsonEncode(remark)},
        where: 'uid = ?',
        whereArgs: [row['uid']],
      );
    }
    final categories =
        await db.query('token_category', where: "remark LIKE '%is_example%'");
    for (final row in categories) {
      final remark = Map<String, dynamic>.from(
          jsonDecode(row['remark'] as String? ?? '{}'));
      remark.remove('is_example');
      await db.update(
        'token_category',
        {'remark': jsonEncode(remark)},
        where: 'uid = ?',
        whereArgs: [row['uid']],
      );
    }
  }

  static Future<bool> hasSampleData() async {
    if (_database == null) return false;
    final db = _database!;
    final tokens =
        await db.query('otp_token', where: "remark LIKE '%is_example%'");
    return tokens.isNotEmpty;
  }

  static Future<void> deleteSampleData() async {
    if (_database == null) return;
    final db = _database!;
    final tokens =
        await db.query('otp_token', where: "remark LIKE '%is_example%'");
    for (final row in tokens) {
      final uid = row['uid'] as String;
      await db.delete('token_category_binding',
          where: 'token_uid = ?', whereArgs: [uid]);
      await db.delete('otp_token', where: 'uid = ?', whereArgs: [uid]);
    }
    await db.delete('token_category', where: "remark LIKE '%is_example%'");
  }

  static Future<void> updateSampleCategoryTitle(String title) async {
    if (_database == null) return;
    final db = _database!;
    await db.update(
      'token_category',
      {'title': title},
      where: "remark LIKE '%is_example%'",
    );
  }

  static String _escapeSql(String value) => value.replaceAll("'", "''");

  static Future<bool> changePassword(
    String password, {
    bool clearStoredDefault = false,
  }) async {
    if (_database == null || password.isEmpty) return false;
    if (!isDatabaseEncrypted) {
      final migrated = await _migratePlaintextDatabase(password);
      if (migrated && clearStoredDefault) {
        try {
          await CloudOTPHiveUtil.clearDefaultDatabasePassword();
        } catch (e, t) {
          ILogger.warning('Failed to clear obsolete default password', e, t);
        }
      }
      return migrated;
    }

    final oldPassword = appProvider.currentDatabasePassword;
    final escaped = _escapeSql(password);
    try {
      await _assertSqlCipher(_database!);
      await _database!.execute("PRAGMA rekey='$escaped'");
      await _verifyEncryptedFile(password);
      appProvider.currentDatabasePassword = password;
      if (clearStoredDefault) {
        try {
          await CloudOTPHiveUtil.clearDefaultDatabasePassword();
        } catch (e, t) {
          ILogger.warning('Failed to clear obsolete default password', e, t);
        }
      }
      return true;
    } catch (e, t) {
      ILogger.error('Failed to rekey encrypted database', e, t);
      if (oldPassword.isNotEmpty && oldPassword != password) {
        try {
          final oldEscaped = _escapeSql(oldPassword);
          await _database!.execute("PRAGMA rekey='$oldEscaped'");
          await _verifyEncryptedFile(oldPassword);
          appProvider.currentDatabasePassword = oldPassword;
          ILogger.info('Restored previous database password after failure');
        } catch (rollbackError, rollbackTrace) {
          ILogger.fatal(
            'Failed to restore previous database password',
            rollbackError,
            rollbackTrace,
          );
        }
      }
      return false;
    }
  }

  static Future<bool> resetToDefaultPassword() async {
    if (_database == null) return false;
    final oldPassword = appProvider.currentDatabasePassword;
    final password = CloudOTPHiveUtil.generateDatabasePassword();
    try {
      await CloudOTPHiveUtil.stageDatabasePassword(password);
      final changed = await changePassword(password);
      if (!changed) {
        await CloudOTPHiveUtil.clearPendingDatabasePassword();
        return false;
      }
      try {
        await CloudOTPHiveUtil.promotePendingDatabasePassword();
        return true;
      } catch (e, t) {
        ILogger.error('Failed to promote new default database password', e, t);
        final rolledBack = await changePassword(oldPassword);
        if (rolledBack) {
          await CloudOTPHiveUtil.clearPendingDatabasePassword();
        }
        return false;
      }
    } catch (e, t) {
      ILogger.error('Failed to prepare a new default database password', e, t);
      return false;
    }
  }

  static Future<void> _configureEncryptedDatabase(
      Database db, String password) async {
    if (password.isEmpty) throw const InvalidDatabasePasswordException();
    await _assertSqlCipher(db);
    final escaped = _escapeSql(password);
    await db.execute("PRAGMA key='$escaped'");
    await db.rawQuery('SELECT count(*) FROM sqlite_master');
  }

  static Future<void> _verifyEncryptedFile(String password) async {
    final path = await _getDatabasePath();
    final verifier = await _openDatabase(path, password,
        encrypted: true, singleInstance: false);
    await verifier.close();
  }

  static Future<Map<String, int>> _getTableCounts(Database db) async {
    final counts = <String, int>{};
    for (final table in _dataTables) {
      final exists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table],
      );
      if (exists.isEmpty) continue;
      final result =
          await db.rawQuery('SELECT COUNT(*) AS count FROM "$table"');
      counts[table] = (result.first['count'] as num).toInt();
    }
    return counts;
  }

  static Future<bool> _migratePlaintextDatabase(String password) async {
    if (_database == null || lib == null) return false;
    final path = await _getDatabasePath();
    final sourceFile = File(path);
    final tempFile = File('$path.encrypted.tmp');
    final backupFile =
        File('$path.unencrypted.${DateTime.now().millisecondsSinceEpoch}.bak');
    final sourceCounts = await _getTableCounts(_database!);
    final versionResult = await _database!.rawQuery('PRAGMA user_version');
    final userVersion =
        (versionResult.first.values.first as num?)?.toInt() ?? _dbVersion;

    Database? sourceWithCipher;
    var originalMoved = false;
    try {
      if (await tempFile.exists()) await tempFile.delete();
      await _database!.rawQuery('PRAGMA wal_checkpoint(FULL)');
      await _database!.close();
      _database = null;

      sourceWithCipher = await cipherDbFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          singleInstance: false,
          onConfigure: _assertSqlCipher,
        ),
      );
      final tempPath = _escapeSql(tempFile.absolute.path);
      final escapedPassword = _escapeSql(password);
      await sourceWithCipher.execute(
          "ATTACH DATABASE '$tempPath' AS encrypted KEY '$escapedPassword'");
      try {
        await sourceWithCipher.rawQuery("SELECT sqlcipher_export('encrypted')");
        await sourceWithCipher
            .execute('PRAGMA encrypted.user_version=$userVersion');
      } finally {
        await sourceWithCipher.execute('DETACH DATABASE encrypted');
      }
      await sourceWithCipher.close();
      sourceWithCipher = null;

      final verifier = await _openDatabase(
        tempFile.path,
        password,
        encrypted: true,
        singleInstance: false,
      );
      final migratedCounts = await _getTableCounts(verifier);
      await verifier.close();
      if (!_mapEquals(sourceCounts, migratedCounts)) {
        throw DatabaseMigrationException(
          'Row counts differ: source=$sourceCounts, migrated=$migratedCounts',
        );
      }

      await sourceFile.rename(backupFile.path);
      originalMoved = true;
      try {
        await tempFile.rename(path);
      } catch (_) {
        await backupFile.rename(path);
        originalMoved = false;
        rethrow;
      }

      _database = await _openDatabase(path, password, encrypted: true);
      final finalCounts = await _getTableCounts(_database!);
      if (!_mapEquals(sourceCounts, finalCounts)) {
        throw DatabaseMigrationException(
          'Final row counts differ: source=$sourceCounts, final=$finalCounts',
        );
      }
      isDatabaseEncrypted = true;
      appProvider.currentDatabasePassword = password;
      try {
        if (await backupFile.exists()) await backupFile.delete();
      } catch (e, t) {
        ILogger.warning(
            'Encrypted database is valid, but plaintext backup cleanup failed',
            e,
            t);
      }
      return true;
    } catch (e, t) {
      ILogger.error('Failed to migrate plaintext database', e, t);
      await sourceWithCipher?.close();
      await _database?.close();
      _database = null;
      if (originalMoved && await backupFile.exists()) {
        if (await sourceFile.exists()) await sourceFile.delete();
        await backupFile.rename(path);
      }
      if (await sourceFile.exists()) {
        _database = await _openDatabase(path, '', encrypted: false);
        isDatabaseEncrypted = false;
        appProvider.currentDatabasePassword = '';
      }
      return false;
    } finally {
      try {
        if (await tempFile.exists()) await tempFile.delete();
      } catch (e, t) {
        ILogger.warning('Failed to clean database migration temp file', e, t);
      }
    }
  }

  static bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(Sql.createTokenTable.sql);
    await db.execute(Sql.createCategoryTable.sql);
    await db.execute(Sql.createConfigTable.sql);
    await db.execute(Sql.createCloudServiceConfigTable.sql);
    await db.execute(Sql.createAutoBackupLogTable.sql);
    await db.execute(Sql.createTokenCategoryBindingTable.sql);
    await DatabaseMigrations.createIndexes(db);
    await _insertSampleData(db);
  }

  static Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remark = jsonEncode({'is_example': true});

    final token1Uid = StringUtil.generateUid();
    final token2Uid = StringUtil.generateUid();
    final token3Uid = StringUtil.generateUid();
    final categoryUid = StringUtil.generateUid();

    await db.insert('otp_token', {
      'id': 1,
      'uid': token1Uid,
      'seq': 1,
      'issuer': 'Google',
      'secret': 'JBSWY3DPEHPK3PXP',
      'account': 'user@example.com',
      'image_path': 'google.png',
      'token_type': OtpTokenType.TOTP.index,
      'algorithm': 'SHA1',
      'digits': 6,
      'counter': 0,
      'period': 30,
      'pinned': 0,
      'create_timestamp': now,
      'edit_timestamp': now,
      'remark': remark,
      'copy_times': 0,
      'pin': '',
      'last_copy_timestamp': 0,
      'description': '',
      'tags': '',
    });

    await db.insert('otp_token', {
      'id': 2,
      'uid': token2Uid,
      'seq': 2,
      'issuer': 'Steam',
      'secret': 'JBSWY3DPEHPK3PXQ',
      'account': 'gamer',
      'image_path': 'steam.png',
      'token_type': OtpTokenType.Steam.index,
      'algorithm': 'SHA1',
      'digits': 5,
      'counter': 0,
      'period': 30,
      'pinned': 0,
      'create_timestamp': now,
      'edit_timestamp': now,
      'remark': remark,
      'copy_times': 0,
      'pin': '',
      'last_copy_timestamp': 0,
      'description': '',
      'tags': '',
    });

    await db.insert('otp_token', {
      'id': 3,
      'uid': token3Uid,
      'seq': 3,
      'issuer': 'Yandex',
      'secret': 'JBSWY3DPEHPK3PXR',
      'account': 'user@yandex.com',
      'image_path': 'yandex.png',
      'token_type': OtpTokenType.Yandex.index,
      'algorithm': 'SHA256',
      'digits': 8,
      'counter': 0,
      'period': 30,
      'pinned': 0,
      'create_timestamp': now,
      'edit_timestamp': now,
      'remark': remark,
      'copy_times': 0,
      'pin': '1234567890123456',
      'last_copy_timestamp': 0,
      'description': '',
      'tags': '',
    });

    await db.insert('token_category', {
      'id': 1,
      'uid': categoryUid,
      'seq': 1,
      'title': 'Example',
      'description': '',
      'create_timestamp': now,
      'edit_timestamp': now,
      'pinned': 0,
      'remark': remark,
    });

    await db.insert('token_category_binding', {
      'token_uid': token1Uid,
      'category_uid': categoryUid,
    });
    await db.insert('token_category_binding', {
      'token_uid': token2Uid,
      'category_uid': categoryUid,
    });
    await db.insert('token_category_binding', {
      'token_uid': token3Uid,
      'category_uid': categoryUid,
    });
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "alter table otp_token add column description TEXT NOT NULL DEFAULT ''");
      await db.execute(
          "alter table cloud_service_config add column enabled INTEGER NOT NULL DEFAULT 1");
    }
    if (oldVersion < 3) {
      await db.execute(
          "alter table cloud_service_config add column total_size INTEGER NOT NULL DEFAULT -1");
      await db.execute(
          "alter table cloud_service_config add column remaining_size INTEGER NOT NULL DEFAULT -1");
      await db.execute(
          "alter table cloud_service_config add column used_size INTEGER NOT NULL DEFAULT -1");
    }
    if (oldVersion < 4) {
      if (!(await isColumnExist("cloud_service_config", "email",
          overrideDb: db))) {
        await db.execute(
            "alter table cloud_service_config add column email TEXT NOT NULL DEFAULT ''");
      }
    }
    if (oldVersion < 5) {
      await db.execute(
          "alter table cloud_service_config add column configured INTEGER NOT NULL DEFAULT 0");
    }
    if (oldVersion < 6) {
      if (!(await isColumnExist("otp_token", "uid", overrideDb: db))) {
        await db.execute(
            "alter table otp_token add column uid TEXT NOT NULL DEFAULT ''");
      }
      if (!(await isColumnExist("token_category", "uid", overrideDb: db))) {
        await db.execute(
            "alter table token_category add column uid TEXT NOT NULL DEFAULT ''");
      }
      await updateToV6(db);
      if ((await isColumnExist("token_category", "token_ids",
          overrideDb: db))) {
        await db.execute(
            "create table temp as select id,uid,seq,title,description,create_timestamp,edit_timestamp,pinned,remark from token_category where 1=1;");
        await db.execute("drop table token_category");
        await db.execute("alter table temp rename to token_category");
      }
    }
    if (oldVersion < 7) {
      if (!(await isColumnExist("otp_token", "tags", overrideDb: db))) {
        await db.execute(
            "alter table otp_token add column tags TEXT NOT NULL DEFAULT ''");
      }
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE token_category_binding_new (
          token_uid INTEGER NOT NULL,
          category_uid INTEGER NOT NULL,
          UNIQUE(token_uid, category_uid)
        )
      ''');
      await db.execute('''
        INSERT OR IGNORE INTO token_category_binding_new (token_uid, category_uid)
        SELECT DISTINCT token_uid, category_uid FROM token_category_binding
      ''');
      await db.execute('DROP TABLE token_category_binding');
      await db.execute(
          'ALTER TABLE token_category_binding_new RENAME TO token_category_binding');
    }
    if (oldVersion < 9) {
      await DatabaseMigrations.upgradeToV9(db);
    }
  }

  static updateToV6(Database db) async {
    if (!(await isTableExist(BindingDao.tableName, overrideDb: db))) {
      await db.execute(Sql.createTokenCategoryBindingTable.sql);
    }
    List<OtpToken> tokens = await TokenDao.listTokens(overrideDb: db);
    for (OtpToken token in tokens) {
      token.uid = StringUtil.generateUid();
    }
    await TokenDao.updateTokens(tokens, autoBackup: false, overrideDb: db);
    List<TokenCategory> categories =
        await CategoryDao.listCategories(overrideDb: db);
    List<TokenCategoryBinding> bindings = [];
    for (TokenCategory category in categories) {
      category.uid = StringUtil.generateUid();
      for (int tokenId in category.oldTokenIds) {
        OtpToken token = tokens.where((element) => element.id == tokenId).first;
        bindings.add(TokenCategoryBinding(
            categoryUid: category.uid, tokenUid: token.uid));
      }
    }
    await CategoryDao.updateCategories(categories,
        backup: false, overrideDb: db);
    await BindingDao.bingdings(bindings, overrideDb: db);
  }

  static Future<void> createTable({
    required String tableName,
    required String sql,
  }) async {
    if (await isTableExist(tableName) == false) {
      await (await getDataBase()).execute(sql);
    }
  }

  static Future<bool> isTableExist(
    String tableName, {
    Database? overrideDb,
  }) async {
    var result = await (overrideDb ?? await getDataBase()).rawQuery(
        "select * from Sqlite_master where type = 'table' and name = '$tableName'");
    return result.isNotEmpty;
  }

  static Future<bool> isColumnExist(
    String tableName,
    String columnName, {
    Database? overrideDb,
  }) async {
    var result = await (overrideDb ?? await getDataBase())
        .rawQuery("PRAGMA table_info($tableName)");
    return result.any((element) => element['name'] == columnName);
  }

  static DynamicLibrary? loadSqlcipher() {
    try {
      DynamicLibrary? lib;
      if (Platform.isLinux || Platform.isAndroid) {
        try {
          lib = DynamicLibrary.open('libsqlcipher.so');
        } catch (e) {
          if (Platform.isAndroid) {
            final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();
            final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
            final appId =
                String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));
            lib = DynamicLibrary.open('/data/data/$appId/lib/libsqlcipher.so');
          } else {
            rethrow;
          }
        }
      }
      if (Platform.isMacOS || Platform.isIOS) {
        return DynamicLibrary.process();
      }
      if (Platform.isWindows) {
        lib = DynamicLibrary.open('sqlite_sqlcipher.dll');
      }
      return lib;
    } catch (e) {
      return null;
    }
  }
}

class SqlCipherUnavailableException implements Exception {
  const SqlCipherUnavailableException();

  @override
  String toString() => 'SQLCipher is unavailable or failed validation.';
}

class InvalidDatabasePasswordException implements Exception {
  const InvalidDatabasePasswordException();

  @override
  String toString() => 'The database password is empty or invalid.';
}

class DatabaseIntegrityException implements Exception {
  final String details;

  const DatabaseIntegrityException(this.details);

  @override
  String toString() => 'Database integrity check failed: $details';
}

class DatabaseMigrationException implements Exception {
  final String details;

  const DatabaseMigrationException(this.details);

  @override
  String toString() => 'Database migration failed: $details';
}
