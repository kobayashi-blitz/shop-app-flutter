import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tomorrow_delivery_provider.dart';
import '../widgets/delivery_list_tile.dart';
import 'delivery_detail_screen.dart';

class TomorrowDeliveryListScreen extends ConsumerStatefulWidget {
  final DateTime targetDate; // 今は画面タイトルに表示する用

  const TomorrowDeliveryListScreen({
    super.key,
    required this.targetDate,
  });

  @override
  ConsumerState<TomorrowDeliveryListScreen> createState() =>
      _TomorrowDeliveryListScreenState();
}

class _TomorrowDeliveryListScreenState
    extends ConsumerState<TomorrowDeliveryListScreen> {
  @override
  void initState() {
    super.initState();
    // 初回ロード（widget.targetDate を Provider に渡して対象日を単一ソース化）
    Future.microtask(() {
      ref
          .read(tomorrowDeliveryProvider.notifier)
          .load(targetDate: widget.targetDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tomorrowDeliveryProvider);

    final dateText =
        '${widget.targetDate.year}/${widget.targetDate.month.toString().padLeft(2, '0')}/${widget.targetDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('配送予定（$dateText）'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(tomorrowDeliveryProvider.notifier)
              .load(targetDate: widget.targetDate);
        },
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(TomorrowDeliveryState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              '翌日配送予定はありません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return DeliveryListTile(
          key: ValueKey(item.id), // 受付ID でカード識別（合積みで同一 haisou_id が複数並ぶため）
          item: item,
          detailMode: DeliveryDetailMode.scheduled,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: state.items.length,
    );
  }
}
