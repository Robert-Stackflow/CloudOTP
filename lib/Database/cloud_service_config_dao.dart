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

import '../Models/cloud_service_config.dart';
import 'database_manager.dart';

class CloudServiceConfigDao {
  static const String tableName = "cloud_service_config";

  static Future<int> insertConfig(CloudServiceConfig config) async {
    final db = await DatabaseManager.getDataBase();
    if (await getSpecifyConfig(config.type) != null) {
      return -1;
    }
    config.id = await getMaxId() + 1;
    config.createTimestamp = DateTime.now().millisecondsSinceEpoch;
    config.editTimestamp = DateTime.now().millisecondsSinceEpoch;
    int id = await db.insert(
      tableName,
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // ExportTokenUtil.autoBackup(triggerType: AutoBackupTriggerType.cloudServiceConfigInserted);
    return id;
  }

  static Future<int> getMaxId() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT MAX(id) as id FROM $tableName",
    );
    return maps[0]["id"] ?? -1;
  }

  static Future<List<CloudServiceConfig>> getConfigs() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
    );
    return List.generate(maps.length, (i) {
      return CloudServiceConfig.fromMap(maps[i]);
    });
  }

  static Future<List<CloudServiceConfig>> getValidConfigs() async {
    List<CloudServiceConfig> configs = await getConfigs();
    List<CloudServiceConfig> validConfigs = [];
    for (CloudServiceConfig config in configs) {
      if (config.enabled && (await config.isValid())) {
        validConfigs.add(config);
      }
    }
    return validConfigs;
  }

  static Future<int> updateLastBackupTime(CloudServiceConfig config) async {
    final db = await DatabaseManager.getDataBase();
    config.lastBackupTimestamp = DateTime.now().millisecondsSinceEpoch;
    int id = await db.update(
      tableName,
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
    return id;
  }

  static Future<int> updateLastPullTime(CloudServiceConfig config) async {
    final db = await DatabaseManager.getDataBase();
    config.lastFetchTimestamp = DateTime.now().millisecondsSinceEpoch;
    int id = await db.update(
      tableName,
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
    return id;
  }

  static Future<int> updateConfig(CloudServiceConfig config) async {
    final db = await DatabaseManager.getDataBase();
    config.editTimestamp = DateTime.now().millisecondsSinceEpoch;
    int id = await db.update(
      tableName,
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
    // ExportTokenUtil.autoBackup(triggerType: AutoBackupTriggerType.cloudServiceConfigUpdated);
    return id;
  }

  static Future<int> updateConfigEnabled(
      CloudServiceConfig config, bool enabled) async {
    final db = await DatabaseManager.getDataBase();
    config.enabled = enabled;
    config.editTimestamp = DateTime.now().millisecondsSinceEpoch;
    int id = await db.update(
      tableName,
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
    // ExportTokenUtil.autoBackup(triggerType: AutoBackupTriggerType.cloudServiceConfigUpdated);
    return id;
  }

  static Future<int> deleteConfig(int id) async {
    final db = await DatabaseManager.getDataBase();
    int result = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    // ExportTokenUtil.autoBackup(triggerType: AutoBackupTriggerType.cloudServiceConfigDeleted);
    return result;
  }

  static Future<CloudServiceConfig?> getSpecifyConfig(
      CloudServiceType type) async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'type = ?',
      whereArgs: [type.index],
    );
    if (maps.isNotEmpty) {
      return CloudServiceConfig.fromMap(maps.first);
    } else {
      return null;
    }
  }

  static Future<CloudServiceConfig?> getWebdavConfig() async {
    return getSpecifyConfig(CloudServiceType.Webdav);
  }

  static Future<CloudServiceConfig?> getOneDriveConfig() async {
    return getSpecifyConfig(CloudServiceType.OneDrive);
  }

  static Future<CloudServiceConfig?> getGoogleDriveConfig() async {
    return getSpecifyConfig(CloudServiceType.GoogleDrive);
  }

  static Future<CloudServiceConfig?> getDropboxConfig() async {
    return getSpecifyConfig(CloudServiceType.Dropbox);
  }

  static Future<CloudServiceConfig?> getS3CloudConfig() async {
    return getSpecifyConfig(CloudServiceType.S3Cloud);
  }

  static Future<CloudServiceConfig?> getHuaweiCloudConfig() async {
    return getSpecifyConfig(CloudServiceType.HuaweiCloud);
  }

  static Future<CloudServiceConfig?> getBoxConfig() async {
    return getSpecifyConfig(CloudServiceType.Box);
  }

  static Future<CloudServiceConfig?> getAliyunDriveConfig() async {
    return getSpecifyConfig(CloudServiceType.AliyunDrive);
  }
}
