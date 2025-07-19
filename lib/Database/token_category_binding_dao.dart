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
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category_binding.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'database_manager.dart';

class BindingDao {
  static const String tableName = "token_category_binding";

  static Future<int> bingding(String tokenUid, String categoryUid) async {
    final db = await DatabaseManager.getDataBase();
    int id = await db.insert(
      tableName,
      TokenCategoryBinding(tokenUid: tokenUid, categoryUid: categoryUid)
          .toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<int> bingdings(
    List<TokenCategoryBinding> bindings, {
    Database? overrideDb,
  }) async {
    if (bindings.isEmpty) return 0;
    final db = overrideDb ?? await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    bindings = bindings.toSet().toList();
    for (TokenCategoryBinding binding in bindings) {
      batch.insert(
        tableName,
        binding.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    List<dynamic> results = await batch.commit();
    return results.length;
  }

  static Future<int> bingdingsForToken(
      String tokenUid, List<String> categoryUids) async {
    final db = await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (String uid in categoryUids) {
      batch.insert(
        tableName,
        TokenCategoryBinding(tokenUid: tokenUid, categoryUid: uid).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    List<dynamic> results = await batch.commit();
    return results.length;
  }

  static Future<int> bingdingsForCategory(
      String categoryUid, List<String> tokenUids) async {
    final db = await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (String uid in tokenUids) {
      batch.insert(
        tableName,
        TokenCategoryBinding(tokenUid: uid, categoryUid: categoryUid).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    List<dynamic> results = await batch.commit();
    return results.length;
  }

  static Future<int> unBinding(String tokenUid, String categoryUid) async {
    final db = await DatabaseManager.getDataBase();
    int id = await db.delete(
      tableName,
      where: "token_uid = ? AND category_uid = ?",
      whereArgs: [tokenUid, categoryUid],
    );
    return id;
  }

  static Future<int> removeTokenBindings(String tokenUid) async {
    List<String> categoryUids = await BindingDao.getCategoryUids(tokenUid);
    return await BindingDao.unBingdingsForToken(tokenUid, categoryUids);
  }

  static Future<int> removeCategoryBindings(String categoryUid) async {
    List<String> tokenUids = await BindingDao.getTokenUids(categoryUid);
    return await BindingDao.unBingdingsForCategory(categoryUid, tokenUids);
  }

  static Future<int> unBingdingsForToken(
      String tokenUid, List<String> categoryUids) async {
    final db = await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (String uid in categoryUids) {
      batch.delete(
        tableName,
        where: "token_uid = ? AND category_uid = ?",
        whereArgs: [tokenUid, uid],
      );
    }
    List<dynamic> results = await batch.commit();
    return results.length;
  }

  static Future<int> unBingdingsForCategory(
      String categoryUid, List<String> tokenUids) async {
    final db = await DatabaseManager.getDataBase();
    Batch batch = db.batch();
    for (String uid in tokenUids) {
      batch.delete(
        tableName,
        where: "token_uid = ? AND category_uid = ?",
        whereArgs: [uid, categoryUid],
      );
    }
    List<dynamic> results = await batch.commit();
    return results.length;
  }

  static Future<List<OtpToken>> getTokens(
    String categoryUid, {
    String searchKey = "",
  }) async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ["token_uid"],
      where: "category_uid = ?",
      whereArgs: [categoryUid],
    );
    List<String> uids = List.generate(maps.length, (i) => maps[i]["token_uid"]);
    uids = uids.toSet().toList();
    uids.removeWhere((e) => !StringUtil.isUid(e));
    List<OtpToken> tokens = [];
    for (String uid in uids) {
      OtpToken? token = await TokenDao.getTokenByUid(uid, searchKey: searchKey);
      if (token != null) {
        tokens.add(token);
      }
    }
    return tokens;
  }

  static Future<List<String>> getTokenUids(String categoryUid) async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ["token_uid"],
      where: "category_uid = ?",
      whereArgs: [categoryUid],
    );
    List<String> uids = List.generate(maps.length, (i) => maps[i]["token_uid"]);
    uids.removeWhere((e) => !StringUtil.isUid(e));
    return uids;
  }

  static Future<List<String>> getCategoryUids(String tokenUid) async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ["category_uid"],
      where: "token_uid = ?",
      whereArgs: [tokenUid],
    );
    List<String> uids =
        List.generate(maps.length, (i) => maps[i]["category_uid"]);
    uids.removeWhere((e) => !StringUtil.isUid(e));
    return uids;
  }

  static Future<List<TokenCategoryBinding>> listBindings() async {
    final db = await DatabaseManager.getDataBase();
    List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return TokenCategoryBinding.fromMap(maps[i]);
    });
  }
}
