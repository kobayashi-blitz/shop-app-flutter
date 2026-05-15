class TomorrowDeliveryItem {
  final int id;
  final String type; // rental / sale  (kubun から派生、UI 色分岐用)
  final String kubun; // 日本語ラベル（レンタル / 返却 / 汎用配送 / 預入引取 / 預入返却）
  final String customerName; // 利用者名
  final String deliveryDate; // 納品希望日 (YYYY/MM/DD)
  final String deliveryTime; // 納品時間（空文字の場合もあり）
  final String itemName; // 商品名
  final String
      placeDelivery; // 引渡し場所 (pcw `*.nouhin_place` / `r31.hikitori_place`)

  TomorrowDeliveryItem({
    required this.id,
    required this.type,
    required this.kubun,
    required this.customerName,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.itemName,
    required this.placeDelivery,
  });

  TomorrowDeliveryItem copyWith({
    int? id,
    String? type,
    String? kubun,
    String? customerName,
    String? deliveryDate,
    String? deliveryTime,
    String? itemName,
    String? placeDelivery,
  }) {
    return TomorrowDeliveryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      kubun: kubun ?? this.kubun,
      customerName: customerName ?? this.customerName,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      itemName: itemName ?? this.itemName,
      placeDelivery: placeDelivery ?? this.placeDelivery,
    );
  }

  /// pcw `haisouyotei/syosai` / `haisou-kanryo/syosai` レスポンスの 1 要素から構築する。
  ///
  /// 一覧表示に必要な項目のみ保持。利用者住所と配送担当者名は **詳細画面 (HaisouDetail) 経由** で取得し、
  /// 一覧モデルには持たない (PR 設計上、責務分離)。
  factory TomorrowDeliveryItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['primary_id'];
    final kubunRaw = (json['kubun'] ?? '').toString();

    return TomorrowDeliveryItem(
      id: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      type: _kubunToType(kubunRaw),
      kubun: _kubunToLabel(kubunRaw),
      customerName: (json['riyosya_name'] ?? '') as String,
      deliveryDate: (json['kibou_date'] ?? '') as String,
      deliveryTime: _pickDeliveryTime(json),
      itemName: _pickItemName(json),
      placeDelivery: (json['place_delivery'] ?? '') as String,
    );
  }

  /// kubun ('1'〜'5') → 色分岐用 type。汎用配送 (kubun=3) のみ 'sale' 緑バッジ、
  /// それ以外 (レンタル/返却/預入) は 'rental' 青バッジ。
  static String _kubunToType(String kubun) {
    return kubun == '3' ? 'sale' : 'rental';
  }

  static String _kubunToLabel(String kubun) {
    switch (kubun) {
      case '1':
        return 'レンタル';
      case '2':
        return '返却';
      case '3':
        return '汎用配送';
      case '4':
        return '預入引取';
      case '5':
        return '預入返却';
      default:
        return kubun;
    }
  }

  /// pcw 側 SELECT は kibou_time が空の種別もあるため hosoku (備考) で代用。
  static String _pickDeliveryTime(Map<String, dynamic> json) {
    final t = (json['kibou_time'] ?? '').toString();
    if (t.isNotEmpty) return t;
    return (json['hosoku'] ?? '').toString();
  }

  /// kubun=3 (汎用) のみ pn2.panhaisou_hinmei、他は syohin_name。
  /// fromJson はどちらも見て non-empty を採用する。
  static String _pickItemName(Map<String, dynamic> json) {
    final syohin = (json['syohin_name'] ?? '').toString();
    if (syohin.isNotEmpty) return syohin;
    return (json['panhaisou_hinmei'] ?? '').toString();
  }
}
