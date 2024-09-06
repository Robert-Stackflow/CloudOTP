import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/Database/create_table_sql.dart';
import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Models/token_category_binding.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/file_util.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

import '../Utils/hive_util.dart';
import '../Utils/ilogger.dart';
import '../Utils/utils.dart';

enum EncryptDatabaseStatus { defaultPassword, customPassword }

class DatabaseManager {
  static const _dbName = "cloudotp.db";
  static const _unencrypedFileHeader = "SQLite format 3";
  static const _dbVersion = 6;
  static Database? _database;
  static final dbFactory = createDatabaseFactoryFfi();
  static DynamicLibrary? lib = loadSqlcipher();
  static final cipherDbFactory = createDatabaseFactoryFfi(ffiInit: () {
    if (lib != null) open.overrideForAll(() => lib!);
  });
  static DatabaseFactory _currentDbFactory = cipherDbFactory;
  static bool isDatabaseEncrypted = false;

  static bool get initialized => _database != null;

  static Future<Database> getDataBase() async {
    if (_database == null) {
      await initDataBase("");
    }
    return _database!;
  }

  static Future<void> initDataBase(String password) async {
    if (_database == null) {
      appProvider.currentDatabasePassword = password;
      String path = join(await FileUtil.getDatabaseDir(), _dbName);
      File file = File(path);
      if (file.existsSync()) {
        final stream = file.openRead(0, _unencrypedFileHeader.length);
        String content = String.fromCharCodes(await stream.fold<List<int>>(
            [], (previous, element) => previous..addAll(element)));
        if (content == _unencrypedFileHeader) {
          isDatabaseEncrypted = false;
          _currentDbFactory = dbFactory;
          ILogger.info(
              "Database is an unencrypted SQLite database. File header is $content");
        } else {
          isDatabaseEncrypted = true;
          _currentDbFactory = cipherDbFactory;
          ILogger.info("Database is an encrypted SQLite database.");
        }
      } else {
        isDatabaseEncrypted = true;
        _currentDbFactory = cipherDbFactory;
        password = await HiveUtil.regeneratePassword();
        appProvider.currentDatabasePassword = password;
        ILogger.info("Database not exist and new password is $password");
        await HiveUtil.setEncryptDatabaseStatus(
            EncryptDatabaseStatus.defaultPassword);
      }
      _database = await _currentDbFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          singleInstance: true,
          onConfigure: (db) async {
            _onConfigure(db, password);
          },
          onUpgrade: _onUpgrade,
          onCreate: _onCreate,
        ),
      );
    }
    await ConfigDao.initConfig();
  }

  static Future<bool> changePassword(String password) async {
    if (_database != null) {
      if (isDatabaseEncrypted) {
        List<Map<String, Object?>> res =
            await _database!.rawQuery("PRAGMA rekey='$password'");
        ILogger.info("Change database password result is $res");
        if (res.isNotEmpty) {
          appProvider.currentDatabasePassword = password;
          return true;
        }
      } else {
        try {
          await _database!.rawQuery(
              "ATTACH DATABASE 'encrypted.db' AS tmp KEY '$password'");
          await _database!.rawQuery("SELECT sqlcipher_export('tmp')");
          await _database!.rawQuery("DETACH DATABASE tmp");
          return true;
        } catch (e) {
          ILogger.error("Failed to change database password", e);
          return false;
        }
      }
      return false;
    }
    return false;
  }

  static Future<void> _onConfigure(Database db, String password) async {
    if (isDatabaseEncrypted) {
      List<Map<String, Object?>> res =
          await db.rawQuery("PRAGMA KEY='$password'");
      if (res.isNotEmpty) {
        ILogger.info(
            "Configure database with cipher successfully. Result is $res");
      } else {
        ILogger.error(
          "Failed to configure database with cipher, perhaps the sqlcipher dynamic library was not loaded.",
          res,
        );
      }
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(Sql.createTokenTable.sql);
    await db.execute(Sql.createCategoryTable.sql);
    await db.execute(Sql.createConfigTable.sql);
    await db.execute(Sql.createCloudServiceConfigTable.sql);
    await db.execute(Sql.createAutoBackupLogTable.sql);
    await db.execute(Sql.createTokenCategoryBindingTable.sql);
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
  }

  static updateToV6(Database db) async {
    if (!(await isTableExist(BindingDao.tableName, overrideDb: db))) {
      await db.execute(Sql.createTokenCategoryBindingTable.sql);
    }
    List<OtpToken> tokens = await TokenDao.listTokens(overrideDb: db);
    for (OtpToken token in tokens) {
      token.uid = Utils.generateUid();
    }
    await TokenDao.updateTokens(tokens, autoBackup: false, overrideDb: db);
    List<TokenCategory> categories =
        await CategoryDao.listCategories(overrideDb: db);
    List<TokenCategoryBinding> bindings = [];
    for (TokenCategory category in categories) {
      category.uid = Utils.generateUid();
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
      if (Platform.isIOS) {
        lib = DynamicLibrary.process();
      }
      if (Platform.isMacOS) {
        lib = DynamicLibrary.open('/usr/lib/libsqlite3.dylib');
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
