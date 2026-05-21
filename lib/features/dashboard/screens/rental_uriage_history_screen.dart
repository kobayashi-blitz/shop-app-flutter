import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/rental_uriage_history_provider.dart';

/// 担当者単位のレンタル売上 月別履歴画面。
///
/// ダッシュボード「レンタル売上（累計）」カードのタップで遷移。
/// pcw `rental-uriage/monthly` API から **過去 12 ヶ月** の月別合計と累計
/// (`totalkin_all` + `period_from` / `period_to`) を取得する。
class RentalUriageHistoryScreen extends ConsumerStatefulWidget {
  const RentalUriageHistoryScreen({super.key});

  @override
  ConsumerState<RentalUriageHistoryScreen> createState() =>
      _RentalUriageHistoryScreenState();
}

class _RentalUriageHistoryScreenState
    extends ConsumerState<RentalUriageHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(rentalUriageHistoryProvider.notifier).load();
    });
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '¥${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalUriageHistoryProvider);
    final authState = ref.watch(authProvider);
    final tantoName = authState.user?.shopSyainName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('レンタル売上履歴'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(rentalUriageHistoryProvider.notifier).load(),
        child: _buildBody(state, tantoName),
      ),
    );
  }

  Widget _buildBody(RentalUriageHistoryState state, String tantoName) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('集計中..', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Center(
            child: Text(
              state.error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    final hasAnyData = state.items.any((m) => m.rentalKin > 0);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(
          tantoName,
          state.totalkinAll,
          state.periodFrom,
          state.periodTo,
        ),
        const SizedBox(height: 12),
        if (!hasAnyData)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                '売上履歴がありません',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          )
        else
          ...state.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMonthTile(item.ym, item.rentalKin, item.count),
              )),
      ],
    );
  }

  Widget _buildHeader(
    String tantoName,
    int totalkinAll,
    String periodFrom,
    String periodTo,
  ) {
    final periodText = (periodFrom.isNotEmpty && periodTo.isNotEmpty)
        ? '$periodFrom 〜 $periodTo'
        : '';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tantoName.isNotEmpty)
              Text(
                '$tantoName 様',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            const SizedBox(height: 4),
            Text(
              '累計 ${_formatCurrency(totalkinAll)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            if (periodText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '対象期間: $periodText',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthTile(String ym, int rentalKin, int count) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              ym,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(rentalKin),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count 件',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
