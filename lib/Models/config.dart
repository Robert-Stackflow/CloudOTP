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
