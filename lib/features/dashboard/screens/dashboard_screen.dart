import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'placeholder_screen.dart';

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

  void _navigateToPlaceholder(String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceholderScreen(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardProvider.notifier).refresh();
            },
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
        ],
      ),
      body: dashboardState.isLoading && dashboardState.data == null
          ? const Center(child: CircularProgressIndicator())
          : dashboardState.error != null && dashboardState.data == null
              ? Center(
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
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.read(dashboardProvider.notifier).refresh();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blue,
                                  child: Icon(Icons.person, size: 32, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dashboardState.data?.user.officeName ?? 
                                        authState.user?.officeName ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${dashboardState.data?.user.name ?? authState.user?.name ?? ''} さん',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '配送状況',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          title: '翌日配送予定',
                          value: '${dashboardState.data?.delivery.tomorrowScheduledCount ?? 0}',
                          unit: '件',
                          icon: Icons.local_shipping,
                          color: Colors.orange,
                          onTap: () => _navigateToPlaceholder('翌日配送予定'),
                        ),
                        const SizedBox(height: 8),
                        _buildMetricCard(
                          title: '配送完了（本日）',
                          value: '${dashboardState.data?.delivery.completedTodayCount ?? 0}',
                          unit: '件',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          onTap: () => _navigateToPlaceholder('配送完了'),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '利用状況',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          title: '長期デモ商品件数',
                          value: '${dashboardState.data?.usage.longTermDemoCount ?? 0}',
                          unit: '件',
                          icon: Icons.inventory,
                          color: Colors.purple,
                          onTap: () => _navigateToPlaceholder('長期デモ商品'),
                        ),
                        const SizedBox(height: 8),
                        _buildMetricCard(
                          title: '入院保留件数',
                          value: '${dashboardState.data?.usage.hospitalOnHoldCount ?? 0}',
                          unit: '件',
                          icon: Icons.pause_circle,
                          color: Colors.amber,
                          onTap: () => _navigateToPlaceholder('入院保留'),
                        ),
                        const SizedBox(height: 8),
                        _buildMetricCard(
                          title: '契約利用者数',
                          value: '${dashboardState.data?.usage.contractUserCount ?? 0}',
                          unit: '人',
                          icon: Icons.people,
                          color: Colors.blue,
                          onTap: () => _navigateToPlaceholder('契約利用者'),
                        ),
                        const SizedBox(height: 8),
                        _buildMetricCard(
                          title: 'レンタル中商品数',
                          value: '${dashboardState.data?.usage.rentalInUseCount ?? 0}',
                          unit: '個',
                          icon: Icons.shopping_cart,
                          color: Colors.teal,
                          onTap: () => _navigateToPlaceholder('レンタル中商品'),
                        ),
                        const SizedBox(height: 8),
                        _buildMetricCard(
                          title: 'レンタル売上（当月）',
                          value: _formatCurrency(
                            dashboardState.data?.usage.rentalSalesAmountMonth ?? 0,
                          ),
                          unit: '',
                          icon: Icons.attach_money,
                          color: Colors.green,
                          onTap: null,
                        ),
                        const SizedBox(height: 8),
                        _buildMetricCard(
                          title: '当月新規受注件数',
                          value: '${dashboardState.data?.usage.newOrdersThisMonthCount ?? 0}',
                          unit: '件',
                          icon: Icons.add_shopping_cart,
                          color: Colors.indigo,
                          onTap: () => _navigateToPlaceholder('当月新規受注'),
                        ),
                      ],
                    ),
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (unit.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 2),
                            child: Text(
                              unit,
                              style: const TextStyle(
                                fontSize: 16,
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
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
