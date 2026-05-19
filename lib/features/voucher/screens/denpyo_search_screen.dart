import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/denpyo_search_item.dart';
import '../providers/voucher_provider.dart';

// お客様控え伝票検索画面。伝票種類複数選択 + 希望日 + 一覧 → タップで PDF。
class DenpyoSearchScreen extends ConsumerStatefulWidget {
  const DenpyoSearchScreen({super.key});

  @override
  ConsumerState<DenpyoSearchScreen> createState() => _DenpyoSearchScreenState();
}

class _DenpyoSearchScreenState extends ConsumerState<DenpyoSearchScreen> {
  static const int _perPage = 50;

  final Set<String> _selectedTypes = {'1'}; // デフォルト：レンタル納品伝票
  DateTime? _hakkoubi;
  bool _isSearching = false;
  bool _isPaging = false;
  bool _isOpening = false;
  String? _error;
  int _total = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  List<DenpyoSearchItem> _items = [];
  bool _hasSearched = false;

  Future<void> _fetch(int page) async {
    final user = ref.read(authProvider).user;
    final shopId = user?.shopId;
    if (shopId == null) {
      throw Exception('ログイン情報が取得できませんでした。');
    }
    final service = ref.read(voucherServiceProvider);
    final hakkoubi =
        _hakkoubi == null ? null : DateFormat('yyyy-MM-dd').format(_hakkoubi!);
    final res = await service.searchDenpyo(
      shopId: shopId,
      denpyoSyurui: _selectedTypes.toList(),
      hakkoubi: hakkoubi,
      page: page,
      perPage: _perPage,
    );
    setState(() {
      _items = res.items;
      _total = res.total;
      _currentPage = res.page;
      _totalPages = (res.total / _perPage).ceil().clamp(1, 9999);
    });
  }

  Future<void> _search() async {
    final user = ref.read(authProvider).user;
    if (user?.shopId == null) {
      setState(() => _error = 'ログイン情報が取得できませんでした。');
      return;
    }
    if (_selectedTypes.isEmpty) {
      setState(() => _error = '伝票種類を 1 つ以上選択してください。');
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _hasSearched = true;
      _currentPage = 1;
    });
    try {
      await _fetch(1);
    } catch (_) {
      setState(() => _error = '伝票検索に失敗しました');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _goToPage(int newPage) async {
    final clamped = newPage.clamp(1, _totalPages);
    if (clamped == _currentPage) return;
    setState(() => _isPaging = true);
    try {
      await _fetch(clamped);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ページ取得に失敗しました')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaging = false);
    }
  }

  Future<void> _openPdf(DenpyoSearchItem item) async {
    final user = ref.read(authProvider).user;
    final shopId = user?.shopId;
    final mytype = item.mytype;
    if (shopId == null || mytype.isEmpty) return;

    setState(() => _isOpening = true);
    try {
      final opener = ref.read(pdfOpenerProvider);
      final result = await opener.fetchAndOpen(
        path: '/api/pcwMobileApi/shop/denpyo/print',
        data: {
          'shop_id': shopId,
          'target_id': item.targetId,
          'mytype': mytype,
        },
        fileBaseName: 'denpyo_${mytype}_${item.targetId}',
      );
      if (!mounted) return;
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'PDF を開けませんでした')),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hakkoubi ?? DateTime.now(),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _hakkoubi = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お客様控え伝票検索'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(height: 1),
          Expanded(child: _buildListBody()),
          _buildPager(),
        ],
      ),
    );
  }

  Widget _buildPager() {
    if (!_hasSearched || _items.isEmpty) return const SizedBox.shrink();

    final pageNums = _calcWindowedPages(_currentPage, _totalPages);
    final canPrev = !_isPaging && !_isSearching && _currentPage > 1;
    final canNext = !_isPaging && !_isSearching && _currentPage < _totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: canPrev ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          ...pageNums.map((p) => _PageNumButton(
                page: p,
                isCurrent: p == _currentPage,
                enabled: !_isPaging && !_isSearching,
                onTap: () => _goToPage(p),
              )),
          IconButton(
            onPressed: canNext ? () => _goToPage(_currentPage + 1) : null,
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

  Widget _buildFilters() {
    final dateLabel = _hakkoubi == null
        ? '希望日（指定なし）'
        : DateFormat('yyyy/MM/dd').format(_hakkoubi!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('伝票種類',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: DenpyoTypeOption.all.map((opt) {
              final selected = _selectedTypes.contains(opt.code);
              return FilterChip(
                label: Text(opt.label, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (_isSearching || _isPaging)
                    ? null
                    : (v) {
                        setState(() {
                          if (v) {
                            _selectedTypes.add(opt.code);
                          } else {
                            _selectedTypes.remove(opt.code);
                          }
                        });
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_isSearching || _isPaging) ? null : _pickDate,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(dateLabel),
                ),
              ),
              if (_hakkoubi != null)
                IconButton(
                  onPressed: (_isSearching || _isPaging)
                      ? null
                      : () => setState(() => _hakkoubi = null),
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: '希望日をクリア',
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: (_isSearching || _isPaging) ? null : _search,
                icon: _isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search, size: 18),
                label: const Text('検索'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_hasSearched &&
              !_isSearching &&
              _error == null &&
              _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$_total 件中 ${(_currentPage - 1) * _perPage + 1}-${(_currentPage - 1) * _perPage + _items.length} 件目',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListBody() {
    if (_isSearching && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error!),
          ],
        ),
      );
    }
    if (!_hasSearched) {
      return const Center(
        child:
            Text('伝票種類を選んで「検索」を押してください', style: TextStyle(color: Colors.grey)),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('該当する伝票はありません', style: TextStyle(color: Colors.grey)),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) => _buildTile(_items[index]),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: _items.length,
        ),
        if (_isOpening)
          Container(
            color: Colors.black26,
            alignment: Alignment.center,
            child: const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('PDF を取得しています…'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTile(DenpyoSearchItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (_isOpening || _isPaging) ? null : () => _openPdf(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.syurui,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.indigo.shade800,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  if (item.hasSignature)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('署名あり',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold)),
                    ),
                  const Spacer(),
                  Icon(Icons.picture_as_pdf,
                      size: 18, color: Colors.grey.shade500),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.riyosyaName.isEmpty ? '(利用者未設定)' : item.riyosyaName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (item.riyosyaKana.isNotEmpty)
                Text(item.riyosyaKana,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.event, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(item.denpyoDate,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                ],
              ),
              if ((item.bikou ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(item.bikou!,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade800)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PageNumButton extends StatelessWidget {
  final int page;
  final bool isCurrent;
  final bool enabled;
  final VoidCallback onTap;
  const _PageNumButton({
    required this.page,
    required this.isCurrent,
    required this.enabled,
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
          onPressed: (enabled && !isCurrent) ? onTap : null,
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
