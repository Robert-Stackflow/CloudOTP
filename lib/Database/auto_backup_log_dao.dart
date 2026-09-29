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

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../Models/auto_backup_log.dart';
import 'database_manager.dart';

class AutoBackupLogDao {
  static const String tableName = "auto_update_log";

  static Future<int> insertLog(AutoBackupLog log) async {
    final db = await DatabaseManager.getDataBase();
    log.endTimestamp = DateTime.now().millisecondsSinceEpoch;
    final values = log.toMap()..remove('id');
    final id = await db.insert(
      tableName,
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    log.id = id;
    return id;
  }

  static Future<List<AutoBackupLog>> getLogs({
    int limit = 10,
    int offset = 0,
  }) async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: "start_timestamp DESC",
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) {
      return AutoBackupLog.fromMap(maps[i]);
    });
  }

  static Future<void> deleteCompletedLogs(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await DatabaseManager.getDataBase();
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete(
      tableName,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  static Future<int> getLogCount() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT COUNT(*) as count FROM $tableName",
    );
    return maps[0]["count"] as int? ?? 0;
  }
}
