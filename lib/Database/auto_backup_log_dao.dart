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
    log.id = await getMaxId() + 1;
    log.endTimestamp = DateTime.now().millisecondsSinceEpoch;
    int id = await db.insert(
      tableName,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<int> getMaxId() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT MAX(id) as id FROM $tableName",
    );
    return maps[0]["id"] ?? -1;
  }

  static Future<List<AutoBackupLog>> getLogs({
    int limit = 10,
    int offset = 0,
  }) async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: "create_timestamp DESC",
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) {
      return AutoBackupLog.fromMap(maps[i]);
    });
  }
}
