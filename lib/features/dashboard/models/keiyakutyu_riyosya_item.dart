class KeiyakutyuRiyosyaItem {
  final int primaryId;
  final String riyosyaName;
  final String syohinName;
  final String keiyakuDateFrom;

  KeiyakutyuRiyosyaItem({
    required this.primaryId,
    required this.riyosyaName,
    required this.syohinName,
    required this.keiyakuDateFrom,
  });

  factory KeiyakutyuRiyosyaItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['primary_id'];
    return KeiyakutyuRiyosyaItem(
      primaryId: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      riyosyaName: (json['riyosya_name'] ?? '') as String,
      syohinName: (json['syohin_name'] ?? '') as String,
      keiyakuDateFrom: (json['keiyaku_date_from'] ?? '') as String,
    );
  }
}
