/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DatabaseMigrations {
  const DatabaseMigrations._();

  static Future<void> upgradeToV9(DatabaseExecutor db) async {
    final sourceCount = await _rowCount(db, 'token_category_binding');

    await db.execute('''
      CREATE TABLE token_category_binding_v9 (
        token_uid TEXT NOT NULL,
        category_uid TEXT NOT NULL,
        UNIQUE(token_uid, category_uid)
      )
    ''');
    await db.execute('''
      INSERT INTO token_category_binding_v9 (token_uid, category_uid)
      SELECT CAST(token_uid AS TEXT), CAST(category_uid AS TEXT)
      FROM token_category_binding
    ''');

    final migratedCount = await _rowCount(db, 'token_category_binding_v9');
    final missingRows = await db.rawQuery('''
      SELECT CAST(token_uid AS TEXT) AS token_uid,
             CAST(category_uid AS TEXT) AS category_uid
      FROM token_category_binding
      EXCEPT
      SELECT token_uid, category_uid FROM token_category_binding_v9
    ''');
    final unexpectedRows = await db.rawQuery('''
      SELECT token_uid, category_uid FROM token_category_binding_v9
      EXCEPT
      SELECT CAST(token_uid AS TEXT), CAST(category_uid AS TEXT)
      FROM token_category_binding
    ''');
    if (sourceCount != migratedCount ||
        missingRows.isNotEmpty ||
        unexpectedRows.isNotEmpty) {
      throw StateError(
        'Binding migration verification failed: '
        'source=$sourceCount, migrated=$migratedCount, '
        'missing=${missingRows.length}, unexpected=${unexpectedRows.length}',
      );
    }

    await db.execute('DROP TABLE token_category_binding');
    await db.execute('''
      ALTER TABLE token_category_binding_v9
      RENAME TO token_category_binding
    ''');
    await createIndexes(db);
  }

  static Future<void> upgradeToV10(DatabaseExecutor db) async {
    final tokenCount = await _rowCount(db, 'otp_token');
    final duplicateUids = await db.rawQuery('''
      SELECT uid
      FROM otp_token
      GROUP BY uid
      HAVING uid = '' OR COUNT(*) > 1
    ''');

    for (final duplicate in duplicateUids) {
      final oldUid = duplicate['uid'] as String;
      final tokens = await db.query(
        'otp_token',
        columns: ['id'],
        where: 'uid = ?',
        whereArgs: [oldUid],
        orderBy: 'id ASC',
      );
      final bindings = await db.query(
        'token_category_binding',
        columns: ['category_uid'],
        where: 'token_uid = ?',
        whereArgs: [oldUid],
      );
      final firstTokenToRepair = oldUid.isEmpty ? 0 : 1;

      for (int i = firstTokenToRepair; i < tokens.length; i++) {
        final newUid = await _generateUniqueTokenUid(db);
        await db.update(
          'otp_token',
          {'uid': newUid},
          where: 'id = ?',
          whereArgs: [tokens[i]['id']],
        );
        for (final binding in bindings) {
          await db.insert(
            'token_category_binding',
            {
              'token_uid': newUid,
              'category_uid': binding['category_uid'],
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }

      if (oldUid.isEmpty) {
        await db.delete(
          'token_category_binding',
          where: 'token_uid = ?',
          whereArgs: [oldUid],
        );
      }
    }

    final duplicateCount = await db.rawQuery('''
      SELECT uid FROM otp_token GROUP BY uid HAVING uid = '' OR COUNT(*) > 1
    ''');
    if (await _rowCount(db, 'otp_token') != tokenCount ||
        duplicateCount.isNotEmpty) {
      throw StateError('Token UID migration verification failed');
    }

    await db.execute('DROP INDEX IF EXISTS idx_otp_token_uid');
    await db.execute(
      'CREATE UNIQUE INDEX idx_otp_token_uid ON otp_token(uid)',
    );
  }

  static Future<void> createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_otp_token_uid ON otp_token(uid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_token_category_uid '
      'ON token_category(uid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_binding_token_uid '
      'ON token_category_binding(token_uid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_binding_category_uid '
      'ON token_category_binding(category_uid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cloud_service_type '
      'ON cloud_service_config(type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_backup_log_started '
      'ON auto_update_log(start_timestamp)',
    );
  }

  static Future<int> _rowCount(
    DatabaseExecutor db,
    String tableName,
  ) async {
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    return (result.first.values.first as num).toInt();
  }

  static Future<String> _generateUniqueTokenUid(DatabaseExecutor db) async {
    while (true) {
      final uid = const Uuid().v4();
      final existing = await db.query(
        'otp_token',
        columns: ['id'],
        where: 'uid = ?',
        whereArgs: [uid],
        limit: 1,
      );
      if (existing.isEmpty) return uid;
    }
  }
}
