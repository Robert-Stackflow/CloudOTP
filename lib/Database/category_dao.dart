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
import '../Models/token_category_binding.dart';
import '../Utils/utils.dart';
import 'database_manager.dart';

class CategoryDao {
  static const String tableName = "token_category";

  static Future<int> insertCategory(TokenCategory category) async {
    final db = await DatabaseManager.getDataBase();
    category.seq = await getMaxSeq() + 1;
    if (category.uid.isEmpty) category.uid = StringUtil.generateUid();
    final values = category.toMap()..remove('id');
    final id = await db.insert(
      tableName,
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    category.id = id;
    ExportTokenUtil.autoBackup(
        triggerType: AutoBackupTriggerType.categoriesInserted);
    Utils.initTray();
    return id;
  }

  static Future<int> insertCategories(
    List<TokenCategory> categories, {
    DatabaseExecutor? overrideDb,
    bool notifyChanges = true,
  }) async {
    if (categories.isEmpty) return 0;
    final db = overrideDb ?? await DatabaseManager.getDataBase();
    int maxSeq = await getMaxSeq(overrideDb: db);
    for (int i = 0; i < categories.length; i++) {
      TokenCategory category = categories[i];
      if (category.seq <= 0) {
        category.seq = maxSeq + 1 + i;
      }
      if (category.uid.isEmpty) category.uid = StringUtil.generateUid();
    }
    Future<List<dynamic>> insertWithExecutor(DatabaseExecutor executor) async {
      final batch = executor.batch();
      for (final category in categories) {
        final values = category.toMap()..remove('id');
        batch.insert(
          tableName,
          values,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      final insertedIds = await batch.commit(noResult: false);
      final bindings = categories
          .expand((category) => category.bindings.map(
                (tokenUid) => TokenCategoryBinding(
                  tokenUid: tokenUid,
                  categoryUid: category.uid,
                ),
              ))
          .toList();
      await BindingDao.bingdings(bindings, overrideDb: executor);
      return insertedIds;
    }

    final results = overrideDb != null
        ? await insertWithExecutor(overrideDb)
        : await (db as Database).transaction(insertWithExecutor);
    for (int i = 0; i < results.length; i++) {
      categories[i].id = results[i] as int;
    }
    if (notifyChanges) {
      ExportTokenUtil.autoBackup(
          triggerType: AutoBackupTriggerType.categoriesInserted);
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
    DatabaseExecutor? overrideDb,
    bool notifyChanges = true,
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
    if (backup && notifyChanges) {
      ExportTokenUtil.autoBackup(
          triggerType: AutoBackupTriggerType.categoriesUpdated);
    }
    if (notifyChanges) Utils.initTray();
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
    DatabaseExecutor? overrideDb,
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
    List<String> tags = const [],
    String? tokenType,
  }) async {
    if (uid.isEmpty) {
      return await TokenDao.listTokens(
          searchKey: searchKey, tags: tags, tokenType: tokenType);
    }
    return TokenDao.listTokensByCategoryUid(
      uid,
      searchKey: searchKey,
      tags: tags,
      tokenType: tokenType,
    );
  }

  static Future<List<String>> getCategoryUidsByName(String name) async {
    final db = await DatabaseManager.getDataBase();
    final maps = await db.query(
      tableName,
      columns: ['uid'],
      where: 'title LIKE ?',
      whereArgs: ['%$name%'],
    );
    return maps.map((m) => m['uid'] as String).toList();
  }
}
