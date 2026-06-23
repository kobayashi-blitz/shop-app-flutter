/// 入院保留申請 (SAP-13) 関連の API モデル。
///
/// architecture.md 規約に従い、JSON キーは pcw 側のスネークケースを保持し、
/// `fromJson` ファクトリで Dart のキャメルケースフィールドにマッピングする。
library;

/// 1 件のレンタル契約商品。
class SinseiRentalItem {
  final int rentalId;
  final int zaikoId;
  final String rentalNo;
  final String syohinName;
  final String? rentalTankaFlag;
  final String keiyakuDateFrom;
  final String? keiyakuDateTo;
  final int? rentalHoryuSyohinId;
  final List<SinseiHoryuKikan> horyuKikan;

  const SinseiRentalItem({
    required this.rentalId,
    required this.zaikoId,
    required this.rentalNo,
    required this.syohinName,
    required this.rentalTankaFlag,
    required this.keiyakuDateFrom,
    required this.keiyakuDateTo,
    required this.rentalHoryuSyohinId,
    required this.horyuKikan,
  });

  factory SinseiRentalItem.fromJson(Map<String, dynamic> json) {
    final kikanList = (json['horyu_kikan'] as List?) ?? const [];
    return SinseiRentalItem(
      rentalId: (json['rental_id'] as num?)?.toInt() ?? 0,
      zaikoId: (json['zaiko_id'] as num?)?.toInt() ?? 0,
      rentalNo: (json['rental_no'] ?? '') as String,
      syohinName: (json['syohin_name'] ?? '') as String,
      rentalTankaFlag: json['rental_tanka_flag'] as String?,
      keiyakuDateFrom: (json['keiyaku_date_from'] ?? '') as String,
      keiyakuDateTo: json['keiyaku_date_to'] as String?,
      rentalHoryuSyohinId: (json['rental_horyu_syohin_id'] as num?)?.toInt(),
      horyuKikan: kikanList
          .whereType<Map>()
          .map((e) => SinseiHoryuKikan.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// 既存の保留期間（同 rental に対する過去 / 現在の保留期間）。
class SinseiHoryuKikan {
  final String horyuDateFrom;
  final String? horyuDateTo;

  const SinseiHoryuKikan({
    required this.horyuDateFrom,
    required this.horyuDateTo,
  });

  factory SinseiHoryuKikan.fromJson(Map<String, dynamic> json) {
    return SinseiHoryuKikan(
      horyuDateFrom: (json['horyu_date_from'] ?? '') as String,
      horyuDateTo: json['horyu_date_to'] as String?,
    );
  }
}

/// 利用者単位の保留レコード（保留中 or 履歴）。
class SinseiHoryuRecord {
  final int rentalHoryuId;
  final String horyuDateFrom;
  final String? horyuDateTo;
  final String inputDate;
  final bool isPending;
  final String syainName;

  const SinseiHoryuRecord({
    required this.rentalHoryuId,
    required this.horyuDateFrom,
    required this.horyuDateTo,
    required this.inputDate,
    required this.isPending,
    required this.syainName,
  });

  factory SinseiHoryuRecord.fromJson(Map<String, dynamic> json) {
    return SinseiHoryuRecord(
      rentalHoryuId: (json['rental_horyu_id'] as num?)?.toInt() ?? 0,
      horyuDateFrom: (json['horyu_date_from'] ?? '') as String,
      horyuDateTo: json['horyu_date_to'] as String?,
      inputDate: (json['input_date'] ?? '') as String,
      isPending: (json['is_pending'] ?? false) as bool,
      syainName: (json['syain_name'] ?? '') as String,
    );
  }
}

/// 変更申請モード時の対象保留商品。pcw 側スキーマがやや複雑なので
/// raw Map を保持しつつ、よく使うフィールドだけ getter で公開。
class SinseiHoryuOrder {
  final Map<String, dynamic> raw;

  const SinseiHoryuOrder(this.raw);

  factory SinseiHoryuOrder.fromJson(Map<String, dynamic> json) =>
      SinseiHoryuOrder(Map<String, dynamic>.from(json));

  int get rentalId => (raw['rental_id'] as num?)?.toInt() ?? 0;
  int? get rentalHoryuSyohinId =>
      (raw['rental_horyu_syohin_id'] as num?)?.toInt();
  int get zaikoId => (raw['zaiko_id'] as num?)?.toInt() ?? 0;
  String get rentalNo => (raw['rental_no'] ?? '') as String;
  String get syohinName => (raw['syohin_name'] ?? '') as String;
  String? get rentalTankaFlag => raw['rental_tanka_flag'] as String?;
  String get keiyakuDateFrom => (raw['keiyaku_date_from'] ?? '') as String;
  String? get keiyakuDateTo => raw['keiyaku_date_to'] as String?;
  String get horyuDateFrom => (raw['horyu_date_from'] ?? '') as String;
  String? get horyuDateTo => raw['horyu_date_to'] as String?;

  /// 変更時のコンフリクト検出に使う「DB の元値」(Y-m-d 形式)
  String get oldHoryuDateFrom => (raw['old_horyu_date_from'] ?? '') as String;
  String? get oldHoryuDateTo => raw['old_horyu_date_to'] as String?;

  /// 変更モード初期化時に画面の開始日/終了日に prefill する値 (Y/m/d 形式)
  String get inpHoryuDateFrom => (raw['inp_horyu_date_from'] ?? '') as String;
  String? get inpHoryuDateTo => raw['inp_horyu_date_to'] as String?;
}

/// 入院保留申請 create エンドポイントのレスポンス全体。
///
/// pcw レスポンス例:
/// ```
/// {
///   "result": "1",
///   "sinsei_kubun": "1",
///   "riyosya": {"riyosya_id":345, "riyosya_kana":"...", "riyosya_name":"...", "shop_name":"..."},
///   "rentals": [...],
///   "onhoryu_list": [...],
///   "offhoryu_list": [...],
///   "horyu_orders": [...]
/// }
/// ```
class SinseiCreateData {
  final String sinseiKubun; // '1':新規, '2':変更
  final int riyosyaId;
  final String riyosyaKana;
  final String riyosyaName;
  final String shopName;
  final List<SinseiRentalItem> rentals;
  final List<SinseiHoryuRecord> onhoryuList;
  final List<SinseiHoryuRecord> offhoryuList;
  final List<SinseiHoryuOrder> horyuOrders;

  const SinseiCreateData({
    required this.sinseiKubun,
    required this.riyosyaId,
    required this.riyosyaKana,
    required this.riyosyaName,
    required this.shopName,
    required this.rentals,
    required this.onhoryuList,
    required this.offhoryuList,
    required this.horyuOrders,
  });

  factory SinseiCreateData.fromJson(Map<String, dynamic> json) {
    final riyosya =
        (json['riyosya'] as Map?)?.cast<String, dynamic>() ?? const {};

    List<T> parseList<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      return ((raw as List?) ?? const [])
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return SinseiCreateData(
      sinseiKubun: (json['sinsei_kubun'] ?? '1') as String,
      riyosyaId: (riyosya['riyosya_id'] as num?)?.toInt() ?? 0,
      riyosyaKana: (riyosya['riyosya_kana'] ?? '') as String,
      riyosyaName: (riyosya['riyosya_name'] ?? '') as String,
      shopName: (riyosya['shop_name'] ?? '') as String,
      rentals: parseList(json['rentals'], SinseiRentalItem.fromJson),
      onhoryuList: parseList(json['onhoryu_list'], SinseiHoryuRecord.fromJson),
      offhoryuList:
          parseList(json['offhoryu_list'], SinseiHoryuRecord.fromJson),
      horyuOrders: parseList(json['horyu_orders'], SinseiHoryuOrder.fromJson),
    );
  }
}

/// API 側のバリデーションエラーや 4xx/5xx を表す。Service 層で `throw` する。
class SinseiApiException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  SinseiApiException(this.message, [this.errors]);

  @override
  String toString() => 'SinseiApiException: $message';
}
