import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/denpyo_search_item.dart';
import '../models/seikyu_month.dart';

class DenpyoSearchResult {
  final int total;
  final int page;
  final int perPage;
  final List<DenpyoSearchItem> items;
  const DenpyoSearchResult({
    required this.total,
    required this.page,
    required this.perPage,
    required this.items,
  });
}

class VoucherService {
  final ApiClient _apiClient;
  VoucherService(this._apiClient);

  /// 請求書発行：選択可能な請求月一覧
  Future<List<SeikyuMonth>> availableMonths({required int shopId}) async {
    try {
      final res = await _apiClient.post(
        '/api/pcwMobileApi/shop/seikyusyo/months',
        data: {'shop_id': shopId},
      );
      final data = _asMap(res.data);
      if (data['result'] != '1') return [];
      final list = (data['months'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => SeikyuMonth.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// お客様控え伝票検索
  Future<DenpyoSearchResult> searchDenpyo({
    required int shopId,
    required List<String> denpyoSyurui,
    String? hakkoubi, // YYYY-MM-DD or YYYY-MM
    int page = 1,
    int perPage = 20,
  }) async {
    final body = <String, dynamic>{
      'shop_id': shopId,
      'search_denpyo_syurui': denpyoSyurui,
      'page': page,
      'per_page': perPage,
    };
    if (hakkoubi != null && hakkoubi.isNotEmpty) {
      body['search_hakkoubi'] = hakkoubi;
    }
    final res = await _apiClient.post(
      '/api/pcwMobileApi/shop/denpyo/search',
      data: body,
    );
    final data = _asMap(res.data);
    if (data['result'] != '1') {
      throw Exception('伝票検索に失敗しました');
    }
    final items = ((data['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => DenpyoSearchItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return DenpyoSearchResult(
      total: int.tryParse('${data['total']}') ?? items.length,
      page: int.tryParse('${data['page']}') ?? page,
      perPage: int.tryParse('${data['per_page']}') ?? perPage,
      items: items,
    );
  }

  // pcw 側 Content-Type が text/html のことがあるため文字列なら手動 decode。
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
