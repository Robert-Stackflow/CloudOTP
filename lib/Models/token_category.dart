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

import 'dart:convert';

import 'package:awesome_chewie/awesome_chewie.dart';

import '../Database/token_category_binding_dao.dart';
import '../Utils/utils.dart';
import 'Proto/TokenCategory/token_category_payload.pb.dart';
import 'opt_token.dart';

class TokenCategory {
  int id;
  String uid;
  int seq;
  String title;
  String description;
  int createTimeStamp;
  int editTimeStamp;
  bool pinned;
  Map<String, dynamic> remark;
  List<OtpToken> tokens = [];
  List<int> oldTokenIds = [];
  List<String> bindings = [];

  TokenCategory({
    required this.id,
    required this.uid,
    required this.seq,
    required this.title,
    required this.description,
    required this.createTimeStamp,
    required this.editTimeStamp,
    required this.pinned,
    required this.remark,
    this.oldTokenIds = const [],
    this.bindings = const [],
  });

  TokenCategory.title({
    required this.title,
    String? tUid,
  })  : id = 0,
        uid = tUid ?? StringUtil.generateUid(),
        seq = 0,
        createTimeStamp = DateTime.now().millisecondsSinceEpoch,
        editTimeStamp = DateTime.now().millisecondsSinceEpoch,
        pinned = false,
        remark = {},
        description = "";

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'seq': seq,
      'title': title,
      'description': description,
      'create_timestamp': createTimeStamp,
      'edit_timestamp': editTimeStamp,
      'pinned': pinned ? 1 : 0,
      'remark': jsonEncode(remark),
    };
  }

  Map<String, dynamic> toMapWithBindings() {
    return {
      'id': id,
      'uid': uid,
      'seq': seq,
      'title': title,
      'description': description,
      'create_timestamp': createTimeStamp,
      'edit_timestamp': editTimeStamp,
      'pinned': pinned ? 1 : 0,
      'remark': jsonEncode(remark),
      'bindings': bindings.join(","),
    };
  }

  Future<TokenCategoryParameters> toCategoryParameters() async {
    return TokenCategoryParameters(
      title: title,
      uid: uid,
      description: description,
      remark: jsonEncode(remark),
      bindings: (await BindingDao.getTokenUids(uid)).join(","),
    );
  }

  factory TokenCategory.fromCategoryParameters(
      TokenCategoryParameters parameters) {
    List<int> tmp = [];
    if (parameters.tokenIds.notNullOrEmpty) {
      for (String e in parameters.tokenIds.split(",")) {
        if (e.isNotEmpty) {
          tmp.add(int.tryParse(e) ?? -1);
        }
      }
    }
    return TokenCategory(
      id: 0,
      seq: 0,
      uid: parameters.uid,
      title: parameters.title,
      description: parameters.description,
      createTimeStamp: DateTime.now().millisecondsSinceEpoch,
      editTimeStamp: DateTime.now().millisecondsSinceEpoch,
      pinned: false,
      remark: jsonDecode(parameters.remark),
      bindings: parameters.bindings.split(","),
    );
  }

  factory TokenCategory.fromMap(Map<String, dynamic> map) {
    List<int> tmpIds = [];
    if ((map['token_ids'] as String?).notNullOrEmpty) {
      for (String e in map['token_ids'].split(",")) {
        if (e.isNotEmpty) {
          tmpIds.add(int.tryParse(e) ?? -1);
        }
      }
    }
    List<String> tmpBindings = [];
    if ((map['bindings'] as String?).notNullOrEmpty) {
      for (String e in map['bindings'].split(",")) {
        if (e.isNotEmpty) {
          tmpBindings.add(e);
        }
      }
    }
    return TokenCategory(
      id: map['id'],
      uid: map['uid'] ?? "",
      seq: map['seq'],
      title: map['title'],
      description: map['description'],
      createTimeStamp: map['create_timestamp'] ?? 0,
      editTimeStamp: map['edit_timestamp'] ?? 0,
      pinned: map['pinned'] == 1,
      remark: jsonDecode(map['remark']),
      oldTokenIds: tmpIds,
      bindings: tmpBindings,
    );
  }

  String toJson() => jsonEncode(toMap());

  String toJsonWithBindings() {
    return jsonEncode(toMapWithBindings());
  }

  factory TokenCategory.fromJson(String source) {
    return TokenCategory.fromMap(jsonDecode(source));
  }

  @override
  String toString() {
    return 'TokenCategory(id: $id, uid: $uid, seq: $seq, title: $title, description: $description, createTimeStamp: $createTimeStamp, editTimeStamp: $editTimeStamp, pinned: $pinned, remark: $remark, oldTokenIds: $oldTokenIds, bindings: $bindings)';
  }

  copyFrom(TokenCategory category) {
    id = category.id;
    uid = category.uid;
    seq = category.seq;
    title = category.title;
    description = category.description;
    createTimeStamp = category.createTimeStamp;
    editTimeStamp = category.editTimeStamp;
    pinned = category.pinned;
    remark = category.remark;
    bindings = category.bindings;
  }
}
