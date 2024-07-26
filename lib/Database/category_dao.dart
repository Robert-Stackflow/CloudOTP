import 'package:sqflite/sqflite.dart';

import '../Models/category.dart';
import 'database_manager.dart';

class CategoryDao{
  static const String tableName = "category";
  static Future<int> saveCategory(Category category) async {
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
    final db = await DatabaseManager.getDataBase();
    int id = await db.update(
      tableName,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return id;
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

  static Future<List<Category>> listCategories() async {
    final db = await DatabaseManager.getDataBase();
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }
}