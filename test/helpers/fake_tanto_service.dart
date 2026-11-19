import 'dart:async';

import 'package:shop_app_flutter/core/api/api_client.dart';
import 'package:shop_app_flutter/features/tanto/models/tanto_models.dart';
import 'package:shop_app_flutter/features/tanto/providers/tanto_service.dart';

/// 一覧の 1 行を作る。
TantoRiyosyaItem tantoItem(
  int id, {
  String? name,
  int? shopSyainId,
  int? rirekiId,
  int? tantoSyainId,
  String? tantoName,
}) {
  return TantoRiyosyaItem(
    riyosyaId: id,
    riyosyaName: name ?? '利用者$id',
    riyosyaKana: null,
    jyusyo1: null,
    jyusyo2: null,
    shopSyainId: shopSyainId,
    rirekiId: rirekiId,
    tantoSyainId: tantoSyainId,
    tantoName: tantoName,
    keiyakutyuCount: 1,
    kakoCount: 0,
  );
}

/// 画面テスト用の TantoService。[rows] を 30 件ずつ返し、送信内容を記録する。
class FakeTantoService extends TantoService {
  FakeTantoService(this.rows, {this.jibunSyainId = 7}) : super(ApiClient());

  List<TantoRiyosyaItem> rows;
  final int jibunSyainId;
  static const perPage = 30;

  final List<({TantoJotai jotai, int page})> listCalls = [];
  final List<List<Map<String, dynamic>>> saitorokuCalls = [];
  final List<List<Map<String, dynamic>>> misetteiCalls = [];

  /// 次の送信で投げる例外。
  TantoApiException? nextSubmitError;

  /// 送信の応答を止めておく (送信中の表示を確かめる)。
  Completer<void>? submitGate;

  @override
  Future<TantoListResult> fetchList({
    String? keyword,
    TantoJotai jotai = TantoJotai.all,
    int? syainId,
    TantoKeiyaku keiyaku = TantoKeiyaku.keiyakutyu,
    int page = 1,
  }) async {
    listCalls.add((jotai: jotai, page: page));
    final start = (page - 1) * perPage;
    final items = start >= rows.length
        ? <TantoRiyosyaItem>[]
        : rows.sublist(start, (start + perPage).clamp(0, rows.length));
    return TantoListResult(
      items: items,
      total: rows.length,
      page: page,
      perPage: perPage,
      syainList: [TantoSyain(shopSyainId: jibunSyainId, name: '担当 自分')],
      jibunSyainId: jibunSyainId,
    );
  }

  @override
  Future<TantoSubmitResult> saitoroku(List<TantoRiyosyaItem> items) async {
    saitorokuCalls.add(items.map((e) => e.toSubmitJson()).toList());
    return _submit(items);
  }

  @override
  Future<TantoSubmitResult> misettei(List<TantoRiyosyaItem> items) async {
    misetteiCalls.add(items.map((e) => e.toSubmitJson()).toList());
    return _submit(items);
  }

  Future<TantoSubmitResult> _submit(List<TantoRiyosyaItem> items) async {
    if (submitGate != null) await submitGate!.future;
    final error = nextSubmitError;
    if (error != null) {
      nextSubmitError = null;
      throw error;
    }
    return TantoSubmitResult(
      changed: items.map((e) => e.riyosyaId).toList(),
      unchanged: const [],
    );
  }
}
