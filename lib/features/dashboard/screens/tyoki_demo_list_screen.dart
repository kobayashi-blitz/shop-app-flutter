import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/tyoki_demo_item.dart';
import '../providers/dashboard_provider.dart';

enum DemoFilter { oneMonth, tyoki }

class TyokiDemoListScreen extends ConsumerStatefulWidget {
  const TyokiDemoListScreen({super.key});

  @override
  ConsumerState<TyokiDemoListScreen> createState() =>
      _TyokiDemoListScreenState();
}

class _TyokiDemoListScreenState extends ConsumerState<TyokiDemoListScreen> {
  bool _isLoading = true;
  String? _error;
  List<TyokiDemoItem> _items = [];
  DemoFilter _filter = DemoFilter.oneMonth;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = ref.read(authProvider).user;
      final shopId = user?.shopId;
      final tantoId = user?.shopSyainId;
      if (shopId == null || tantoId == null) {
        setState(() {
          _isLoading = false;
          _error = 'ログイン情報が取得できませんでした。';
        });
        return;
      }
      final service = ref.read(riyojokyoServiceProvider);
      final list = await service.moreOneMonthDemoDetails(
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
        _error = '取得に失敗しました';
      });
    }
  }

  /// "YYYY/MM/DD" -> 経過日数 (今日を含む)。失敗時は null。
  int? _elapsedDays(String dateText) {
    try {
      final parts = dateText.split('/');
      if (parts.length != 3) return null;
      final from = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final today = DateTime.now();
      final t = DateTime(today.year, today.month, today.day);
      return t.difference(from).inDays + 1;
    } catch (_) {
      return null;
    }
  }

  bool _matchesFilter(TyokiDemoItem item) {
    if (_filter == DemoFilter.oneMonth) return true;
    final days = _elapsedDays(item.keiyakuDateFrom) ?? 0;
    return days >= 90;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where(_matchesFilter).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('長期デモ商品'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(filtered),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SegmentedButton<DemoFilter>(
        segments: const [
          ButtonSegment<DemoFilter>(
            value: DemoFilter.oneMonth,
            label: Text('1ヶ月以上'),
          ),
          ButtonSegment<DemoFilter>(
            value: DemoFilter.tyoki,
            label: Text('長期(3ヶ月以上)'),
          ),
        ],
        selected: {_filter},
        onSelectionChanged: (s) => setState(() => _filter = s.first),
      ),
    );
  }

  Widget _buildBody(List<TyokiDemoItem> items) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Center(
            child: Text(_error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center),
          ),
        ],
      );
    }
    if (items.isEmpty) {
      final msg = _filter == DemoFilter.tyoki
          ? '長期(3ヶ月以上)のデモ商品はありません'
          : '1ヶ月以上のデモ商品はありません';
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(msg,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildTile(items[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }

  Widget _buildTile(TyokiDemoItem item) {
    final days = _elapsedDays(item.keiyakuDateFrom);
    final isOver90 = (days ?? 0) >= 90;
    final accent = isOver90 ? Colors.red.shade700 : Colors.orange.shade800;
    final nameStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isOver90 ? Colors.red.shade700 : Colors.black87,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isOver90 ? Colors.red.shade200 : Colors.grey.withOpacity(0.2),
          width: isOver90 ? 1.2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.riyosyaName,
                    style: nameStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (days != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$days日経過',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.inventory_2, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.syohinName,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isOver90 ? Colors.red.shade800 : Colors.grey.shade800,
                    ),
                  ),
                ),
                if (item.syohinClass1.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.syohinClass1,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'デモ開始: ${item.keiyakuDateFrom}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
