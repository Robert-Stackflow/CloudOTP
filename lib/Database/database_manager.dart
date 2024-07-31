import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/Database/create_table_sql.dart';
import 'package:cloudotp/Screens/Setting/setting_screen.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

import '../Utils/hive_util.dart';

class DatabaseManager {
  static const _dbName = "cloudotp.db";
  static const _dbVersion = 1;
  static Database? _database;
  static final dbFactory = createDatabaseFactoryFfi(ffiInit: ffiInit);

  static bool get initialized => _database != null;

  static Future<Database> getDataBase() async {
    if (_database == null) {
      await initDataBase("");
    }
    return _database!;
  }

  static Future<void> initDataBase(String password) async {
    if (_database == null) {
      String path = join(await dbFactory.getDatabasesPath(), _dbName);
      if (!await dbFactory.databaseExists(path)) {
        password = await HiveUtil.regeneratePassword();
        await HiveUtil.setEncryptDatabaseStatus(
            EncryptDatabaseStatus.defaultPassword);
      }
      _database = await dbFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          singleInstance: true,
          onConfigure: (db) async {
            await db.rawQuery("PRAGMA KEY='$password'");
          },
          onCreate: _onCreate,
        ),
      );
    }
    await ConfigDao.initConfig();
  }

  static Future<bool> changePassword(String password) async {
    if (_database != null) {
      List<Map<String, Object?>> res =
          await _database!.rawQuery("PRAGMA rekey='$password'");
      if (res.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static void ffiInit() {
    open.overrideForAll(sqlcipherOpen);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(Sql.createTokenTable.sql);
    await db.execute(Sql.createCategoryTable.sql);
    await db.execute(Sql.createConfigTable.sql);
    await db.execute(Sql.createCloudServiceConfigTable.sql);
  }

  static Future<void> createTable({
    required String tableName,
    required String sql,
  }) async {
    if (await isTableExist(tableName) == false) {
      await (await getDataBase()).execute(sql);
    }
  }

  static Future<bool> isTableExist(String tableName) async {
    var result = await (await getDataBase()).rawQuery(
        "select * from Sqlite_master where type = 'table' and name = '$tableName'");
    return result.isNotEmpty;
  }

  static DynamicLibrary sqlcipherOpen() {
    if (Platform.isLinux || Platform.isAndroid) {
      try {
        return DynamicLibrary.open('libsqlcipher.so');
      } catch (_) {
        if (Platform.isAndroid) {
          final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();

          final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
          final appId =
              String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));
          return DynamicLibrary.open('/data/data/$appId/lib/libsqlcipher.so');
        }

        rethrow;
      }
    }
    if (Platform.isIOS) {
      return DynamicLibrary.process();
    }
    if (Platform.isMacOS) {
      return DynamicLibrary.open('/usr/lib/libsqlite3.dylib');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('sqlite3.dll');
    }

    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}
