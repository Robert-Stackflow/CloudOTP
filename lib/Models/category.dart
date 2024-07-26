class Category {
  int id;
  int seq;
  String title;
  String description;
  int createTimeStamp;
  int editTimeStamp;
  bool pinned;
  Map<String, dynamic> remark;

  Category({
    required this.id,
    required this.seq,
    required this.title,
    required this.description,
    required this.createTimeStamp,
    required this.editTimeStamp,
    required this.pinned,
    required this.remark,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seq': seq,
      'title': title,
      'description': description,
      'createTimeStamp': createTimeStamp,
      'editTimeStamp': editTimeStamp,
      'pinned': pinned,
      'remark': remark,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      seq: map['seq'],
      title: map['title'],
      description: map['description'],
      createTimeStamp: map['createTimeStamp'],
      editTimeStamp: map['editTimeStamp'],
      pinned: map['pinned'],
      remark: map['remark'],
    );
  }
}
