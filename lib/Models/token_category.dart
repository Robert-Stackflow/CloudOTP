import 'dart:convert';

import '../Utils/utils.dart';
import 'Proto/TokenCategory/token_category_payload.pb.dart';
import 'opt_token.dart';

class TokenCategory {
  int id;
  int seq;
  String title;
  String description;
  int createTimeStamp;
  int editTimeStamp;
  bool pinned;
  Map<String, dynamic> remark;
  List<int> tokenIds;
  List<OtpToken> tokens=[];

  TokenCategory({
    required this.tokenIds,
    required this.id,
    required this.seq,
    required this.title,
    required this.description,
    required this.createTimeStamp,
    required this.editTimeStamp,
    required this.pinned,
    required this.remark,
  });

  TokenCategory.title({
    required this.title,
  })  : id = 0,
        seq = 0,
        createTimeStamp = DateTime.now().millisecondsSinceEpoch,
        editTimeStamp = DateTime.now().millisecondsSinceEpoch,
        pinned = false,
        remark = {},
        description = "",
        tokenIds = [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seq': seq,
      'title': title,
      'description': description,
      'create_timestamp': createTimeStamp,
      'edit_timestamp': editTimeStamp,
      'pinned': pinned ? 1 : 0,
      'remark': jsonEncode(remark),
      'token_ids': tokenIds.join(","),
    };
  }

  TokenCategoryParameters toCategoryParameters() {
    return TokenCategoryParameters(
      title: title,
      description: description,
      remark: jsonEncode(remark),
      tokenIds: tokenIds.join(","),
    );
  }

  factory TokenCategory.fromCategoryParameters(TokenCategoryParameters parameters) {
    List<int> tmp = [];
    if (Utils.isNotEmpty(parameters.tokenIds)) {
      for (String e in parameters.tokenIds.split(",")) {
        if (e.isNotEmpty) {
          tmp.add(int.tryParse(e) ?? -1);
        }
      }
    }
    return TokenCategory(
      id: 0,
      seq: 0,
      title: parameters.title,
      description: parameters.description,
      createTimeStamp: DateTime.now().millisecondsSinceEpoch,
      editTimeStamp: DateTime.now().millisecondsSinceEpoch,
      pinned: false,
      remark: jsonDecode(parameters.remark),
      tokenIds: tmp,
    );
  }

  factory TokenCategory.fromMap(Map<String, dynamic> map) {
    List<int> tmp = [];
    if (Utils.isNotEmpty(map['token_ids'])) {
      for (String e in map['token_ids'].split(",")) {
        if (e.isNotEmpty) {
          tmp.add(int.tryParse(e) ?? -1);
        }
      }
    }
    return TokenCategory(
      id: map['id'],
      seq: map['seq'],
      title: map['title'],
      description: map['description'],
      createTimeStamp: map['create_timestamp'] ?? 0,
      editTimeStamp: map['edit_timestamp'] ?? 0,
      pinned: map['pinned'] == 1,
      remark: jsonDecode(map['remark']),
      tokenIds: tmp,
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory TokenCategory.fromJson(String source) {
    return TokenCategory.fromMap(jsonDecode(source));
  }

  @override
  String toString() {
    return 'Category{id: $id, seq: $seq, title: $title, description: $description, createTimeStamp: $createTimeStamp, editTimeStamp: $editTimeStamp, pinned: $pinned, remark: $remark, tokenIds: $tokenIds}';
  }

  copyFrom(TokenCategory category) {
    id = category.id;
    seq = category.seq;
    title = category.title;
    description = category.description;
    createTimeStamp = category.createTimeStamp;
    editTimeStamp = category.editTimeStamp;
    pinned = category.pinned;
    remark = category.remark;
    tokenIds = category.tokenIds;
  }
}
