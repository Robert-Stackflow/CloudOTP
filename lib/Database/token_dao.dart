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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:sqflite/sqflite.dart';

import '../Models/auto_backup_log.dart';
import '../TokenUtils/export_token_util.dart';
import '../Utils/utils.dart';

class TokenDao {
  static const String tableName = "otp_token";

  static Future<int> insertToken(OtpToken token) async {
    final db = await DatabaseManager.getDataBase();
    token.seq = await getMaxSeq() + 1;
    final values = token.toMap()..remove('id');
    final id = await db.insert(
      tableName,
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    token.id = id;
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.tokenInserted);
    Utils.initTray();
    return id;
  }

  static Future<int> insertTokens(
    List<OtpToken> tokens, {
    DatabaseExecutor? overrideDb,
    bool notifyChanges = true,
  }) async {
    if (tokens.isEmpty) return 0;
    final db = overrideDb ?? await DatabaseManager.getDataBase();
    int maxSeq = await getMaxSeq(overrideDb: db);
    Batch batch = db.batch();
    // The incoming list is in display order (top first). Assign descending seq
    // so the first item gets the highest seq, preserving the original order
    // (display is ordered by seq DESC). A plain `maxSeq + 1 + i` would reverse
    // the list on backup restore / cloud pull.
    for (int i = 0; i < tokens.length; i++) {
      tokens[i].seq = maxSeq + tokens.length - i;
      final values = tokens[i].toMap()..remove('id');
      batch.insert(
        tableName,
        values,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
    List<dynamic> results = await batch.commit();
    for (int i = 0; i < results.length; i++) {
      tokens[i].id = results[i] as int;
    }
    if (notifyChanges) {
      ExportTokenUtil.autoBackup(
          triggerType: AutoBackupTriggerType.tokensInserted);
      Utils.initTray();
    }
    return results.length;
  }

  static Future<int> getMaxSeq({DatabaseExecutor? overrideDb}) async {
    final db = overrideDb ?? await DatabaseManager.getDataBase();
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
    DatabaseExecutor? overrideDb,
    bool notifyChanges = true,
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
    if (autoBackup && notifyChanges) {
      ExportTokenUtil.autoBackup(
          triggerType: AutoBackupTriggerType.tokensUpdated);
    }
    if (notifyChanges) Utils.initTray();
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

  static Future<int> deleteTokens(List<OtpToken> tokens) async {
    if (tokens.isEmpty) return 0;
    final db = await DatabaseManager.getDataBase();
    for (OtpToken token in tokens) {
      await BindingDao.removeTokenBindings(token.uid);
    }
    Batch batch = db.batch();
    for (OtpToken token in tokens) {
      batch.delete(tableName, where: 'id = ?', whereArgs: [token.id]);
    }
    List<dynamic> results = await batch.commit();
    ExportTokenUtil.autoBackup(triggerType: AutoBackupTriggerType.tokenDeleted);
    Utils.initTray();
    return results.length;
  }

  static ({String? where, List<Object>? whereArgs}) _buildSearchWhere({
    String searchKey = "",
    List<String> tags = const [],
    String? tokenType,
    String? uidCondition,
    Object? uidArg,
  }) {
    final conditions = <String>[];
    final args = <Object>[];

    if (uidCondition != null) {
      conditions.add(uidCondition);
      if (uidArg != null) args.add(uidArg);
    }

    if (searchKey.isNotEmpty) {
      conditions.add('(issuer LIKE ? OR account LIKE ? OR description LIKE ?)');
      args.addAll(["%$searchKey%", "%$searchKey%", "%$searchKey%"]);
    }

    for (final tag in tags) {
      conditions.add('tags LIKE ?');
      args.add('%$tag%');
    }

    if (tokenType != null) {
      try {
        final typeIndex = OtpTokenType.fromString(tokenType).index;
        conditions.add('token_type = ?');
        args.add(typeIndex);
      } catch (_) {}
    }

    if (conditions.isEmpty) return (where: null, whereArgs: null);
    return (where: conditions.join(' AND '), whereArgs: args);
  }

  static Future<List<OtpToken>> listTokens({
    String searchKey = "",
    List<String> tags = const [],
    String? tokenType,
    String orderBy = "",
    DatabaseExecutor? overrideDb,
  }) async {
    final db = overrideDb ?? await DatabaseManager.getDataBase();
    final search = _buildSearchWhere(
        searchKey: searchKey, tags: tags, tokenType: tokenType);
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: "pinned DESC, seq DESC${orderBy.isEmpty ? "" : ", $orderBy"}",
      where: search.where,
      whereArgs: search.whereArgs,
    );
    return List.generate(maps.length, (i) {
      return OtpToken.fromMap(maps[i]);
    });
  }

  static Future<int> getTokenCount({DatabaseExecutor? overrideDb}) async {
    final db = overrideDb ?? await DatabaseManager.getDataBase();
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    return (result.first.values.first as num).toInt();
  }

  static Future<List<OtpToken>> listTokensByCategoryUid(
    String categoryUid, {
    String searchKey = "",
    List<String> tags = const [],
    String? tokenType,
    DatabaseExecutor? overrideDb,
  }) async {
    final db = overrideDb ?? await DatabaseManager.getDataBase();
    final search = _buildSearchWhere(
      searchKey: searchKey,
      tags: tags,
      tokenType: tokenType,
    );
    final conditions = <String>['binding.category_uid = ?'];
    final args = <Object>[categoryUid];
    if (search.where != null) {
      conditions.add(search.where!);
      args.addAll(search.whereArgs!);
    }
    final maps = await db.rawQuery('''
      SELECT DISTINCT token.*
      FROM $tableName AS token
      INNER JOIN ${BindingDao.tableName} AS binding
        ON binding.token_uid = token.uid
      WHERE ${conditions.join(' AND ')}
      ORDER BY token.pinned DESC, token.seq DESC
    ''', args);
    return maps.map(OtpToken.fromMap).toList();
  }

  static Future<OtpToken?> getTokenById(
    int id, {
    String searchKey = "",
    List<String> tags = const [],
    String? tokenType,
  }) async {
    try {
      final db = await DatabaseManager.getDataBase();
      final search = _buildSearchWhere(
        searchKey: searchKey,
        tags: tags,
        tokenType: tokenType,
        uidCondition: 'id = ?',
        uidArg: id,
      );
      List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: search.where,
        whereArgs: search.whereArgs,
      );
      return OtpToken.fromMap(maps[0]);
    } catch (e, t) {
      ILogger.error(
          "Failed to get token by id $id and serachKey $searchKey", e, t);
      return null;
    }
  }

  static Future<OtpToken?> getTokenByUid(
    String uid, {
    String searchKey = "",
    List<String> tags = const [],
    String? tokenType,
  }) async {
    try {
      final db = await DatabaseManager.getDataBase();
      final search = _buildSearchWhere(
        searchKey: searchKey,
        tags: tags,
        tokenType: tokenType,
        uidCondition: 'uid = ?',
        uidArg: uid,
      );
      List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: search.where,
        whereArgs: search.whereArgs,
      );
      return maps.isNotEmpty ? OtpToken.fromMap(maps[0]) : null;
    } catch (e, t) {
      ILogger.error(
          "Failed to get token by uid $uid and searchKey $searchKey", e, t);
      return null;
    }
  }
}
