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
import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/auto_backup_log.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:sqflite/sqflite.dart';

import '../Models/opt_token.dart';
import '../Models/token_category.dart';
import '../Utils/utils.dart';
import 'database_manager.dart';

class CategoryDao {
  static const String tableName = "token_category";

  static Future<int> insertCategory(TokenCategory category) async {
    final db = await DatabaseManager.getDataBase();
    category.seq = await getMaxSeq() + 1;
    category.id = await getMaxId() + 1;
    if (category.uid.isEmpty) category.uid = StringUtil.generateUid();
    int id = await db.insert(
      tableName,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.categoriesInserted);
    Utils.initTray();
    return id;
  }

  static Future<int> insertCategories(List<TokenCategory> categories) async {
    if (categories.isEmpty) return 0;
    final db = await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (TokenCategory category in categories) {
      category.seq = await getMaxSeq() + 1 + categories.indexOf(category);
      category.id = await getMaxId() + 1 + categories.indexOf(category);
      if (category.uid.isEmpty) category.uid = StringUtil.generateUid();
      batch.insert(
        tableName,
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (category.bindings.isNotEmpty) {
        BindingDao.bingdingsForCategory(category.uid, category.bindings);
      }
    }
    List<dynamic> results = await batch.commit();
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.categoriesInserted);
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

  static Future<int> updateCategory(TokenCategory category) async {
    category.editTimeStamp = DateTime.now().millisecondsSinceEpoch;
    final db = await DatabaseManager.getDataBase();
    int id = await db.update(
      tableName,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.categoriesUpdated);
    Utils.initTray();
    return id;
  }

  static Future<int> updateCategories(
    List<TokenCategory> categories, {
    bool backup = false,
    Database? overrideDb,
  }) async {
    if (categories.isEmpty) return 0;
    final db = overrideDb ?? await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (TokenCategory category in categories) {
      category.editTimeStamp = DateTime.now().millisecondsSinceEpoch;
      batch.update(
        tableName,
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }
    List<dynamic> results = await batch.commit();
    if (backup) {
      ExportTokenUtil.autoBackup(
          triggerType: AutoBackupTriggerType.categoriesUpdated);
    }
    Utils.initTray();
    return results.length;
  }

  static Future<int> deleteCategory(TokenCategory category) async {
    final db = await DatabaseManager.getDataBase();
    await BindingDao.removeCategoryBindings(category.uid);
    int id = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [category.id],
    );
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.categoryDeleted);
    Utils.initTray();
    return id;
  }

  static Future<List<TokenCategory>> listCategories({
    bool desc = false,
    Database? overrideDb,
  }) async {
    final db = overrideDb ?? await DatabaseManager.getDataBase();
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

  static Future<TokenCategory> getCategoryByUid(String uid) async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return TokenCategory.fromMap(maps[0]);
  }

  static Future<List<OtpToken>> getTokensByCategoryUid(
    String uid, {
    String searchKey = "",
  }) async {
    if (uid.isEmpty) return await TokenDao.listTokens(searchKey: searchKey);
    TokenCategory category = await getCategoryByUid(uid);
    List<OtpToken> tokens =
        await BindingDao.getTokens(category.uid, searchKey: searchKey);
    tokens.sort((a, b) => -a.pinnedInt.compareTo(b.pinnedInt));
    return tokens;
  }
}
