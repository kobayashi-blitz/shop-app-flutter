class RentalSyohinItem {
  final int primaryId;
  final String riyosyaName;
  final String syohinName;
  final String syohinClass1;
  final String keiyakuDateFrom;

  RentalSyohinItem({
    required this.primaryId,
    required this.riyosyaName,
    required this.syohinName,
    required this.syohinClass1,
    required this.keiyakuDateFrom,
  });

  factory RentalSyohinItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['primary_id'];
    return RentalSyohinItem(
      primaryId: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      riyosyaName: (json['riyosya_name'] ?? '') as String,
      syohinName: (json['syohin_name'] ?? '') as String,
      syohinClass1: (json['syohin_class_1'] ?? '') as String,
      keiyakuDateFrom: (json['keiyaku_date_from'] ?? '') as String,
    );
  }
}
