import 'package:cloudotp/Database/token_dao.dart';
import 'package:sqflite/sqflite.dart';

import '../Models/category.dart';
import '../Models/opt_token.dart';
import 'database_manager.dart';

class CategoryDao {
  static const String tableName = "token_category";

  static Future<int> insertCategory(TokenCategory category) async {
    final db = await DatabaseManager.getDataBase();
    category.seq = await getMaxSeq() + 1;
    category.id = await getMaxId() + 1;
    int id = await db.insert(
      tableName,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<int> insertCategories(List<TokenCategory> categories) async {
    final db = await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (TokenCategory category in categories) {
      category.seq = await getMaxSeq() + 1 + categories.indexOf(category);
      category.id = await getMaxId() + 1 + categories.indexOf(category);
      batch.insert(
        tableName,
        category.toMap(),
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
    return maps[0]["id"] ?? -1;
  }

  static Future<int> getMaxSeq() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT MAX(seq) as seq FROM $tableName",
    );
    return maps[0]["seq"] ?? -1;
  }

  static Future<int> updateCategory(TokenCategory category) async {
    category.editTimeStamp = DateTime.now().millisecondsSinceEpoch;
    final db = await DatabaseManager.getDataBase();
    int id = await db.update(
      tableName,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return id;
  }

  static Future<int> updateCategories(List<TokenCategory> category) async {
    final db = await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (TokenCategory category in category) {
      category.editTimeStamp = DateTime.now().millisecondsSinceEpoch;
      batch.update(
        tableName,
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }
    List<dynamic> results = await batch.commit();
    return results.length;
  }

  static Future<int> deleteCategory(TokenCategory category) async {
    final db = await DatabaseManager.getDataBase();
    int id = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return id;
  }

  static Future<List<TokenCategory>> listCategories({bool desc = false}) async {
    final db = await DatabaseManager.getDataBase();
    final List<Map<String, dynamic>> maps =
        await db.query(tableName, orderBy: "seq ${desc ? "DESC" : "ASC"}");
    return List.generate(maps.length, (i) {
      return TokenCategory.fromMap(maps[i]);
    });
  }

  static Future<bool> isCategoryExist(String title) async {
    final db = await DatabaseManager.getDataBase();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'title = ?',
      whereArgs: [title],
    );
    return maps.isNotEmpty;
  }

  static Future<TokenCategory> getCategoryById(int id) async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return TokenCategory.fromMap(maps[0]);
  }

  static Future<List<OtpToken>> getTokensByCategoryId(
    int id, {
    String searchKey = "",
  }) async {
    if (id == -1) return await TokenDao.listTokens(searchKey: searchKey);
    TokenCategory category = await getCategoryById(id);
    List<OtpToken> tokens = [];
    for (int tokenId in category.tokenIds) {
      OtpToken? tmp =
          await TokenDao.getTokenById(tokenId, searchKey: searchKey);
      if (tmp != null) tokens.add(tmp);
    }
    tokens.sort((a, b) => -a.pinnedInt.compareTo(b.pinnedInt));
    return tokens;
  }

  static Future<List<int>> getCategoryIdsByTokenId(int id) async {
    List<TokenCategory> categories = await listCategories();
    List<int> categoryIds = [];
    for (TokenCategory category in categories) {
      if (category.tokenIds.contains(id)) {
        categoryIds.add(category.id);
      }
    }
    return categoryIds;
  }

  static Future<void> deleteToken(int tokenId) async {
    List<int> categoryIds = await getCategoryIdsByTokenId(tokenId);
    updateCategoriesForToken(tokenId, categoryIds, []);
  }

  static Future<void> updateCategoriesForToken(
      int tokenId, List<int> unseletedIds, List<int> newSeletedIds) async {
    List<TokenCategory> unselectedCategories = [];
    List<TokenCategory> newSeletedCategories = [];
    for (int id in unseletedIds) {
      unselectedCategories.add(await getCategoryById(id));
    }
    for (int id in newSeletedIds) {
      newSeletedCategories.add(await getCategoryById(id));
    }
    for (TokenCategory category in unselectedCategories) {
      category.tokenIds.remove(tokenId);
    }
    for (TokenCategory category in newSeletedCategories) {
      category.tokenIds.add(tokenId);
    }
    await updateCategories(unselectedCategories);
    await updateCategories(newSeletedCategories);
  }
}
