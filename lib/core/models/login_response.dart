import 'user.dart';

/// レスポンス形式:
/// {
///   "status": "OK" | "NG",
///   "message": "...",
///   "data": {
///     "shop_syain_id": 123,
///     "shop_syain_name": "山田太郎",
///     "shop_id": "0001",
///     "login_id": "taro",
///     "shop_syain_bikou": "メモ"
///   }
/// }
class LoginResponse {
  final String status;
  final String message;
  final User? user;

  LoginResponse({
    required this.status,
    required this.message,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      // Laravel 側では `data` 配下に担当者情報を返している想定
      user: json['data'] != null
          ? User.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
