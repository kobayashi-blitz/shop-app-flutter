/// 契約中利用者詳細 API のレスポンス行モデル (商品行単位)。
///
/// pcw `keiyakutyu-riyosya/syosai` は利用者×商品の組合せで複数行返す。
/// 画面側で `riyosya_id` で groupBy して 1 利用者カードにまとめる。
///
/// 検索用に m41 の `kana / pref / jyusyo_1 / jyusyo_2` も含む。
/// nullable 列は `?.toString() ?? ''` でフォールバック。
class KeiyakutyuRiyosyaItem {
  final int primaryId;
  final int riyosyaId;
  final String riyosyaName;
  final String riyosyaKana;
  final String riyosyaPref;
  final String riyosyaJyusyo1;
  final String riyosyaJyusyo2;
  final String syohinName;
  final String keiyakuDateFrom;

  KeiyakutyuRiyosyaItem({
    required this.primaryId,
    required this.riyosyaId,
    required this.riyosyaName,
    required this.riyosyaKana,
    required this.riyosyaPref,
    required this.riyosyaJyusyo1,
    required this.riyosyaJyusyo2,
    required this.syohinName,
    required this.keiyakuDateFrom,
  });

  factory KeiyakutyuRiyosyaItem.fromJson(Map<String, dynamic> json) {
    String s(String k) => json[k]?.toString() ?? '';
    int i(String k) {
      final v = json[k];
      if (v is int) return v;
      return int.tryParse('${v ?? ''}') ?? 0;
    }

    return KeiyakutyuRiyosyaItem(
      primaryId: i('primary_id'),
      riyosyaId: i('riyosya_id'),
      riyosyaName: s('riyosya_name'),
      riyosyaKana: s('riyosya_kana'),
      riyosyaPref: s('riyosya_pref'),
      riyosyaJyusyo1: s('riyosya_jyusyo_1'),
      riyosyaJyusyo2: s('riyosya_jyusyo_2'),
      syohinName: s('syohin_name'),
      keiyakuDateFrom: s('keiyaku_date_from'),
    );
  }
}
