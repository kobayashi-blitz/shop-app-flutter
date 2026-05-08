import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tomorrow_delivery_provider.dart';
import '../models/tomorrow_delivery_item.dart';
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
    // 初回ロード
    Future.microtask(() {
      ref.read(tomorrowDeliveryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tomorrowDeliveryProvider);

    final dateText =
        '${widget.targetDate.year}/${widget.targetDate.month.toString().padLeft(2, '0')}/${widget.targetDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('翌日配送予定（$dateText）'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(tomorrowDeliveryProvider.notifier).load();
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
        return _buildDeliveryTile(context, item);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: state.items.length,
    );
  }

  Widget _buildDeliveryTile(BuildContext context, TomorrowDeliveryItem item) {
    final kubunBadgeColor =
        item.type == 'sale' ? Colors.green.shade100 : Colors.blue.shade100;
    final kubunTextColor =
        item.type == 'sale' ? Colors.green.shade800 : Colors.blue.shade800;

    final timeText =
        (item.deliveryTime.isNotEmpty) ? item.deliveryTime : '時間未定';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DeliveryDetailScreen(
                item: item,
                mode: DeliveryDetailMode.scheduled,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1行目: 区分バッジ + 利用者名
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kubunBadgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.kubun,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kubunTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 2行目: 配送時間・担当
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.haisouTantoName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 3行目: 住所
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 4行目: 商品
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
