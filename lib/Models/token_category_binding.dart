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
