/// 配送詳細 API (`POST /api/pcwMobileApi/shop/haisou/detail`) のレスポンス。
///
/// 1 配送 (`hs1.haisou_id`) を起点に取得した、配送ヘッダ情報 + 商品リスト。
/// レスポンス JSON 構造:
/// ```json
/// {
///   "result": "1",
///   "detail": { ... }, // 配送ヘッダ
///   "products": [ ... ] // 商品リスト
/// }
/// ```
class HaisouDetail {
  final int haisouId;
  final String kubun; // '1'〜'5'
  final String receptionNo;
  final String contractStartDate;
  final String sitenName;
  final String riyosyaName;
  final String riyosyaTel;
  final String riyosyaAddress;
  final String placeDelivery;
  final String hikkosiAddress;
  final String haisouTantoName;
  final String agentTantoName;
  final String footerComment;
  final bool isDelivered;
  final List<HaisouDetailProduct> products;

  HaisouDetail({
    required this.haisouId,
    required this.kubun,
    required this.receptionNo,
    required this.contractStartDate,
    required this.sitenName,
    required this.riyosyaName,
    required this.riyosyaTel,
    required this.riyosyaAddress,
    required this.placeDelivery,
    required this.hikkosiAddress,
    required this.haisouTantoName,
    required this.agentTantoName,
    required this.footerComment,
    required this.isDelivered,
    required this.products,
  });

  factory HaisouDetail.fromJson(
    Map<String, dynamic> detailJson,
    List<dynamic> productsJson,
  ) {
    final idRaw = detailJson['haisou_id'];
    return HaisouDetail(
      haisouId: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      kubun: (detailJson['kubun'] ?? '').toString(),
      receptionNo: (detailJson['reception_no'] ?? '') as String,
      contractStartDate: (detailJson['contract_start_date'] ?? '') as String,
      sitenName: (detailJson['siten_name'] ?? '') as String,
      riyosyaName: (detailJson['riyosya_name'] ?? '') as String,
      riyosyaTel: (detailJson['riyosya_tel'] ?? '') as String,
      riyosyaAddress: (detailJson['riyosya_address'] ?? '') as String,
      placeDelivery: (detailJson['place_delivery'] ?? '') as String,
      hikkosiAddress: (detailJson['hikkosi_address'] ?? '') as String,
      haisouTantoName: (detailJson['haisou_tanto_name'] ?? '') as String,
      agentTantoName: (detailJson['agent_tanto_name'] ?? '') as String,
      footerComment: (detailJson['footer_comment'] ?? '') as String,
      isDelivered: _parseBool(detailJson['is_delivered']),
      products: productsJson
          .whereType<Map>()
          .map(
              (e) => HaisouDetailProduct.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// pcw 側は 0/1 (int) or '0'/'1' (string) で返す可能性があるので両対応。
  static bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }
}

class HaisouDetailProduct {
  final String name;
  final String katasiki;
  final String rentalNo;
  final int qty;
  final String comment;

  HaisouDetailProduct({
    required this.name,
    required this.katasiki,
    required this.rentalNo,
    required this.qty,
    required this.comment,
  });

  factory HaisouDetailProduct.fromJson(Map<String, dynamic> json) {
    final qtyRaw = json['qty'];
    return HaisouDetailProduct(
      name: (json['name'] ?? '') as String,
      katasiki: (json['katasiki'] ?? '') as String,
      rentalNo: (json['rental_no'] ?? '') as String,
      qty: qtyRaw is int ? qtyRaw : int.tryParse('$qtyRaw') ?? 1,
      comment: (json['comment'] ?? '') as String,
    );
  }
}
