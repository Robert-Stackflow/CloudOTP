import 'dart:convert';

class Config {
  int id;
  String backupPassword;
  Map<String, dynamic> remark;

  Config({
    this.id = 0,
    this.backupPassword = "",
    this.remark = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "backup_password": backupPassword,
      "remark": jsonEncode(remark),
    };
  }

  factory Config.fromMap(Map<String, dynamic> map) {
    return Config(
      id: map["id"],
      backupPassword: map["backup_password"],
      remark: jsonDecode(map["remark"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "backup_password": backupPassword,
      "remark": remark,
    };
  }

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      id: json["id"],
      backupPassword: json["backup_password"],
      remark: json["remark"],
    );
  }
}
