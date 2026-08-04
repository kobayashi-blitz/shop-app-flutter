import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/dashboard_data.dart';
import 'riyojokyo_service.dart';

final riyojokyoServiceProvider = Provider<RiyojokyoService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RiyojokyoService(apiClient);
});

/// 配送予定カードの表示対象日を翌日に切り替える時刻（端末ローカル時刻）。
///
/// pcw の配送予定 Push 送信（20:00 / `app/Console/Kernel.php`）より手前に置き、
/// 通知を受けて開いた時点で一覧が既に翌日を向いているようにする。
const _scheduledSwitchHour = 19;
const _scheduledSwitchMinute = 55;

/// 配送予定カードの表示対象日: 19:55 を境に切替。
/// 配送業務で夕方以降は翌日分に意識が向く運用に合わせる。
DateTime resolveScheduledTargetDate(DateTime now) {
  final switchAt = DateTime(
    now.year,
    now.month,
    now.day,
    _scheduledSwitchHour,
    _scheduledSwitchMinute,
  );
  return now.isBefore(switchAt) ? now : now.add(const Duration(days: 1));
}

/// 配送完了カードの表示対象日: 常に当日（time of day で変えない）
DateTime resolveCompletedTargetDate(DateTime now) {
  return DateTime(now.year, now.month, now.day);
}

class DashboardState {
  final DashboardData? data;
  final bool isLoading;
  final String? error;

  /// レンタル売上累計 (`rentalUriageTotal`) は SQL が重く、ダッシュボード並列 8 API
  /// から分離して独立 future で取得する。取得中は true、完了 (or 30 秒 timeout) で
  /// false。UI 側でカード値を「集計中..」表示するのに使う。
  final bool rentalSalesLoading;

  /// 累計取得が失敗 (timeout / DioException / result != '1' / パース不能) した場合 true。
  /// 実値 0 と取得失敗を区別するため、UI で「-」表示に分岐する。
  final bool rentalSalesFailed;

  DashboardState({
    this.data,
    this.isLoading = false,
    this.error,
    this.rentalSalesLoading = false,
    this.rentalSalesFailed = false,
  });

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? error,
    bool? rentalSalesLoading,
    bool? rentalSalesFailed,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      rentalSalesLoading: rentalSalesLoading ?? this.rentalSalesLoading,
      rentalSalesFailed: rentalSalesFailed ?? this.rentalSalesFailed,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(DashboardState());

  Future<void> loadDashboard() async {
    // ローディング開始 (累計は別 future で独立管理)
    state = state.copyWith(
      isLoading: true,
      rentalSalesLoading: true,
      rentalSalesFailed: false,
      error: null,
    );

    try {
      // ★ ログインユーザー情報を Auth から取得
      final authState = _ref.read(authProvider);
      final loginUser = authState.user;

      // shopId は既に int 型として保持されている（null の場合はエラー扱い）
      final parsedShopId = loginUser?.shopId;
      if (parsedShopId == null) {
        state = state.copyWith(
          isLoading: false,
          rentalSalesLoading: false,
          rentalSalesFailed: false,
          error: 'ログイン情報に代理店IDがありません。',
        );
        return;
      }

      // 配送カードの表示対象日を決定
      final now = DateTime.now();
      final scheduledTargetDate = resolveScheduledTargetDate(now);
      final completedTargetDate = resolveCompletedTargetDate(now);

      // 利用状況 + 配送予定（特定日分）を pcw 側 RiyojokyoApi から並列取得
      // rentalUriageTotal は SQL が重いため Future.wait から分離 (後段で独立実行)
      final tantoId = loginUser?.shopSyainId ?? 0;
      final riyo = _ref.read(riyojokyoServiceProvider);
      final results = await Future.wait<int>([
        riyo.togetuSinkiOrderCount(shopId: parsedShopId, tantoId: tantoId),
        riyo.nyuinHoryuSyohinCount(shopId: parsedShopId, tantoId: tantoId),
        riyo.keiyakutyuRiyosyaCount(shopId: parsedShopId, tantoId: tantoId),
        riyo.moreOneMonthDemoCount(shopId: parsedShopId, tantoId: tantoId),
        riyo.rentalSyohinCount(shopId: parsedShopId, tantoId: tantoId),
        riyo.haisouYoteiCountForDate(
          shopId: parsedShopId,
          tantoId: tantoId,
          targetDate: scheduledTargetDate,
        ),
        riyo.haisouKanryoCount(shopId: parsedShopId, tantoId: tantoId),
      ]);

      final dashboardData = DashboardData(
        user: UserInfo(
          shopId: parsedShopId,
          shopSyainName: loginUser?.shopSyainName ?? '',
          name: loginUser?.shopSyainName ?? '',
          officeName: loginUser?.shopName ?? '',
          shopName: loginUser?.shopName ?? '',
        ),
        delivery: DeliveryInfo(
          tomorrowScheduledCount: results[5],
          completedTodayCount: results[6],
          scheduledTargetDate: scheduledTargetDate,
          completedTargetDate: completedTargetDate,
        ),
        usage: UsageInfo(
          newOrdersThisMonthCount: results[0],
          hospitalOnHoldCount: results[1],
          contractUserCount: results[2],
          rentalSalesAmountMonth: 0, // 別 future で後段更新、ロード中は UI で「集計中..」表示
          oneMonthDemoCount: results[3],
          rentalInUseCount: results[4],
        ),
      );

      // 状態更新 (他カードはここで表示、累計のみ rentalSalesLoading=true のまま)
      state = state.copyWith(
        data: dashboardData,
        isLoading: false,
        error: null,
      );

      // 累計を独立 future で取得、完了で state 更新
      // (await しないので他カードと並列に実行される。state 更新は async コールバック内)
      // rentalSales が null なら取得失敗 → rentalSalesFailed=true で UI に「-」表示
      riyo
          .rentalUriageTotal(shopId: parsedShopId, tantoId: tantoId)
          .then((rentalSales) {
        if (!mounted) return;
        final current = state.data;
        if (current == null) return;
        state = state.copyWith(
          data: DashboardData(
            user: current.user,
            delivery: current.delivery,
            usage: UsageInfo(
              newOrdersThisMonthCount: current.usage.newOrdersThisMonthCount,
              hospitalOnHoldCount: current.usage.hospitalOnHoldCount,
              contractUserCount: current.usage.contractUserCount,
              rentalSalesAmountMonth: rentalSales ?? 0,
              oneMonthDemoCount: current.usage.oneMonthDemoCount,
              rentalInUseCount: current.usage.rentalInUseCount,
            ),
          ),
          rentalSalesLoading: false,
          rentalSalesFailed: rentalSales == null,
        );
      }).catchError((_) {
        // _fetchTotalKin 内で各種例外は null 返却済。
        // ここに来るのは想定外、念のため失敗扱いにする。
        if (!mounted) return;
        state = state.copyWith(
          rentalSalesLoading: false,
          rentalSalesFailed: true,
        );
      });
    } catch (e) {
      // ここに来ることはほぼ無いが、念のためエラー処理を残しておく
      state = state.copyWith(
        isLoading: false,
        rentalSalesLoading: false,
        rentalSalesFailed: false,
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
  return DashboardNotifier(ref);
});
