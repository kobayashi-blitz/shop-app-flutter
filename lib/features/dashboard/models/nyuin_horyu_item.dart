class NyuinHoryuItem {
  final int primaryId;
  final String riyosyaName;
  final String syohinName;
  final String syohinClass1;
  final String horyuDateFrom;
  final String? horyuDateTo;

  NyuinHoryuItem({
    required this.primaryId,
    required this.riyosyaName,
    required this.syohinName,
    required this.syohinClass1,
    required this.horyuDateFrom,
    this.horyuDateTo,
  });

  factory NyuinHoryuItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['primary_id'];
    return NyuinHoryuItem(
      primaryId: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      riyosyaName: (json['riyosya_name'] ?? '') as String,
      syohinName: (json['syohin_name'] ?? '') as String,
      syohinClass1: (json['syohin_class_1'] ?? '') as String,
      horyuDateFrom: (json['horyu_date_from'] ?? '') as String,
      horyuDateTo: json['horyu_date_to'] as String?,
    );
  }
}
