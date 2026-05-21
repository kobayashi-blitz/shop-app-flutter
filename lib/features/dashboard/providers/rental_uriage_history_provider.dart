import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/rental_uriage_month_item.dart';
import 'rental_uriage_history_service.dart';

class RentalUriageHistoryState {
  final bool isLoading;
  final String? error;

  /// 担当者の全期間累計 (pcw `totalkin_all`、税込)。`months` 切替に依存せず固定。
  final int totalkinAll;

  /// 月別履歴 (DESC 順)。長さは `months` と一致 (データなし月は 0 埋め)。
  final List<RentalUriageMonthItem> items;

  /// 現在選択中の取得月数 (UI の SegmentedButton 選択値、3/6/12)
  final int months;

  RentalUriageHistoryState({
    this.isLoading = false,
    this.error,
    this.totalkinAll = 0,
    this.items = const [],
    this.months = 3,
  });

  RentalUriageHistoryState copyWith({
    bool? isLoading,
    String? error,
    int? totalkinAll,
    List<RentalUriageMonthItem>? items,
    int? months,
  }) {
    return RentalUriageHistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalkinAll: totalkinAll ?? this.totalkinAll,
      items: items ?? this.items,
      months: months ?? this.months,
    );
  }
}

class RentalUriageHistoryNotifier
    extends StateNotifier<RentalUriageHistoryState> {
  final RentalUriageHistoryService _service;
  final Ref _ref;

  RentalUriageHistoryNotifier(this._service, this._ref)
      : super(RentalUriageHistoryState());

  Future<void> load({int months = 3}) async {
    state = state.copyWith(isLoading: true, error: null, months: months);

    try {
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
      final res = await _service.fetchMonthly(
        shopId: shopId,
        tantoId: tantoId,
        months: months,
      );

      state = state.copyWith(
        isLoading: false,
        totalkinAll: res.totalkinAll,
        items: res.months,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'レンタル売上履歴の取得に失敗しました',
      );
    }
  }
}

final rentalUriageHistoryProvider = StateNotifierProvider<
    RentalUriageHistoryNotifier, RentalUriageHistoryState>(
  (ref) {
    final apiClient = ref.watch(apiClientProvider);
    final service = RentalUriageHistoryService(apiClient);
    return RentalUriageHistoryNotifier(service, ref);
  },
);
