/// レンタル売上の月別 1 行を表すモデル。
///
/// pcw `rental-uriage/monthly` API の `months[]` 要素から構築する。
/// 当月含む過去 13 ヶ月分が DESC 順で返り、データなし月は 0 埋めされている。
class RentalUriageMonthItem {
  /// 年月 (例: "2026/05")
  final String ym;

  /// 月の税込合計 (rental_kin + rental_tax)
  final int rentalKin;

  /// u01 売上明細件数
  final int count;

  const RentalUriageMonthItem({
    required this.ym,
    required this.rentalKin,
    required this.count,
  });

  factory RentalUriageMonthItem.fromJson(Map<String, dynamic> json) {
    return RentalUriageMonthItem(
      ym: (json['ym'] ?? '').toString(),
      rentalKin: int.tryParse('${json['rental_kin']}') ?? 0,
      count: int.tryParse('${json['count']}') ?? 0,
    );
  }
}
