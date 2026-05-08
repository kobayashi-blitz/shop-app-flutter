class DenpyoSearchItem {
  final int targetId;
  final String denpyoType; // "1"〜"5","7"
  final String syurui; // "レンタル納品伝票" 等
  final String riyosyaName;
  final String riyosyaKana;
  final String? bikou;
  final String denpyoDate; // "YYYY年MM月DD日"
  final bool hasSignature;

  const DenpyoSearchItem({
    required this.targetId,
    required this.denpyoType,
    required this.syurui,
    required this.riyosyaName,
    required this.riyosyaKana,
    required this.bikou,
    required this.denpyoDate,
    required this.hasSignature,
  });

  factory DenpyoSearchItem.fromJson(Map<String, dynamic> json) {
    return DenpyoSearchItem(
      targetId: int.tryParse('${json['target_id']}') ?? 0,
      denpyoType: (json['denpyo_type'] ?? '').toString(),
      syurui: (json['syurui'] ?? '').toString(),
      riyosyaName: (json['riyosya_name'] ?? '').toString(),
      riyosyaKana: (json['riyosya_kana'] ?? '').toString(),
      bikou: json['sonota_denpyo_bikou']?.toString(),
      denpyoDate: (json['denpyo_date'] ?? '').toString(),
      hasSignature: ((json['syomei_ari'] ?? '').toString()).isNotEmpty,
    );
  }

  /// pcw 側 print API に渡す mytype 文字列
  String get mytype {
    switch (denpyoType) {
      case '1':
        return 'nouhin';
      case '2':
        return 'hanbai';
      case '3':
        return 'hanyohaiso';
      case '4':
        return 'henkyaku';
      case '5':
        return 'azukari';
      case '7':
        return 'senjo';
      default:
        return '';
    }
  }
}

/// チェックボックス UI 用の伝票種類定義
class DenpyoTypeOption {
  final String code; // "1","2","3","4","5","7"
  final String label; // 表示名
  const DenpyoTypeOption(this.code, this.label);

  static const List<DenpyoTypeOption> all = [
    DenpyoTypeOption('1', 'レンタル納品伝票'),
    DenpyoTypeOption('2', '販売納品伝票'),
    DenpyoTypeOption('3', '汎用配送伝票'),
    DenpyoTypeOption('4', 'レンタル返却伝票'),
    DenpyoTypeOption('5', '預かり品'),
    DenpyoTypeOption('7', '洗浄'),
  ];
}
