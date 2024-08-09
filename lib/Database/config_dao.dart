import 'package:sqflite/sqflite.dart';

import '../Models/auto_backup_log.dart';
import '../Models/config.dart';
import '../TokenUtils/export_token_util.dart';
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
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.configInited);
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
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.configUpdated);
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
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.configUpdated);
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
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.configUpdated);
    return id;
  }
}
