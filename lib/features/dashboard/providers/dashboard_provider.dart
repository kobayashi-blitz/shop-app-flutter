import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/dashboard_data.dart';
import 'dashboard_service.dart';
import 'riyojokyo_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardService(apiClient);
});

final riyojokyoServiceProvider = Provider<RiyojokyoService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RiyojokyoService(apiClient);
});

class DashboardState {
  final DashboardData? data;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardService _dashboardService;
  final Ref _ref;

  DashboardNotifier(this._dashboardService, this._ref)
      : super(DashboardState());

  Future<void> loadDashboard() async {
    // ローディング開始
    state = state.copyWith(isLoading: true, error: null);

    try {
      // ★ ログインユーザー情報を Auth から取得
      final authState = _ref.read(authProvider);
      final loginUser = authState.user;

      // shopId は既に int 型として保持されている（null の場合はエラー扱い）
      final parsedShopId = loginUser?.shopId;
      print('### [DashboardNotifier] parsedShopId = $parsedShopId');
      if (parsedShopId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'ログイン情報に代理店IDがありません。',
        );
        return;
      }

      // 配送件数（明日／本日完了）取得
      final deliveryInfo =
          await _dashboardService.fetchDeliveryInfo(shopId: parsedShopId);

      // 利用状況を pcw 側 RiyojokyoApi から並列取得
      final tantoId = loginUser?.shopSyainId ?? 0;
      final riyo = _ref.read(riyojokyoServiceProvider);
      final results = await Future.wait<int>([
        riyo.togetuSinkiOrderCount(shopId: parsedShopId, tantoId: tantoId),
        riyo.nyuinHoryuSyohinCount(shopId: parsedShopId, tantoId: tantoId),
        riyo.keiyakutyuRiyosyaCount(shopId: parsedShopId, tantoId: tantoId),
        riyo.rentalUriageTotal(shopId: parsedShopId, tantoId: tantoId),
        riyo.moreOneMonthDemoCount(shopId: parsedShopId, tantoId: tantoId),
        riyo.rentalSyohinCount(shopId: parsedShopId, tantoId: tantoId),
      ]);

      final dashboardData = DashboardData(
        user: UserInfo(
          shopId: parsedShopId,
          shopSyainName: loginUser?.shopSyainName ?? '',
          name: loginUser?.shopSyainName ?? '',
          officeName: loginUser?.shopName ?? '',
          shopName: loginUser?.shopName ?? '',
        ),
        delivery: deliveryInfo,
        usage: UsageInfo(
          newOrdersThisMonthCount: results[0],
          hospitalOnHoldCount: results[1],
          contractUserCount: results[2],
          rentalSalesAmountMonth: results[3],
          oneMonthDemoCount: results[4],
          rentalInUseCount: results[5],
        ),
      );

      // 状態更新（ローディング終了＋データ反映）
      state = state.copyWith(
        data: dashboardData,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      // ここに来ることはほぼ無いが、念のためエラー処理を残しておく
      state = state.copyWith(
        isLoading: false,
        error: 'ダッシュボードデータの取得に失敗しました',
      );
    }
  }

  void refresh() {
    loadDashboard();
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return DashboardNotifier(dashboardService, ref);
});
