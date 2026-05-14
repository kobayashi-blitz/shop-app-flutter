class DashboardData {
  final UserInfo user;
  final DeliveryInfo delivery;
  final UsageInfo usage;

  DashboardData({
    required this.user,
    required this.delivery,
    required this.usage,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
      delivery: DeliveryInfo.fromJson(json['delivery'] as Map<String, dynamic>),
      usage: UsageInfo.fromJson(json['usage'] as Map<String, dynamic>),
    );
  }
}

class UserInfo {
  final String name;
  final String officeName;
  // 代理店名
  final String shopName;
  // 代理店ID
  final int? shopId;
  // 担当者名（ログインユーザー名）
  final String? shopSyainName;

  UserInfo({
    required this.name,
    required this.officeName,
    required this.shopName,
    this.shopId,
    this.shopSyainName,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      name: json['name'] as String? ?? '',
      officeName: json['office_name'] as String? ?? '',
      shopName: json['shop_name'] as String? ?? '',
      shopId: json['shop_id'] as int?,
      shopSyainName: json['shop_syain_name'] as String?,
    );
  }
}

class DeliveryInfo {
  /// 「配送予定」カードの件数。表示対象日は [scheduledTargetDate]
  /// （17 時切替: 16:59 まで今日、17:00 から翌日）。
  final int tomorrowScheduledCount;

  /// 「配送完了」カードの件数。表示対象日は [completedTargetDate]（常に当日）。
  /// API 未実装のため当面 0 固定。実装後に実値を入れる。
  final int completedTodayCount;

  /// 配送予定カードのタイトルに表示する日付（17 時を境に切替）
  final DateTime scheduledTargetDate;

  /// 配送完了カードのタイトルに表示する日付（常に当日）
  final DateTime completedTargetDate;

  DeliveryInfo({
    required this.tomorrowScheduledCount,
    required this.completedTodayCount,
    required this.scheduledTargetDate,
    required this.completedTargetDate,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return DeliveryInfo(
      tomorrowScheduledCount: json['tomorrow_scheduled_count'] as int,
      completedTodayCount: json['completed_today_count'] as int,
      scheduledTargetDate: now,
      completedTargetDate: DateTime(now.year, now.month, now.day),
    );
  }
}

class UsageInfo {
  final int hospitalOnHoldCount;
  final int contractUserCount;
  final int rentalInUseCount;
  final int rentalSalesAmountMonth;
  final int newOrdersThisMonthCount;
  final int oneMonthDemoCount;

  UsageInfo({
    required this.hospitalOnHoldCount,
    required this.contractUserCount,
    required this.rentalInUseCount,
    required this.rentalSalesAmountMonth,
    required this.newOrdersThisMonthCount,
    this.oneMonthDemoCount = 0,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) {
    return UsageInfo(
      hospitalOnHoldCount: json['hospital_on_hold_count'] as int,
      contractUserCount: json['contract_user_count'] as int,
      rentalInUseCount: json['rental_in_use_count'] as int,
      rentalSalesAmountMonth: json['rental_sales_amount_month'] as int,
      newOrdersThisMonthCount: json['new_orders_this_month_count'] as int,
    );
  }
}
