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

import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:sqflite/sqflite.dart';

import '../Models/auto_backup_log.dart';
import '../TokenUtils/export_token_util.dart';
import '../Utils/ilogger.dart';
import '../Utils/utils.dart';

class TokenDao {
  static const String tableName = "otp_token";

  static Future<int> insertToken(OtpToken token) async {
    final db = await DatabaseManager.getDataBase();
    token.seq = await getMaxSeq() + 1;
    token.id = await getMaxId() + 1;
    int id = await db.insert(
      tableName,
      token.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.tokenInserted);
    Utils.initTray();
    return id;
  }

  static Future<int> insertTokens(List<OtpToken> tokens) async {
    if (tokens.isEmpty) return 0;
    final db = await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (OtpToken token in tokens) {
      token.seq = await getMaxSeq() + 1 + tokens.indexOf(token);
      token.id = await getMaxId() + 1 + tokens.indexOf(token);
      batch.insert(
        tableName,
        token.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    List<dynamic> results = await batch.commit();
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.tokensInserted);
    Utils.initTray();
    return results.length;
  }

  static Future<int> getMaxId() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT MAX(id) as id FROM $tableName",
    );
    return maps[0]["id"] ?? -1;
  }

  static Future<int> getMaxSeq() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT MAX(seq) as seq FROM $tableName",
    );
    return maps[0]["seq"] ?? -1;
  }

  static Future<int> updateToken(
    OtpToken token, {
    bool autoBackup = true,
  }) async {
    token.editTimeStamp = DateTime.now().millisecondsSinceEpoch;
    final db = await DatabaseManager.getDataBase();
    int id = await db.update(
      tableName,
      token.toMap(),
      where: 'id = ?',
      whereArgs: [token.id],
    );
    if (autoBackup) {
      ExportTokenUtil.autoBackup(
          triggerType: AutoBackupTriggerType.tokenUpdated);
    }
    Utils.initTray();
    return id;
  }

  static Future<int> updateTokenCounter(OtpToken token) async {
    return updateToken(token, autoBackup: false);
  }

  static Future<int> updateTokens(
    List<OtpToken> tokens, {
    bool autoBackup = true,
    Database? overrideDb,
  }) async {
    if (tokens.isEmpty) return 0;
    final db = overrideDb ?? await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (OtpToken token in tokens) {
      token.editTimeStamp = DateTime.now().millisecondsSinceEpoch;
      batch.update(
        tableName,
        token.toMap(),
        where: 'id = ?',
        whereArgs: [token.id],
      );
    }
    List<dynamic> results = await batch.commit();
    if (autoBackup) {
      ExportTokenUtil.autoBackup(
          triggerType: AutoBackupTriggerType.tokensUpdated);
    }
    Utils.initTray();
    return results.length;
  }

  static Future<int> resetSingleTokenCopyTimes(OtpToken token) async {
    final db = await DatabaseManager.getDataBase();
    token.copyTimes = 0;
    token.lastCopyTimeStamp = 0;
    int id = await db.update(
      tableName,
      token.toMap(),
      where: 'id = ?',
      whereArgs: [token.id],
    );
    return id;
  }

  static Future<int> resetTokenCopyTimes() async {
    final db = await DatabaseManager.getDataBase();
    List<OtpToken> tokens = await listTokens();
    Batch batch = db.batch();
    for (OtpToken token in tokens) {
      token.copyTimes = 0;
      token.lastCopyTimeStamp = 0;
      batch.update(
        tableName,
        token.toMap(),
        where: 'id = ?',
        whereArgs: [token.id],
      );
    }
    List<dynamic> results = await batch.commit();
    return results.length;
  }

  static Future<int> updateTokenPinned(OtpToken token, bool pinned) async {
    final db = await DatabaseManager.getDataBase();
    token.pinned = pinned;
    token.editTimeStamp = DateTime.now().millisecondsSinceEpoch;
    int id = await db.update(
      tableName,
      token.toMap(),
      where: 'id = ?',
      whereArgs: [token.id],
    );
    return id;
  }

  static Future<int> incTokenCopyTimes(OtpToken token) async {
    final db = await DatabaseManager.getDataBase();
    token.copyTimes += 1;
    token.lastCopyTimeStamp = DateTime.now().millisecondsSinceEpoch;
    int id = await db.update(
      tableName,
      token.toMap(),
      where: 'id = ?',
      whereArgs: [token.id],
    );
    return id;
  }

  static Future<int> deleteToken(OtpToken token) async {
    final db = await DatabaseManager.getDataBase();
    await BindingDao.removeTokenBindings(token.uid);
    int id = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [token.id],
    );
    ExportTokenUtil.autoBackup(triggerType: AutoBackupTriggerType.tokenDeleted);
    Utils.initTray();
    return id;
  }

  static Future<List<OtpToken>> listTokens({
    String searchKey = "",
    String orderBy = "",
    Database? overrideDb,
  }) async {
    final db = overrideDb ?? await DatabaseManager.getDataBase();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: "pinned DESC, seq DESC${orderBy.isEmpty ? "" : ", $orderBy"}",
      where: searchKey.isEmpty ? null : 'issuer LIKE ?',
      whereArgs: searchKey.isEmpty ? null : ["%$searchKey%"],
    );
    return List.generate(maps.length, (i) {
      return OtpToken.fromMap(maps[i]);
    });
  }

  static Future<OtpToken?> getTokenById(
    int id, {
    String searchKey = "",
  }) async {
    try {
      final db = await DatabaseManager.getDataBase();
      List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: searchKey.isEmpty ? 'id = ?' : 'id = ? AND issuer LIKE ?',
        whereArgs: searchKey.isEmpty ? [id] : [id, "%$searchKey%"],
      );
      return OtpToken.fromMap(maps[0]);
    } catch (e, t) {
      ILogger.error("CloudOTP",
          "Failed to get token by id $id and serachKey $searchKey", e, t);
      return null;
    }
  }

  static Future<OtpToken?> getTokenByUid(
    String uid, {
    String searchKey = "",
  }) async {
    try {
      final db = await DatabaseManager.getDataBase();
      List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: searchKey.isEmpty ? 'uid = ?' : 'uid = ? AND issuer LIKE ?',
        whereArgs: searchKey.isEmpty ? [uid] : [uid, "%$searchKey%"],
      );
      return maps.isNotEmpty ? OtpToken.fromMap(maps[0]) : null;
    } catch (e, t) {
      ILogger.error("CloudOTP",
          "Failed to get token by uid $uid and searchKey $searchKey", e, t);
      return null;
    }
  }
}
