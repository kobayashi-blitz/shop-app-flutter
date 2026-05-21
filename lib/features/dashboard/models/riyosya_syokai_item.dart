/// pcw `/api/pcwMobileApi/shop/riyosya-syokai` のレスポンス行モデル。
///
/// 商品行 1 行に利用者基本情報 (m41) と契約情報 (r02/m01) を含む。
/// 同一利用者に複数契約があると行が複製されるため、画面側で `riyosyaId` で
/// groupBy して 1 利用者カード ＝ 複数行 にまとめる。
///
/// m41 の nullable カラム (birthday / gender / kaigo_rank / 等) は pcw 側で
/// `null` を返す可能性があるため、`as String` キャストではなく
/// `?.toString() ?? ''` でフォールバックする。
class RiyosyaSyokaiItem {
  /// pcw `config/const.php` の flags.NOHIN_ZUMI=30, flags.KEIYAKU_CHU=40 に対応。
  /// pcw 側が変わったらここも同時更新 (要グレップ追従)。
  static const Set<int> activeRentalFlags = {30, 40};

  final int primaryId;
  final int riyosyaId;
  // --- 利用者基本情報 (商品行間で同じ値が繰り返される) ---
  final String riyosyaName;
  final String riyosyaKana;
  final String riyosyaPref;
  final String riyosyaJyusyo1;
  final String riyosyaJyusyo2;
  final String riyosyaPost;
  final String riyosyaTel;
  final String riyosyaGender;
  final String riyosyaBirthday; // YYYY/MM/DD or ''
  final String riyosyaKaigoRank;
  final String riyosyaKaigoKikanFrom; // YYYY/MM/DD or ''
  final String riyosyaKaigoKikanTo; // YYYY/MM/DD or ''
  final String riyosyaCareMan;
  // --- 商品行情報 ---
  final String syohinName;
  final int rentalSincyokuFlag;
  final String keiyakuDateFrom; // YYYY/MM/DD or ''
  final String keiyakuDateTo; // YYYY/MM/DD or ''

  RiyosyaSyokaiItem({
    required this.primaryId,
    required this.riyosyaId,
    required this.riyosyaName,
    required this.riyosyaKana,
    required this.riyosyaPref,
    required this.riyosyaJyusyo1,
    required this.riyosyaJyusyo2,
    required this.riyosyaPost,
    required this.riyosyaTel,
    required this.riyosyaGender,
    required this.riyosyaBirthday,
    required this.riyosyaKaigoRank,
    required this.riyosyaKaigoKikanFrom,
    required this.riyosyaKaigoKikanTo,
    required this.riyosyaCareMan,
    required this.syohinName,
    required this.rentalSincyokuFlag,
    required this.keiyakuDateFrom,
    required this.keiyakuDateTo,
  });

  /// 現在契約中 (NOHIN_ZUMI / KEIYAKU_CHU) かどうか。
  /// それ以外 (HENKYAKU_* = 50/55/57) は過去契約とみなす。
  bool get isActive => activeRentalFlags.contains(rentalSincyokuFlag);

  factory RiyosyaSyokaiItem.fromJson(Map<String, dynamic> json) {
    String s(String k) => json[k]?.toString() ?? '';
    int i(String k) {
      final v = json[k];
      if (v is int) return v;
      return int.tryParse('${v ?? ''}') ?? 0;
    }

    return RiyosyaSyokaiItem(
      primaryId: i('primary_id'),
      riyosyaId: i('riyosya_id'),
      riyosyaName: s('riyosya_name'),
      riyosyaKana: s('riyosya_kana'),
      riyosyaPref: s('riyosya_pref'),
      riyosyaJyusyo1: s('riyosya_jyusyo_1'),
      riyosyaJyusyo2: s('riyosya_jyusyo_2'),
      riyosyaPost: s('riyosya_post'),
      riyosyaTel: s('riyosya_tel'),
      riyosyaGender: s('riyosya_gender'),
      riyosyaBirthday: s('riyosya_birthday'),
      riyosyaKaigoRank: s('riyosya_kaigo_rank'),
      riyosyaKaigoKikanFrom: s('riyosya_kaigo_kikan_from'),
      riyosyaKaigoKikanTo: s('riyosya_kaigo_kikan_to'),
      riyosyaCareMan: s('riyosya_care_man'),
      syohinName: s('syohin_name'),
      rentalSincyokuFlag: i('rental_sincyoku_flag'),
      keiyakuDateFrom: s('keiyaku_date_from'),
      keiyakuDateTo: s('keiyaku_date_to'),
    );
  }
}
