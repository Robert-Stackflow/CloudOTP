import 'dart:convert';

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
  List<String> bindings=[];

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
  })  : id = 0,
        uid = Utils.generateUid(),
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
      uid: map['uid'] ?? "",
      seq: map['seq'],
      title: map['title'],
      description: map['description'],
      createTimeStamp: map['create_timestamp'] ?? 0,
      editTimeStamp: map['edit_timestamp'] ?? 0,
      pinned: map['pinned'] == 1,
      remark: jsonDecode(map['remark']),
      oldTokenIds: tmp,
      bindings: map['bindings'] ?? [],
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
    return 'Category{id: $id, seq: $seq, title: $title, description: $description, createTimeStamp: $createTimeStamp, editTimeStamp: $editTimeStamp, pinned: $pinned, remark: $remark}';
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
  }
}
