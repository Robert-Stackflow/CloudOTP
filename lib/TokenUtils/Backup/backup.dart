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

import '../../Models/opt_token.dart';
import '../../Models/token_category.dart';

class Backup {
  final List<OtpToken> tokens;
  final List<TokenCategory> categories;

  String get json => jsonEncode(toJson());

  Backup({
    required this.tokens,
    required this.categories,
  });

  Map<String, dynamic> toJson() {
    return {
      'tokens': tokens.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJsonWithBindings()).toList(),
    };
  }

  static Backup fromJson(Map<String, dynamic> json) {
    return Backup(
      tokens: json['tokens'] != null
          ? (json['tokens'] as List).map((e) => OtpToken.fromJson(e)).toList()
          : [],
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((e) => TokenCategory.fromJson(e))
              .toList()
          : [],
    );
  }
}
