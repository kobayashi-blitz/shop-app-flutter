import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/sinsei_models.dart';

/// 入院保留申請 (SAP-13) の pcw API ファサード。
///
/// 対応エンドポイント:
/// - `POST /api/pcwMobileApi/shop/sinsei-nyuinhoryu/create` (フォーム初期データ取得)
/// - `POST /api/pcwMobileApi/shop/sinsei-nyuinhoryu/regist` (申請登録)
class SinseiService {
  final ApiClient _apiClient;

  SinseiService(this._apiClient);

  /// 申請フォームの初期データを取得する。
  ///
  /// [sinseiKubun] は `'1'` (新規入院保留) または `'2'` (入院保留変更)。
  /// [selectRentalHoryuId] は変更モードで対象の保留期間を選んだとき指定する。
  Future<SinseiCreateData> fetchCreate({
    required int shopId,
    required int riyosyaId,
    String sinseiKubun = '1',
    int? selectRentalHoryuId,
  }) async {
    try {
      final res = await _apiClient.post(
        '/api/pcwMobileApi/shop/sinsei-nyuinhoryu/create',
        data: {
          'shop_id': shopId,
          'riyosya_id': riyosyaId,
          'sinsei_kubun': sinseiKubun,
          if (selectRentalHoryuId != null)
            'select_rental_horyu_id': selectRentalHoryuId,
        },
      );
      final data = _asMap(res.data);
      if (data['result'] != '1') {
        throw SinseiApiException(
          (data['message'] ?? '入院保留申請画面の取得に失敗しました') as String,
        );
      }
      return SinseiCreateData.fromJson(data);
    } on DioException catch (e) {
      throw _convertDioError(e, '入院保留申請画面の取得に失敗しました');
    }
  }

  /// 入院保留申請を登録する。成功時は `sinsei_syonin_id` を返す。
  Future<int> regist({
    required int shopId,
    required int riyosyaId,
    required String sinseiKubun,
    required String sinseiFromDate, // 'Y/m/d'
    String? sinseiToDate, // 'Y/m/d' or null
    String? sinseiRiyu,
    required List<int> horyucheck, // チェック済 rental_id 配列
    required List<int> rentalid, // 画面に出した全 rental_id（順序固定）
    required List<String> tankaflag, // rentalid と同順
    List<int?>? rentalHoryuSyohinId, // sinsei_kubun=2 のみ
    List<String?>? oldHoryuDateFrom, // sinsei_kubun=2 のみ ('Y-m-d')
    List<String?>? oldHoryuDateTo, // sinsei_kubun=2 のみ
    int? shopSyainId, // ログイン中の代理店社員ID（pcw 側でメール本文の申請者名に使用。任意）
  }) async {
    final body = <String, dynamic>{
      'shop_id': shopId,
      'riyosya_id': riyosyaId,
      'sinsei_kubun': sinseiKubun,
      if (shopSyainId != null) 'shop_syain_id': shopSyainId,
      'sinsei_from_date': sinseiFromDate,
      if (sinseiToDate != null && sinseiToDate.isNotEmpty)
        'sinsei_to_date': sinseiToDate,
      if (sinseiRiyu != null) 'sinsei_riyu': sinseiRiyu,
      'horyucheck': horyucheck,
      'rentalid': rentalid,
      'tankaflag': tankaflag,
      if (rentalHoryuSyohinId != null)
        'rental_horyu_syohin_id': rentalHoryuSyohinId,
      if (oldHoryuDateFrom != null) 'old_horyu_date_from': oldHoryuDateFrom,
      if (oldHoryuDateTo != null) 'old_horyu_date_to': oldHoryuDateTo,
    };

    try {
      final res = await _apiClient.post(
        '/api/pcwMobileApi/shop/sinsei-nyuinhoryu/regist',
        data: body,
      );
      final data = _asMap(res.data);
      if (data['result'] != '1') {
        throw SinseiApiException(
          (data['message'] ?? '申請の登録に失敗しました') as String,
          _parseErrors(data['errors']),
        );
      }
      return (data['sinsei_syonin_id'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw _convertDioError(e, '申請の登録に失敗しました');
    }
  }

  /// Dio が text/html を返した場合の防御コード。
  /// pcw 修正後は application/json で返ってくるはずだが、互換性のため保持。
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

  /// DioException のうち 4xx/5xx を SinseiApiException に詰め直す。
  SinseiApiException _convertDioError(DioException e, String fallback) {
    final response = e.response;
    if (response != null) {
      final data = _asMap(response.data);
      final msg = (data['message'] ?? fallback) as String;
      return SinseiApiException(msg, _parseErrors(data['errors']));
    }
    // ネットワークエラー等
    return SinseiApiException(fallback);
  }

  Map<String, List<String>>? _parseErrors(dynamic raw) {
    if (raw is! Map) return null;
    final out = <String, List<String>>{};
    raw.forEach((k, v) {
      if (k is String && v is List) {
        out[k] = v.map((e) => e.toString()).toList();
      }
    });
    return out.isEmpty ? null : out;
  }
}
