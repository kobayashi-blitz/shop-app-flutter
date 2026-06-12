import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/rental_uriage_month_item.dart';
import 'rental_uriage_history_service.dart';

class RentalUriageHistoryState {
  final bool isLoading;
  final String? error;

  /// 担当者の全期間累計 (pcw `totalkin_all`、税込)。
  final int totalkinAll;

  /// 累計の対象期間 (YYYY/MM 形式、データなしなら空文字)。
  final String periodFrom;
  final String periodTo;

  /// 月別履歴 (DESC 順、当月を除く過去 12 ヶ月固定。データなし月は 0 埋め)。
  /// 当月は月次確定処理 (pcw `m05getuzimenu`) 前は 0 円固定のため表示しない。
  final List<RentalUriageMonthItem> items;

  RentalUriageHistoryState({
    this.isLoading = false,
    this.error,
    this.totalkinAll = 0,
    this.periodFrom = '',
    this.periodTo = '',
    this.items = const [],
  });

  RentalUriageHistoryState copyWith({
    bool? isLoading,
    String? error,
    int? totalkinAll,
    String? periodFrom,
    String? periodTo,
    List<RentalUriageMonthItem>? items,
  }) {
    return RentalUriageHistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalkinAll: totalkinAll ?? this.totalkinAll,
      periodFrom: periodFrom ?? this.periodFrom,
      periodTo: periodTo ?? this.periodTo,
      items: items ?? this.items,
    );
  }
}

class RentalUriageHistoryNotifier
    extends StateNotifier<RentalUriageHistoryState> {
  final RentalUriageHistoryService _service;
  final Ref _ref;

  RentalUriageHistoryNotifier(this._service, this._ref)
      : super(RentalUriageHistoryState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

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
      );

      state = state.copyWith(
        isLoading: false,
        totalkinAll: res.totalkinAll,
        periodFrom: res.periodFrom,
        periodTo: res.periodTo,
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
