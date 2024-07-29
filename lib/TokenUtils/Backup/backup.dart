import 'dart:convert';

import '../../Models/category.dart';
import '../../Models/opt_token.dart';

class Backup {
  final List<OtpToken> tokens;
  final List<TokenCategory> categories;

  String get json => jsonEncode(toJson());

  Backup({required this.tokens, required this.categories});

  Map<String, dynamic> toJson() {
    return {
      'tokens': tokens.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }

  static Backup fromJson(Map<String, dynamic> json) {
    return Backup(
      tokens:
          (json['tokens'] as List).map((e) => OtpToken.fromJson(e)).toList(),
      categories: (json['categories'] as List)
          .map((e) => TokenCategory.fromJson(e))
          .toList(),
    );
  }
}
