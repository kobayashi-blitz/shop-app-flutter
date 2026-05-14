import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/tomorrow_delivery_item.dart';
import '../providers/tomorrow_delivery_service.dart';
import 'delivery_detail_screen.dart';

class TodayDeliveryCompletedListScreen extends ConsumerStatefulWidget {
  const TodayDeliveryCompletedListScreen({super.key});

  @override
  ConsumerState<TodayDeliveryCompletedListScreen> createState() =>
      _TodayDeliveryCompletedListScreenState();
}

class _TodayDeliveryCompletedListScreenState
    extends ConsumerState<TodayDeliveryCompletedListScreen> {
  bool _isLoading = true;
  String? _error;
  List<TomorrowDeliveryItem> _items = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      // ログインユーザーから shop_id / tantoId(shopSyainId) / shopSyainName を取得
      final authState = ref.read(authProvider);
      final loginUser = authState.user;
      final shopId = loginUser?.shopId;

      if (shopId == null) {
        setState(() {
          _isLoading = false;
          _error = '代理店IDが取得できませんでした。';
        });
        return;
      }

      final tantoId = loginUser?.shopSyainId ?? 0;
      final fallbackName = loginUser?.shopSyainName ?? '';

      final apiClient = ref.read(apiClientProvider);
      final service = TomorrowDeliveryService(apiClient);

      final list = await service.fetchTodayCompletedList(
        shopId: shopId,
        tantoId: tantoId,
        haisouTantoNameFallback: fallbackName,
      );

      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : '本日配送完了の取得に失敗しました';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配送完了（本日）'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('本日の配送完了はありません。'),
      );
    }

    // ⬇ レイアウトは「翌日配送予定」と同じイメージ
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DeliveryDetailScreen(
                  item: item,
                  mode: DeliveryDetailMode.completed,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 上段: 区分 + 日時 + 担当配送員
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.kubun, // レンタル / 販売 など
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // 日時
                            '${item.deliveryDate ?? ''} ${item.deliveryTime ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '担当配送員: ${item.haisouTantoName ?? '未定'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 利用者名
                Text(
                  item.customerName ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // 住所
                Text(
                  item.address ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                // 商品名
                Text(
                  item.itemName ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
