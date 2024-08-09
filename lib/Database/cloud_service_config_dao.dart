import '../Models/auto_backup_log.dart';
import '../Models/cloud_service_config.dart';
import '../TokenUtils/export_token_util.dart';
import 'database_manager.dart';
import 'package:sqflite/sqflite.dart';

class CloudServiceConfigDao {
  static const String tableName = "cloud_service_config";

  static Future<int> insertConfig(CloudServiceConfig config) async {
    final db = await DatabaseManager.getDataBase();
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
}
