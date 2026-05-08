class SeikyuMonth {
  final String yearMonth; // "YYYY-MM"
  final String display; // "YYYY年n月"

  const SeikyuMonth({required this.yearMonth, required this.display});

  factory SeikyuMonth.fromJson(Map<String, dynamic> json) {
    return SeikyuMonth(
      yearMonth: (json['year_month'] ?? '').toString(),
      display: (json['display'] ?? '').toString(),
    );
  }
}
