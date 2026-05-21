import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/riyosya_syokai_item.dart';
import '../providers/dashboard_provider.dart';
import 'riyosya_syokai_detail_screen.dart';

/// 利用者照会 一覧画面。担当者が過去に契約したことのある利用者を含む全リスト。
///
/// 「契約利用者 / 入院保留申請」が現在契約中のみだったのに対し、本画面は
/// 過去契約 (返却完了系) も含めて閲覧できる。タップで利用者詳細画面へ遷移。
class RiyosyaSyokaiListScreen extends ConsumerStatefulWidget {
  const RiyosyaSyokaiListScreen({super.key});

  @override
  ConsumerState<RiyosyaSyokaiListScreen> createState() =>
      _RiyosyaSyokaiListScreenState();
}

class _RiyosyaSyokaiListScreenState
    extends ConsumerState<RiyosyaSyokaiListScreen> {
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
      final raw = await service.riyosyaSyokaiDetails(
        shopId: shopId,
        tantoId: tantoId,
      );
      setState(() {
        _groups = _groupByRiyosya(raw);
        _isLoading = false;
      });
    } catch (_) {
      // PII を含まない汎用メッセージのみ画面表示する。
      setState(() {
        _isLoading = false;
        _error = '取得に失敗しました';
      });
    }
  }

  /// 利用者 ID で集約。商品行 1 行を 1 利用者カード内の 1 行に対応させる。
  /// 並び順はサーバの ORDER BY (氏名 ASC, 契約開始日 DESC) を尊重するため
  /// LinkedHashMap の挿入順を保持する。
  List<_RiyosyaGroup> _groupByRiyosya(List<RiyosyaSyokaiItem> items) {
    final map = <int, _RiyosyaGroup>{};
    for (final item in items) {
      final key = item.riyosyaId;
      final existing = map[key];
      if (existing == null) {
        map[key] = _RiyosyaGroup(
          riyosyaId: item.riyosyaId,
          riyosyaName: item.riyosyaName,
          items: [item],
        );
      } else {
        existing.items.add(item);
      }
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = _groups.isEmpty ? '利用者照会' : '利用者照会（${_groups.length}名）';
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
            child: Text('利用者はいません',
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

  void _openDetail(_RiyosyaGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiyosyaSyokaiDetailScreen(items: group.items),
      ),
    );
  }

  Widget _buildGroupCard(_RiyosyaGroup group) {
    final displayName =
        group.riyosyaName.isEmpty ? '(氏名未登録)' : group.riyosyaName;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _openDetail(group),
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
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadges(group),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 20, color: Colors.grey.shade500),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 「契約中 N 件」「過去 N 件」バッジ。N は商品行数。
  Widget _buildStatusBadges(_RiyosyaGroup group) {
    final widgets = <Widget>[];
    if (group.activeCount > 0) {
      widgets.add(_badge(
        '契約中 ${group.activeCount} 件',
        bg: Colors.blue.shade50,
        fg: Colors.blue.shade800,
      ));
    }
    if (group.pastCount > 0) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(width: 6));
      widgets.add(_badge(
        '過去 ${group.pastCount} 件',
        bg: Colors.grey.shade200,
        fg: Colors.grey.shade800,
      ));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: widgets);
  }

  Widget _badge(String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

class _RiyosyaGroup {
  final int riyosyaId;
  final String riyosyaName;
  final List<RiyosyaSyokaiItem> items;
  _RiyosyaGroup({
    required this.riyosyaId,
    required this.riyosyaName,
    required this.items,
  }) : assert(items.isNotEmpty);
  int get activeCount => items.where((e) => e.isActive).length;
  int get pastCount => items.length - activeCount;
}
