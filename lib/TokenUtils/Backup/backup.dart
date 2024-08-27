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
