import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../sinsei/screens/nyuin_horyu_sinsei_create_screen.dart';
import '../models/keiyakutyu_riyosya_item.dart';
import '../providers/dashboard_provider.dart';

// SAP-8 (+ SAP-15 統合候補): 契約中利用者詳細
class KeiyakutyuRiyosyaListScreen extends ConsumerStatefulWidget {
  const KeiyakutyuRiyosyaListScreen({super.key});

  @override
  ConsumerState<KeiyakutyuRiyosyaListScreen> createState() =>
      _KeiyakutyuRiyosyaListScreenState();
}

class _KeiyakutyuRiyosyaListScreenState
    extends ConsumerState<KeiyakutyuRiyosyaListScreen> {
  bool _isLoading = true;
  String? _error;
  List<_RiyosyaGroup> _groups = [];

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
      final raw = await service.keiyakutyuRiyosyaDetails(
        shopId: shopId,
        tantoId: tantoId,
      );
      setState(() {
        _groups = _groupByRiyosya(raw);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '取得に失敗しました';
      });
    }
  }

  /// 利用者 ID で集約。
  /// 旧仕様では `riyosyaName` をキーにしていたため同名別人が同一カードに混ざっていたが、
  /// SAP-13 入院保留申請で利用者 ID が必要になったのを契機に id ベースに変更。
  /// 副作用として同名別人は別カードに分かれる（仕様変更として PR で明記）。
  List<_RiyosyaGroup> _groupByRiyosya(List<KeiyakutyuRiyosyaItem> items) {
    final map = <int, _RiyosyaGroup>{};
    for (final item in items) {
      final key = item.riyosyaId;
      final existing = map[key];
      if (existing == null) {
        map[key] = _RiyosyaGroup(
          riyosyaId: item.riyosyaId,
          riyosyaName: item.riyosyaName,
          earliestKeiyakuDateFrom: item.keiyakuDateFrom,
          items: [item],
        );
      } else {
        existing.items.add(item);
        if (item.keiyakuDateFrom.isNotEmpty &&
            (existing.earliestKeiyakuDateFrom.isEmpty ||
                item.keiyakuDateFrom
                        .compareTo(existing.earliestKeiyakuDateFrom) <
                    0)) {
          existing.earliestKeiyakuDateFrom = item.keiyakuDateFrom;
        }
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => a.riyosyaName.compareTo(b.riyosyaName));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final title = _groups.isEmpty ? '契約中の利用者' : '契約中の利用者（${_groups.length}名）';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _groups.isEmpty) {
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
    if (_groups.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text('契約中の利用者はいません',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildGroupCard(_groups[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _groups.length,
    );
  }

  void _openSinsei(_RiyosyaGroup group) {
    final shopId = ref.read(authProvider).user?.shopId;
    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログイン情報が取得できませんでした。')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NyuinHoryuSinseiCreateScreen(
          shopId: shopId,
          riyosyaId: group.riyosyaId,
          riyosyaName: group.riyosyaName,
        ),
      ),
    );
  }

  Widget _buildGroupCard(_RiyosyaGroup group) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _openSinsei(group),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.riyosyaName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '契約商品 ${group.items.length} 件',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              if (group.earliestKeiyakuDateFrom.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.event, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '最初の契約: ${group.earliestKeiyakuDateFrom}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
              const Divider(height: 16),
              ...group.items.map((it) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.inventory_2,
                            size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.syohinName,
                                  style: const TextStyle(fontSize: 13)),
                              Text(
                                '契約開始: ${it.keiyakuDateFrom}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiyosyaGroup {
  final int riyosyaId;
  final String riyosyaName;
  String earliestKeiyakuDateFrom;
  final List<KeiyakutyuRiyosyaItem> items;
  _RiyosyaGroup({
    required this.riyosyaId,
    required this.riyosyaName,
    required this.earliestKeiyakuDateFrom,
    required this.items,
  });
}
