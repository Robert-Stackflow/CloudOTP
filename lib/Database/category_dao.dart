import 'package:cloudotp/Database/token_dao.dart';
import 'package:sqflite/sqflite.dart';

import '../Models/category.dart';
import '../Models/opt_token.dart';
import 'database_manager.dart';

class CategoryDao {
  static const String tableName = "category";

  static Future<int> insertCategory(Category category) async {
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

  static Future<int> updateCategory(Category category) async {
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

  static Future<int> updateCategories(List<Category> category) async {
    final db = await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (Category category in category) {
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

  static Future<int> deleteCategory(Category category) async {
    final db = await DatabaseManager.getDataBase();
    int id = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return id;
  }

  static Future<List<Category>> listCategories({bool desc = false}) async {
    final db = await DatabaseManager.getDataBase();
    final List<Map<String, dynamic>> maps =
        await db.query(tableName, orderBy: "seq ${desc ? "DESC" : "ASC"}");
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
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

  static Future<Category> getCategoryById(int id) async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return Category.fromMap(maps[0]);
  }

  static Future<List<OtpToken>> getTokensByCategoryId(int id) async {
    if (id == -1) return await TokenDao.listTokens();
    Category category = await getCategoryById(id);
    List<OtpToken> tokens = [];
    for (int tokenId in category.tokenIds) {
      tokens.add(await TokenDao.getTokenById(tokenId));
    }
    tokens.sort((a, b) => -a.pinnedInt.compareTo(b.pinnedInt));
    return tokens;
  }

  static Future<List<int>> getCategoryIdsByTokenId(int id) async {
    List<Category> categories = await listCategories();
    List<int> categoryIds = [];
    for (Category category in categories) {
      if (category.tokenIds.contains(id)) {
        categoryIds.add(category.id);
      }
    }
    return categoryIds;
  }

  static Future<void> updateCategoriesForToken(
      int tokenId, List<int> unseletedIds, List<int> newSeletedIds) async {
    List<Category> unselectedCategories = [];
    List<Category> newSeletedCategories = [];
    for (int id in unseletedIds) {
      unselectedCategories.add(await getCategoryById(id));
    }
    for (int id in newSeletedIds) {
      newSeletedCategories.add(await getCategoryById(id));
    }
    for (Category category in unselectedCategories) {
      category.tokenIds.remove(tokenId);
    }
    for (Category category in newSeletedCategories) {
      category.tokenIds.add(tokenId);
    }
    await updateCategories(unselectedCategories);
    await updateCategories(newSeletedCategories);
  }
}
