import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/display_format.dart';
import '../../sinsei/screens/nyuin_horyu_sinsei_create_screen.dart';
import '../models/keiyakutyu_riyosya_item.dart';
import '../providers/dashboard_provider.dart';

/// SAP-8 (+ SAP-15 統合候補): 契約中利用者詳細
///
/// 上部にテキスト検索 (名前 / ふりがな / 住所の部分一致) と、下部に
/// 30 件単位のページャを備える。`お客様控え伝票検索` 画面の UI パターンと、
/// 利用者照会画面 ([RiyosyaSyokaiListScreen]) の検索 / ページャ実装を踏襲。
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

  // --- 検索 ---
  final _searchController = TextEditingController();
  bool _filtersExpanded = true;
  String _query = '';

  // --- ページャ ---
  static const int _perPage = 30;
  int _currentPage = 1;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        _currentPage = 1;
      });
    } catch (_) {
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

  /// 検索クエリを正規化: 半角/全角スペース除去 + 大文字小文字無視。
  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s　]'), '');

  /// 名前 / ふりがな / 住所 (pref + jyusyo1 + jyusyo2) のいずれかに
  /// 部分一致したら true。グループの基本情報は items.first から取り出す。
  bool _matches(_RiyosyaGroup g, String normQuery) {
    if (normQuery.isEmpty) return true;
    final head = g.items.first;
    final hay = _normalize(
      [
        head.riyosyaName,
        head.riyosyaKana,
        head.riyosyaPref,
        head.riyosyaJyusyo1,
        head.riyosyaJyusyo2,
      ].join(''),
    );
    return hay.contains(normQuery);
  }

  List<_RiyosyaGroup> get _filteredGroups {
    final q = _normalize(_query);
    if (q.isEmpty) return _groups;
    return _groups.where((g) => _matches(g, q)).toList();
  }

  int _totalPagesOf(int filteredCount) =>
      (filteredCount / _perPage).ceil().clamp(1, 9999);

  int _safeCurrentPage(int totalPages) => _currentPage.clamp(1, totalPages);

  List<_RiyosyaGroup> _pageSlice(List<_RiyosyaGroup> filtered, int safePage) {
    final start = (safePage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, filtered.length);
    if (start >= filtered.length) return const [];
    return filtered.sublist(start, end);
  }

  void _goToPage(int page) {
    final filtered = _filteredGroups;
    final total = _totalPagesOf(filtered.length);
    final clamped = page.clamp(1, total);
    if (clamped == _safeCurrentPage(total)) return;
    setState(() => _currentPage = clamped);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _onQueryChanged(String v) {
    setState(() {
      _query = v;
      _currentPage = 1;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGroups;
    final hasQuery = _query.trim().isNotEmpty;
    final totalPages = _totalPagesOf(filtered.length);
    final safePage = _safeCurrentPage(totalPages);
    final pageItems = _pageSlice(filtered, safePage);

    final title = _groups.isEmpty
        ? '契約中の利用者'
        : hasQuery
            ? '契約中の利用者（${filtered.length}/${_groups.length}名）'
            : '契約中の利用者（${_groups.length}名）';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          _buildFiltersCollapsible(),
          _buildResultSummary(filtered.length, safePage, pageItems.length),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(pageItems, filtered.isEmpty, hasQuery),
            ),
          ),
          _buildPager(filtered.length, safePage, totalPages),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return InkWell(
      onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Icon(Icons.filter_list, size: 18, color: Colors.indigo.shade700),
            const SizedBox(width: 8),
            const Text('検索条件',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            AnimatedRotation(
              turns: _filtersExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersCollapsible() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: ClipRect(
        child: Visibility(
          visible: _filtersExpanded,
          maintainState: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '名前・ふりがな・住所で検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSummary(int filteredCount, int safePage, int onPage) {
    if (filteredCount == 0) return const SizedBox.shrink();
    final from = (safePage - 1) * _perPage + 1;
    final to = (safePage - 1) * _perPage + onPage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        '$filteredCount 名中 $from-$to 名目',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildBody(
      List<_RiyosyaGroup> pageItems, bool filteredIsEmpty, bool hasQuery) {
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
    if (filteredIsEmpty && hasQuery) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text('該当する利用者はいません',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildGroupCard(pageItems[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: pageItems.length,
    );
  }

  /// ページャ。`お客様控え伝票検索` と同形 (前へ ← + 5 番号 + 次へ →)。
  Widget _buildPager(int filteredCount, int safePage, int totalPages) {
    if (filteredCount == 0 || totalPages <= 1) {
      return const SizedBox.shrink();
    }
    final pageNums = _calcWindowedPages(safePage, totalPages);
    final canPrev = safePage > 1;
    final canNext = safePage < totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: canPrev ? () => _goToPage(safePage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          ...pageNums.map((p) => _PageNumButton(
                page: p,
                isCurrent: p == safePage,
                onTap: () => _goToPage(p),
              )),
          IconButton(
            onPressed: canNext ? () => _goToPage(safePage + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  /// 現在ページを中心に前後 2 ページずつ、最大 5 番号を返す。
  List<int> _calcWindowedPages(int current, int total) {
    if (total <= 5) return List.generate(total, (i) => i + 1);
    int start = current - 2;
    int end = current + 2;
    if (start < 1) {
      end += (1 - start);
      start = 1;
    }
    if (end > total) {
      start -= (end - total);
      end = total;
    }
    start = start.clamp(1, total);
    return List.generate(end - start + 1, (i) => start + i);
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
                      // 敬称は表示のみ。検索 (_matches) / ソート / 子画面への
                      // 引数は生値のまま扱う。
                      formatRiyosyaName(group.riyosyaName,
                          emptyPlaceholder: ''),
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

class _PageNumButton extends StatelessWidget {
  final int page;
  final bool isCurrent;
  final VoidCallback onTap;
  const _PageNumButton({
    required this.page,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 40,
        height: 40,
        child: TextButton(
          onPressed: isCurrent ? null : onTap,
          style: TextButton.styleFrom(
            backgroundColor: isCurrent ? Colors.indigo : null,
            foregroundColor: isCurrent ? Colors.white : Colors.indigo,
            disabledForegroundColor:
                isCurrent ? Colors.white : Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text('$page'),
        ),
      ),
    );
  }
}
