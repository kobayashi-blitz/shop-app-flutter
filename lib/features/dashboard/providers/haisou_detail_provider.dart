import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/haisou_detail.dart';
import 'haisou_detail_service.dart';

final haisouDetailServiceProvider = Provider<HaisouDetailService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HaisouDetailService(apiClient);
});

/// 配送詳細 (1 配送 = haisou_id 単位) を取得する FutureProvider.family。
///
/// 画面側で `ref.watch(haisouDetailProvider(haisouId))` して AsyncValue で
/// loading / error / data の 3 状態を受ける。autoDispose で画面破棄時に破棄。
final haisouDetailProvider =
    FutureProvider.autoDispose.family<HaisouDetail, int>((ref, haisouId) async {
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
    haisouId: haisouId,
  );
});
