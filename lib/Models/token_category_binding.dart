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

class TokenCategoryBinding {
  String tokenUid;
  String categoryUid;

  TokenCategoryBinding({
    required this.tokenUid,
    required this.categoryUid,
  });

  factory TokenCategoryBinding.fromMap(Map<String, dynamic> map) {
    return TokenCategoryBinding(
      tokenUid: map['token_uid'],
      categoryUid: map['category_uid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'token_uid': tokenUid,
      'category_uid': categoryUid,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory TokenCategoryBinding.fromJson(String source) =>
      TokenCategoryBinding.fromMap(jsonDecode(source));

  @override
  String toString() =>
      'TokenCategoryBinding(tokenUid: $tokenUid, categoryUid: $categoryUid)';

  @override
  bool operator ==(Object other) {
    return other is TokenCategoryBinding &&
        other.tokenUid == tokenUid &&
        other.categoryUid == categoryUid;
  }

  @override
  int get hashCode => tokenUid.hashCode ^ categoryUid.hashCode;
}
