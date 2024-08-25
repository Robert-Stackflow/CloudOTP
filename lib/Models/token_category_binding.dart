class TokenCategoryBinding{
  String tokenUid;
  String categoryUid;

  TokenCategoryBinding({
    required this.tokenUid,
    required this.categoryUid,
  });

  factory TokenCategoryBinding.fromMap(Map<String, dynamic> map){
    return TokenCategoryBinding(
      tokenUid: map['token_uid'],
      categoryUid: map['category_uid'],
    );
  }

  Map<String, dynamic> toMap(){
    return {
      'token_uid': tokenUid,
      'category_uid': categoryUid,
    };
  }
}