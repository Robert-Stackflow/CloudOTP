/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import 'package:sqflite/sqflite.dart';

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
}
