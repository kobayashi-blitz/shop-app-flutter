class User {
  final int shopSyainId;
  final String shopSyainName;
  final int shopId;
  final String loginId;
  final String? bikou;
  final String? shopName;

  User({
    required this.shopSyainId,
    required this.shopSyainName,
    required this.shopId,
    required this.loginId,
    this.bikou,
    this.shopName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      shopSyainId: json['shop_syain_id'] as int,
      shopSyainName: json['shop_syain_name'] as String,
      shopId: json['shop_id'] as int,
      loginId: json['login_id'] as String? ?? '',
      bikou: json['shop_syain_bikou'] as String?,
      shopName: json['shop_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_syain_id': shopSyainId,
      'shop_syain_name': shopSyainName,
      'shop_id': shopId,
      'shop_syain_bikou': bikou,
    };
  }
}
