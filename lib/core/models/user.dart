class User {
  final int shopSyainId;
  final String shopSyainName;
  final String shopId;
  final String loginId;
  final String? bikou;

  User({
    required this.shopSyainId,
    required this.shopSyainName,
    required this.shopId,
    required this.loginId,
    this.bikou,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      shopSyainId: json['shop_syain_id'] as int,
      shopSyainName: json['shop_syain_name'] as String,
      shopId: json['shop_id'] as String,
      loginId: json['login_id'] as String? ?? '',
      bikou: json['shop_syain_bikou'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_syain_id': shopSyainId,
      'shop_syain_name': shopSyainName,
      'shop_id': shopId,
      'login_id': loginId,
      'shop_syain_bikou': bikou,
    };
  }
}
