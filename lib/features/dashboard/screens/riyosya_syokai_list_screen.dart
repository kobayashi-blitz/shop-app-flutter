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
///
/// 上部にテキスト検索 (名前 / ふりがな / 住所の部分一致) と、下部に
/// 30 件単位のページャを備える。`お客様控え伝票検索` 画面の UI を踏襲。
/// データ取得済みのクライアント側フィルタ + ページングなので追加 API
/// コールはしない。
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
      final raw = await service.riyosyaSyokaiDetails(
        shopId: shopId,
        tantoId: tantoId,
      );
      setState(() {
        _groups = _groupByRiyosya(raw);
        _isLoading = false;
        _currentPage = 1;
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

  /// 検索クエリを正規化: 半角/全角スペース除去 + 大文字小文字無視。
  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s　]'), '');

  /// 1 グループが現在のクエリにヒットするかを返す。
  /// 名前 / ふりがな / 住所 (pref + jyusyo1 + jyusyo2) のいずれかに
  /// 部分一致したら true。
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

  /// `_currentPage` が範囲外になった場合に最終ページに丸める。
  /// 検索フィルタを変更した直後など、件数が縮んで現在ページが空になるのを防ぐ。
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

  /// 検索クエリ変更時は 1 ページ目に戻す。
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
        ? '利用者照会'
        : hasQuery
            ? '利用者照会（${filtered.length}/${_groups.length}名）'
            : '利用者照会（${_groups.length}名）';
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
            child: Text('利用者はいません',
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
  /// 結果 0 件 / 1 ページのみの場合は表示しない。
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
  /// 端では片側を多めに表示し常に 5 個 (足りなければ可能な分) を維持。
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
