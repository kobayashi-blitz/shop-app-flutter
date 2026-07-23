import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/haisou_detail.dart';
import 'haisou_detail_service.dart';

final haisouDetailServiceProvider = Provider<HaisouDetailService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HaisouDetailService(apiClient);
});

/// 配送詳細 family のキー。**受付単位**で一意化するため、配送ID・受付ID・区分の3値を持つ。
///
/// 合積み配送では複数受付が同じ [haisouId] を共有するため、[haisouId] 単独をキーにすると
/// プロバイダが衝突し全カードが先頭受付の詳細を開いてしまう。受付ID [orderId] と区分 [kubun]
/// を含めることで受付ごとに別インスタンスになる。レコードは構造的等価なので family キーに使える。
typedef HaisouDetailKey = ({int haisouId, int orderId, String kubun});

/// 配送詳細 (1 受付単位) を取得する FutureProvider.family。
///
/// 画面側で `ref.watch(haisouDetailProvider(key))` して AsyncValue で
/// loading / error / data の 3 状態を受ける。autoDispose で画面破棄時に破棄。
final haisouDetailProvider = FutureProvider.autoDispose
    .family<HaisouDetail, HaisouDetailKey>((ref, key) async {
  final authState = ref.watch(authProvider);
  final loginUser = authState.user;
  final shopId = loginUser?.shopId;
  if (shopId == null) {
    throw Exception('ログイン情報に代理店IDがありません。');
  }
  final tantoId = loginUser?.shopSyainId ?? 0;
  final service = ref.watch(haisouDetailServiceProvider);
  return service.fetchDetail(
    shopId: shopId,
    tantoId: tantoId,
    haisouId: key.haisouId,
    orderId: key.orderId,
    kubun: key.kubun,
  );
});
