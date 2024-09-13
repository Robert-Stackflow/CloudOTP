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

import 'package:sqflite/sqflite.dart';

import '../Models/config.dart';
import 'database_manager.dart';

class ConfigDao {
  static const String tableName = "cloudotp_config";

  static Future<int> initConfig() async {
    if (await hasConfig()) return 0;
    final db = await DatabaseManager.getDataBase();
    Config config = Config();
    config.id = 0;
    int id = await db.insert(
      tableName,
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // ExportTokenUtil.autoBackup(
    //     triggerType: AutoBackupTriggerType.configInited);
    return id;
  }

  static Future<bool> hasConfig() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [0],
    );
    return maps.isNotEmpty;
  }

  static Future<Config> getConfig() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [0],
    );
    if (maps.isNotEmpty) {
      return Config.fromMap(maps.first);
    } else {
      return Config();
    }
  }

  static Future<String> getBackupPassword() async {
    Config config = await getConfig();
    return config.backupPassword;
  }

  static Future<bool> hasBackupPassword() async {
    return (await getBackupPassword()).isNotEmpty;
  }

  static Future<int> updateBackupPassword(String password) async {
    final db = await DatabaseManager.getDataBase();
    Config config = await getConfig();
    config.backupPassword = password;
    int id = await db.update(
      tableName,
      config.toMap(),
      where: 'id = ?',
      whereArgs: [0],
    );
    // ExportTokenUtil.autoBackup(
    //     triggerType: AutoBackupTriggerType.configUpdated);
    return id;
  }

  static Future<int> updateRemark(Map<String, dynamic> remark) async {
    final db = await DatabaseManager.getDataBase();
    Config config = await getConfig();
    config.remark = remark;
    int id = await db.update(
      tableName,
      config.toMap(),
      where: 'id = ?',
      whereArgs: [0],
    );
    // ExportTokenUtil.autoBackup(
    //     triggerType: AutoBackupTriggerType.configUpdated);
    return id;
  }

  static Future<int> updateConfig(Config config) async {
    final db = await DatabaseManager.getDataBase();
    int id = await db.update(
      tableName,
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
    // ExportTokenUtil.autoBackup(
    //     triggerType: AutoBackupTriggerType.configUpdated);
    return id;
  }
}
