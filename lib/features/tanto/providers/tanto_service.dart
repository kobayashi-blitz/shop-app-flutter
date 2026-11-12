import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/tanto_models.dart';

/// 担当利用者の再登録 API (pcw `pcwMobileApi/shop/tanto/*`)。どれもトークン必須。
///
/// 店舗と「自分」は pcw がトークンから決めるので、shop_id / shop_syain_id は送らない。
class TantoService {
  TantoService(this._apiClient);

  final ApiClient _apiClient;

  /// 送れる件数の上限 (pcw `TantoSaitorokuApiController::MAX_ITEMS`)。
  static const int maxItems = 500;

  static const _base = '/api/pcwMobileApi/shop/tanto';

  Future<TantoListResult> fetchList({
    String? keyword,
    TantoJotai jotai = TantoJotai.all,
    int? syainId,
    TantoKeiyaku keiyaku = TantoKeiyaku.keiyakutyu,
    int page = 1,
  }) async {
    final body = <String, dynamic>{
      'jotai': jotai.value,
      'keiyaku': keiyaku.value,
      'page': page,
    };
    final kw = keyword?.trim() ?? '';
    if (kw.isNotEmpty) body['keyword'] = kw;
    if (syainId != null) body['syain_id'] = syainId;

    final data = await _post('$_base/list', body);
    return TantoListResult(
      items: (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => TantoRiyosyaItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: _int(data['total']),
      page: _int(data['page'], 1),
      perPage: _int(data['per_page'], 30),
      syainList: (data['syain_list'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => TantoSyain.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      jibunSyainId: _int(data['jibun_syain_id']),
    );
  }

  /// 選んだ利用者をログイン中の担当者の担当にする。
  Future<TantoSubmitResult> saitoroku(List<TantoRiyosyaItem> items) =>
      _submit('$_base/saitoroku', items);

  /// 自分が担当している利用者を担当者未設定にする。
  Future<TantoSubmitResult> misettei(List<TantoRiyosyaItem> items) =>
      _submit('$_base/misettei', items);

  Future<TantoSubmitResult> _submit(
    String path,
    List<TantoRiyosyaItem> items,
  ) async {
    final data = await _post(path, {
      'items': items.map((e) => e.toSubmitJson()).toList(),
    });
    return TantoSubmitResult(
      changed: toIntList(data['changed']),
      unchanged: toIntList(data['unchanged']),
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _apiClient.post(path, data: body);
      final data = _asMap(response.data);
      if (data['result'] != '1') {
        throw const TantoApiException(TantoErrorKind.unknown);
      }
      return data;
    } on DioException catch (e) {
      throw _convertDioError(e);
    }
  }

  TantoApiException _convertDioError(DioException e) {
    final response = e.response;
    if (response == null) {
      return const TantoApiException(TantoErrorKind.network);
    }
    final data = _asMap(response.data);
    final ids = toIntList(data['riyosya_ids']);
    final reason = data['reason']?.toString();
    switch (response.statusCode) {
      case 401:
        return const TantoApiException(TantoErrorKind.unauthenticated);
      case 409:
        return TantoApiException(TantoErrorKind.conflict, riyosyaIds: ids);
      case 422:
        return TantoApiException(
          TantoErrorKind.invalid,
          reason: reason,
          riyosyaIds: ids,
        );
      case 503:
        return const TantoApiException(TantoErrorKind.retry);
      default:
        return const TantoApiException(TantoErrorKind.unknown);
    }
  }

  int _int(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  // pcw 側 Content-Type が text/html のことがあり Dio が自動 JSON 化しない。文字列のときは手動 decode。
  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }
}
