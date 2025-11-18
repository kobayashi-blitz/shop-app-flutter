import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/dashboard_data.dart';
import 'dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardService(apiClient);
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

  DashboardNotifier(this._dashboardService) : super(DashboardState());

  Future<void> loadDashboard() async {
    // ローディング開始
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 疑似的な通信待ち時間（ローディング感を出すため）
      await Future.delayed(const Duration(milliseconds: 500));

      // ★ ダッシュボードのモックデータ
      final mockData = DashboardData(
        user: UserInfo(
          name: '山田 太郎',
          officeName: '〇〇介護サービス',
        ),
        delivery: DeliveryInfo(
          tomorrowScheduledCount: 12,
          completedTodayCount: 8,
        ),
        usage: UsageInfo(
          longTermDemoCount: 5,
          hospitalOnHoldCount: 3,
          contractUserCount: 120,
          rentalInUseCount: 340,
          rentalSalesAmountMonth: 1234567,
          newOrdersThisMonthCount: 18,
        ),
      );

      // 状態更新（ローディング終了＋データ反映）
      state = state.copyWith(
        data: mockData,
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

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return DashboardNotifier(dashboardService);
});
