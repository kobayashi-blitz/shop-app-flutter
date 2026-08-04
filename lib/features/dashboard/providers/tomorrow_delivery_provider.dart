import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/tomorrow_delivery_item.dart';
import '../providers/tomorrow_delivery_service.dart';

class TomorrowDeliveryState {
  final bool isLoading;
  final String? error;
  final List<TomorrowDeliveryItem> items;

  TomorrowDeliveryState({
    this.isLoading = false,
    this.error,
    this.items = const [],
  });

  TomorrowDeliveryState copyWith({
    bool? isLoading,
    String? error,
    List<TomorrowDeliveryItem>? items,
  }) {
    return TomorrowDeliveryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
    );
  }
}

class TomorrowDeliveryNotifier extends StateNotifier<TomorrowDeliveryState> {
  final TomorrowDeliveryService _service;
  final Ref _ref;

  TomorrowDeliveryNotifier(this._service, this._ref)
      : super(TomorrowDeliveryState());

  /// [targetDate] は呼出元 (画面) で確定済みの対象日。19:55 切替ロジックの単一ソース化のため、
  /// 内部で `DateTime.now()` を見ない（境界跨ぎで画面タイトルと API フィルタがズレないように）。
  Future<void> load({required DateTime targetDate}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // ログイン情報から shopId / tantoId(shopSyainId) を取得
      final authState = _ref.read(authProvider);
      final loginUser = authState.user;
      final shopId = loginUser?.shopId;

      if (shopId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'ログイン情報に代理店IDがありません。',
        );
        return;
      }

      final tantoId = loginUser?.shopSyainId ?? 0;

      final items = await _service.fetchTomorrowList(
        shopId: shopId,
        tantoId: tantoId,
        targetDate: targetDate,
      );

      state = state.copyWith(
        isLoading: false,
        items: items,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : '配送予定の取得に失敗しました',
      );
    }
  }
}

final tomorrowDeliveryProvider =
    StateNotifierProvider<TomorrowDeliveryNotifier, TomorrowDeliveryState>(
  (ref) {
    final apiClient = ref.watch(apiClientProvider);
    final service = TomorrowDeliveryService(apiClient);
    return TomorrowDeliveryNotifier(service, ref);
  },
);
