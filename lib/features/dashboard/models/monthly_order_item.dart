class MonthlyOrderItem {
  final int primaryId;
  final String kubun;
  final String orderMoshikomiDate;
  final String riyosyaName;
  final String syohinName;

  MonthlyOrderItem({
    required this.primaryId,
    required this.kubun,
    required this.orderMoshikomiDate,
    required this.riyosyaName,
    required this.syohinName,
  });

  factory MonthlyOrderItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['primary_id'];
    return MonthlyOrderItem(
      primaryId: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      kubun: (json['kubun'] ?? '') as String,
      orderMoshikomiDate: (json['order_moshikomi_date'] ?? '') as String,
      riyosyaName: (json['riyosya_name'] ?? '') as String,
      syohinName: (json['syohin_name'] ?? '') as String,
    );
  }
}
