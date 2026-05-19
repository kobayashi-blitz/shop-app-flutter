import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/env/app_env.dart';
import '../providers/dashboard_provider.dart';
import 'placeholder_screen.dart';
import 'tomorrow_delivery_list_screen.dart';
import 'today_delivery_completed_list_screen.dart';
import 'monthly_order_list_screen.dart';
import 'nyuin_horyu_list_screen.dart';
import 'rental_syohin_list_screen.dart';
import 'keiyakutyu_riyosya_list_screen.dart';
import 'tyoki_demo_list_screen.dart';
import '../../user/screens/user_detail_screen.dart';
import '../../voucher/screens/voucher_hub_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '¥${formatter.format(amount)}';
  }

  /// 「5/14」のような短い日付表記を作る（カードタイトル用）
  String _formatMonthDay(DateTime d) => '${d.month}/${d.day}';

  void _navigateToPlaceholder(String title) {
    if (title == '配送完了（本日）') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TodayDeliveryCompletedListScreen(),
        ),
      );
      return;
    }

    if (title == 'お客様詳細（仮）') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const UserDetailScreen(),
        ),
      );
      return;
    }

    if (title == '伝票照会') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const VoucherHubScreen(),
        ),
      );
      return;
    }

    if (title == '当月新規受注') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MonthlyOrderListScreen(),
        ),
      );
      return;
    }

    if (title == '入院保留') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const NyuinHoryuListScreen(),
        ),
      );
      return;
    }

    if (title == 'レンタル中商品') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const RentalSyohinListScreen(),
        ),
      );
      return;
    }

    if (title == '契約利用者') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const KeiyakutyuRiyosyaListScreen(),
        ),
      );
      return;
    }

    if (title == '長期デモ商品') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TyokiDemoListScreen(),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceholderScreen(title: title),
      ),
    );
  }

  void _showProfileDialog(dynamic data) {
    if (data == null || data.user == null) {
      return;
    }

    final shopName = data.user.shopName ?? '';
    final staffName = data.user.shopSyainName ?? '';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'ログインユーザー',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shopName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    shopName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (staffName.isNotEmpty)
                Text(
                  '$staffName 様',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const _EnvBadge(),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: dashboardState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: dashboardState.isLoading
                  ? null
                  : () => ref.read(dashboardProvider.notifier).refresh(),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await ref.read(authProvider.notifier).logout();
                if (mounted) {
                  navigator.pushReplacementNamed('/login');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                _showProfileDialog(dashboardState.data);
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: '商品管理'),
              Tab(text: '利用状況'),
            ],
          ),
        ),
        body: _buildBody(dashboardState),
      ),
    );
  }

  Widget _buildBody(dynamic dashboardState) {
    if (dashboardState.data == null && dashboardState.error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboardState.error != null && dashboardState.data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              dashboardState.error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(dashboardProvider.notifier).refresh();
              },
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    final data = dashboardState.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TabBarView(
            children: [
              _buildDeliveryTab(data),
              _buildUsageTab(data),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTab(dynamic data) {
    final scheduledLabel = _formatMonthDay(data.delivery.scheduledTargetDate);
    final completedLabel = _formatMonthDay(data.delivery.completedTargetDate);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildMetricCard(
          title: '配送予定（$scheduledLabel日分）',
          value: '${data.delivery.tomorrowScheduledCount ?? 0}',
          unit: '件',
          icon: Icons.local_shipping,
          color: Colors.orange,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TomorrowDeliveryListScreen(
                targetDate: data.delivery.scheduledTargetDate,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          title: '配送完了（$completedLabel日分）',
          value: '${data.delivery.completedTodayCount ?? 0}',
          unit: '件',
          icon: Icons.check_circle,
          color: Colors.green,
          onTap: () => _navigateToPlaceholder('配送完了（本日）'),
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          title: '長期デモ商品件数',
          value: '${data.usage.oneMonthDemoCount ?? 0}',
          unit: '件',
          icon: Icons.inventory,
          color: Colors.purple,
          onTap: () => _navigateToPlaceholder('長期デモ商品'),
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          title: 'レンタル中商品数',
          value: '${data.usage.rentalInUseCount ?? 0}',
          unit: '個',
          icon: Icons.shopping_cart,
          color: Colors.teal,
          onTap: () => _navigateToPlaceholder('レンタル中商品'),
        ),
        const SizedBox(height: 8),
        _buildTextActionRow(
          title: '伝票照会',
          icon: Icons.receipt_long,
          color: Colors.brown,
          onTap: () => _navigateToPlaceholder('伝票照会'),
        ),
      ],
    );
  }

  Widget _buildUsageTab(dynamic data) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildMetricCard(
          title: '当月新規受注件数',
          value: '${data.usage.newOrdersThisMonthCount ?? 0}',
          unit: '件',
          icon: Icons.add_shopping_cart,
          color: Colors.indigo,
          onTap: () => _navigateToPlaceholder('当月新規受注'),
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          title: '入院保留件数',
          value: '${data.usage.hospitalOnHoldCount ?? 0}',
          unit: '件',
          icon: Icons.pause_circle,
          color: Colors.amber,
          onTap: () => _navigateToPlaceholder('入院保留'),
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          title: '契約利用者 / 入院保留申請',
          value: '${data.usage.contractUserCount ?? 0}',
          unit: '人',
          icon: Icons.people,
          color: Colors.blue,
          onTap: () => _navigateToPlaceholder('契約利用者'),
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          title: 'レンタル売上（累計）',
          value: _formatCurrency(
            data.usage.rentalSalesAmountMonth ?? 0,
          ),
          unit: '',
          icon: Icons.currency_yen,
          color: Colors.green,
          onTap: null,
        ),
        const SizedBox(height: 8),
        _buildTextActionRow(
          title: 'お客様詳細（仮）',
          icon: Icons.person_outline,
          color: Colors.indigo,
          onTap: () => _navigateToPlaceholder('お客様詳細（仮）'),
        ),
      ],
    );
  }

  Widget _buildTextActionRow({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
// 左側のカラー帯
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
// アイコン
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 12),
// タイトルのみ
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
// 左側のカラー帯
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
// アイコン
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 12),
// タイトル＋値
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 2),
                          child: Text(
                            unit,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}

/// AppBar に表示する接続先（Local / Test / Prod / Custom）バッジ。
class _EnvBadge extends StatelessWidget {
  const _EnvBadge();

  @override
  Widget build(BuildContext context) {
    final env = detectAppEnv();
    final color = switch (env) {
      AppEnv.local => Colors.grey.shade600,
      AppEnv.test => Colors.orange.shade700,
      AppEnv.prod => Colors.red.shade700,
      AppEnv.custom => Colors.purple,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          env.label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
