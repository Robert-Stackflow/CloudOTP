import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:sqflite/sqflite.dart';

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

  static Future<int> updateTokens(List<OtpToken> tokens) async {
    final db = await DatabaseManager.getDataBase();
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
    return results.length;
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
    await CategoryDao.deleteToken(token.id);
    int id = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [token.id],
    );
    return id;
  }

  static Future<List<OtpToken>> listTokens({
    String searchKey = "",
  }) async {
    final db = await DatabaseManager.getDataBase();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: "pinned DESC, seq ASC",
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
    } catch (_) {
      return null;
    }
  }
}
