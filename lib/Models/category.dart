import 'dart:convert';

import '../Utils/utils.dart';

class Category {
  int id;
  int seq;
  String title;
  String description;
  int createTimeStamp;
  int editTimeStamp;
  bool pinned;
  Map<String, dynamic> remark;
  List<int> tokenIds;

  Category({
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

  Category.title({
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
      'create_time_stamp': createTimeStamp,
      'edit_time_stamp': editTimeStamp,
      'pinned': pinned ? 1 : 0,
      'remark': jsonEncode(remark),
      'token_ids': tokenIds.join(","),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    List<int> tmp = [];
    if (Utils.isNotEmpty(map['token_ids'])) {
      for (String e in map['token_ids'].split(",")) {
        if (e.isNotEmpty) {
          tmp.add(int.tryParse(e) ?? -1);
        }
      }
    }
    return Category(
      id: map['id'],
      seq: map['seq'],
      title: map['title'],
      description: map['description'],
      createTimeStamp: map['create_time_stamp'],
      editTimeStamp: map['edit_time_stamp'],
      pinned: map['pinned'] == 1,
      remark: jsonDecode(map['remark']),
      tokenIds: tmp,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, seq: $seq, title: $title, description: $description, createTimeStamp: $createTimeStamp, editTimeStamp: $editTimeStamp, pinned: $pinned, remark: $remark, tokenIds: $tokenIds}';
  }
}
