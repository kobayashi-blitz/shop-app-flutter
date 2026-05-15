import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/tomorrow_delivery_item.dart';
import '../providers/tomorrow_delivery_service.dart';
import '../widgets/delivery_list_tile.dart';
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
      // ログインユーザーから shop_id / tantoId(shopSyainId) を取得
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

      final apiClient = ref.read(apiClientProvider);
      final service = TomorrowDeliveryService(apiClient);

      final list = await service.fetchTodayCompletedList(
        shopId: shopId,
        tantoId: tantoId,
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
        return DeliveryListTile(
          item: item,
          detailMode: DeliveryDetailMode.completed,
        );
      },
    );
  }
}
