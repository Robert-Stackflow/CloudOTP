import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

class TokenDao {
  static const String tableName = "token";

  static Future<int> insertToken(OtpToken token) async {
    final db = await DatabaseManager.getDataBase();
    token.seq = await getMaxSeq() + 1;
    token.id = await getMaxId() + 1;
    int id = await db.insert(
      tableName,
      token.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<int> insertTokens(List<OtpToken> tokens) async {
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
    return results.length;
  }

  static Future<int> getMaxId() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT MAX(id) as id FROM $tableName",
    );
    return maps[0]["id"] ?? 0;
  }

  static Future<int> getMaxSeq() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT MAX(seq) as seq FROM $tableName",
    );
    return maps[0]["seq"] ?? 0;
  }

  static Future<int> updateToken(OtpToken token) async {
    token.editTimeStamp = DateTime.now().millisecondsSinceEpoch;
    final db = await DatabaseManager.getDataBase();
    int id = await db.update(
      tableName,
      token.toMap(),
      where: 'id = ?',
      whereArgs: [token.id],
    );
    return id;
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
    int id = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [token.id],
    );
    return id;
  }

  static Future<List<OtpToken>> listTokens() async {
    final db = await DatabaseManager.getDataBase();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: "pinned DESC",
    );
    return List.generate(maps.length, (i) {
      return OtpToken.fromMap(maps[i]);
    });
  }

  static Future<OtpToken> getTokenById(int id) async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return OtpToken.fromMap(maps[0]);
  }
}
