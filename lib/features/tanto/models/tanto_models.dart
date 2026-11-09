/// 担当利用者の再登録 (pcw `TantoSaitorokuApiController`) のモデル。
///
/// キー名・型・null の扱いは pcw `TantoSaitorokuService::list` の応答に合わせる。
library;

/// 担当状態の絞り込み (`jotai`)。
enum TantoJotai {
  all('all', 'すべて'),
  jibun('jibun', '自分'),
  tanin('tanin', 'ほかの担当者'),
  misettei('misettei', '担当者未設定');

  const TantoJotai(this.value, this.label);
  final String value;
  final String label;
}

/// 契約の絞り込み (`keiyaku`)。pcw の初期値は keiyakutyu。
enum TantoKeiyaku {
  keiyakutyu('keiyakutyu', '契約中のみ'),
  all('all', '過去の契約も含む');

  const TantoKeiyaku(this.value, this.label);
  final String value;
  final String label;
}

/// 一覧の 1 行 (利用者)。
class TantoRiyosyaItem {
  const TantoRiyosyaItem({
    required this.riyosyaId,
    required this.riyosyaName,
    required this.riyosyaKana,
    required this.jyusyo1,
    required this.jyusyo2,
    required this.shopSyainId,
    required this.rirekiId,
    required this.tantoSyainId,
    required this.tantoName,
    required this.keiyakutyuCount,
    required this.kakoCount,
  });

  final int riyosyaId;
  final String? riyosyaName;
  final String? riyosyaKana;
  final String? jyusyo1;
  final String? jyusyo2;

  /// m41 の生の担当者 ID。退職者・他店の ID のこともある。競合検知用にそのまま送り返す。
  final int? shopSyainId;

  /// 現在の担当履歴 ID。競合検知用にそのまま送り返す。
  final int? rirekiId;

  /// 有効な担当者 (在籍中・同じ店舗) の ID。いなければ null (担当者未設定)。
  final int? tantoSyainId;
  final String? tantoName;
  final int keiyakutyuCount;
  final int kakoCount;

  factory TantoRiyosyaItem.fromJson(Map<String, dynamic> json) {
    return TantoRiyosyaItem(
      riyosyaId: _toInt(json['riyosya_id']) ?? 0,
      riyosyaName: json['riyosya_name']?.toString(),
      riyosyaKana: json['riyosya_kana']?.toString(),
      jyusyo1: json['riyosya_jyusyo_1']?.toString(),
      jyusyo2: json['riyosya_jyusyo_2']?.toString(),
      shopSyainId: _toInt(json['shop_syain_id']),
      rirekiId: _toInt(json['rireki_id']),
      tantoSyainId: _toInt(json['tanto_syain_id']),
      tantoName: json['tanto_name']?.toString(),
      keiyakutyuCount: _toInt(json['keiyakutyu_count']) ?? 0,
      kakoCount: _toInt(json['kako_count']) ?? 0,
    );
  }

  /// saitoroku / misettei に送る形。null もキーごと送る (pcw はキーの欠落を 422 にする)。
  Map<String, dynamic> toSubmitJson() => {
        'riyosya_id': riyosyaId,
        'shop_syain_id': shopSyainId,
        'rireki_id': rirekiId,
      };

  bool get isMisettei => tantoSyainId == null;

  /// 担当者名の表示。未設定の判定は名前ではなく有効な担当者 ID で行う。
  String get tantoLabel {
    if (tantoSyainId == null) return '担当者未設定';
    final name = tantoName?.trim() ?? '';
    return name.isEmpty ? '（担当者名なし）' : name;
  }

  String get jyusyo => [jyusyo1, jyusyo2]
      .where((s) => s != null && s.trim().isNotEmpty)
      .join(' ');
}

class TantoSyain {
  const TantoSyain({required this.shopSyainId, required this.name});

  final int shopSyainId;
  final String name;

  factory TantoSyain.fromJson(Map<String, dynamic> json) {
    return TantoSyain(
      shopSyainId: _toInt(json['shop_syain_id']) ?? 0,
      name: json['shop_syain_name']?.toString() ?? '',
    );
  }
}

class TantoListResult {
  const TantoListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.syainList,
    required this.jibunSyainId,
  });

  final List<TantoRiyosyaItem> items;
  final int total;
  final int page;
  final int perPage;
  final List<TantoSyain> syainList;

  /// ログイン中の担当者 (トークンの担当者)。
  final int jibunSyainId;

  int get totalPages => total <= 0 ? 1 : (total + perPage - 1) ~/ perPage;
}

class TantoSubmitResult {
  const TantoSubmitResult({required this.changed, required this.unchanged});

  final List<int> changed;
  final List<int> unchanged;
}

enum TantoErrorKind {
  /// 409: ほかの所で担当者が変わった。
  conflict,

  /// 422: 入力や指定が正しくない。
  invalid,

  /// 503: ほかの処理と重なった。送り直せば通ることがある。
  retry,

  /// 401: トークンが無いか無効。ログアウトは ApiClient の通知で行う。
  unauthenticated,

  /// 通信できなかった。
  network,
  unknown,
}

class TantoApiException implements Exception {
  const TantoApiException(this.kind, {this.reason, this.riyosyaIds = const []});

  final TantoErrorKind kind;

  /// 422 の理由 (owner / riyosya / syain など)。
  final String? reason;
  final List<int> riyosyaIds;

  /// 画面に出す文言。サーバの生のメッセージは出さない。
  String get message {
    switch (kind) {
      case TantoErrorKind.conflict:
        return 'ほかの所で担当者が変わった利用者がいます。一覧を更新しました。';
      case TantoErrorKind.invalid:
        if (reason == 'owner') {
          return 'ほかの担当者に変わった利用者が含まれています。一覧を更新しました。';
        }
        return '登録できない利用者が含まれています。一覧を更新しました。';
      case TantoErrorKind.retry:
        return '混み合っています。もう一度お試しください。';
      case TantoErrorKind.unauthenticated:
        return 'ログインの有効期限が切れました。';
      case TantoErrorKind.network:
        return '通信できませんでした。電波の良い所でもう一度お試しください。';
      case TantoErrorKind.unknown:
        return '処理に失敗しました。もう一度お試しください。';
    }
  }

  @override
  String toString() => 'TantoApiException($kind, $reason)';
}

int? _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// pcw の `riyosya_ids` などを int の一覧にする。
List<int> toIntList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map(_toInt).whereType<int>().toList();
}
