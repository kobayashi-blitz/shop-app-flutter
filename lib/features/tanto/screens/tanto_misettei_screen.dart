import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tanto_models.dart';
import '../providers/tanto_provider.dart';
import '../providers/tanto_service.dart';
import '../tanto_labels.dart';
import '../widgets/tanto_widgets.dart';

/// 担当者未設定登録 (PRMT-34)。自分が担当している利用者のうち、
/// チェックを外した人を担当者未設定にする。
///
/// 初めは全員チェック済み。外した人は外した時点の shop_syain_id / rireki_id で持ち、
/// ページをまたいでも残す (取り直しても上書きしない)。
class TantoMisetteiScreen extends ConsumerStatefulWidget {
  const TantoMisetteiScreen({
    super.key,
    this.maxSelection = TantoService.maxItems,
  });

  /// 一度に送れる人数。pcw の上限 (500) に合わせる。テストで小さくするための入口。
  final int maxSelection;

  @override
  ConsumerState<TantoMisetteiScreen> createState() =>
      _TantoMisetteiScreenState();
}

class _TantoMisetteiScreenState extends ConsumerState<TantoMisetteiScreen> {
  final _keywordController = TextEditingController();
  TantoKeiyaku _keiyaku = TantoKeiyaku.keiyakutyu;
  int _page = 1;

  TantoListResult? _result;
  bool _loading = false;
  String? _error;
  int _fetchSeq = 0;

  /// チェックを外した利用者 (riyosya_id → 外した時点の行)。
  final Map<int, TantoRiyosyaItem> _unchecked = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    final seq = ++_fetchSeq;
    final target = page ?? _page;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(tantoServiceProvider).fetchList(
            keyword: _keywordController.text,
            jotai: TantoJotai.jibun,
            keiyaku: _keiyaku,
            page: target,
          );
      if (!mounted || seq != _fetchSeq) return;
      // 未設定にして件数が減り、今のページが最後のページより後ろになったら戻す。
      if (result.items.isEmpty && target > result.totalPages) {
        _load(page: result.totalPages);
        return;
      }
      setState(() {
        _result = result;
        _page = target;
        _loading = false;
      });
    } on TantoApiException catch (e) {
      if (!mounted || seq != _fetchSeq) return;
      setState(() {
        _loading = false;
        _error =
            e.kind == TantoErrorKind.unauthenticated ? null : '一覧の取得に失敗しました';
      });
    }
  }

  void _search() {
    FocusScope.of(context).unfocus();
    _load(page: 1);
  }

  void _toggle(TantoRiyosyaItem item, bool checked) {
    setState(() {
      if (checked) {
        _unchecked.remove(item.riyosyaId);
        return;
      }
      if (_unchecked.length >= widget.maxSelection) {
        _showSnack('一度に変更できるのは${widget.maxSelection}人までです。');
        return;
      }
      _unchecked[item.riyosyaId] = item;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmAndSubmit() async {
    // 確認した中身をそのまま送る。
    final items = _unchecked.values.toList();
    if (items.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('担当者未設定にしますか？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('自分の担当から外す：${items.length}人'),
            const SizedBox(height: 8),
            Text(describeRiyosyaNames(items)),
            const SizedBox(height: 12),
            Text(
              'この利用者は担当者未設定になります。',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('未設定にする'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(tantoServiceProvider).misettei(items);
      if (!mounted) return;
      setState(() {
        for (final item in items) {
          _unchecked.remove(item.riyosyaId);
        }
      });
      _showSnack('${items.length}人を担当者未設定にしました。');
      await _load();
    } on TantoApiException catch (e) {
      if (!mounted) return;
      await _handleError(e, items);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleError(
    TantoApiException e,
    List<TantoRiyosyaItem> sent,
  ) async {
    switch (e.kind) {
      case TantoErrorKind.conflict:
      case TantoErrorKind.invalid:
        // 競合・自分の担当でなくなった利用者は外し、ほかは残して取り直す。
        final ids = e.riyosyaIds.toSet();
        final affected = sent.where((s) => ids.contains(s.riyosyaId));
        final names = describeRiyosyaNames(affected);
        setState(() {
          for (final id in ids) {
            _unchecked.remove(id);
          }
        });
        _showSnack(names.isEmpty ? e.message : '${e.message}\n対象：$names');
        await _load();
      case TantoErrorKind.unauthenticated:
        // ログアウトとログイン画面への移動はアプリのルートが行う。
        break;
      case TantoErrorKind.retry:
      case TantoErrorKind.network:
      case TantoErrorKind.unknown:
        _showSnack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text(TantoLabels.misettei)),
      body: Column(
        children: [
          _buildFilters(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '自分が担当している利用者です。担当から外す利用者のチェックを外してください。',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          if (result != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${result.total}人',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ),
          Expanded(child: _buildList(result)),
          if (result != null)
            TantoPager(
              page: _page,
              totalPages: result.totalPages,
              enabled: !_loading && !_submitting,
              onPage: (p) => _load(page: p),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          TextField(
            controller: _keywordController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: '氏名・ふりがな・住所で検索',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: '検索',
                icon: const Icon(Icons.arrow_forward),
                onPressed: _search,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<TantoKeiyaku>(
            segments: TantoKeiyaku.values
                .map((k) => ButtonSegment(value: k, label: Text(k.label)))
                .toList(),
            selected: {_keiyaku},
            onSelectionChanged: (s) {
              setState(() => _keiyaku = s.first);
              _load(page: 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(TantoListResult? result) {
    if (_loading && result == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('再読み込み')),
          ],
        ),
      );
    }
    if (result == null) return const SizedBox.shrink();
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: result.items.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('担当している利用者はいません。')),
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: result.items.length,
                  itemBuilder: (_, i) {
                    final item = result.items[i];
                    return TantoRiyosyaCard(
                      key: ValueKey('tanto-${item.riyosyaId}'),
                      item: item,
                      checked: !_unchecked.containsKey(item.riyosyaId),
                      onChanged: _submitting ? null : (v) => _toggle(item, v),
                    );
                  },
                ),
        ),
        if (_loading) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildBottomBar() {
    final count = _unchecked.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: count == 0 || _submitting
                  ? null
                  : () => showTantoSelectionSheet(
                        context: context,
                        title: '担当から外す利用者',
                        selection: _unchecked,
                        onRemove: (id) => setState(() => _unchecked.remove(id)),
                      ),
              icon: const Icon(Icons.checklist),
              label: Text('外す $count人'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: count == 0 || _submitting ? null : _confirmAndSubmit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('担当者未設定にする（$count人）'),
            ),
          ],
        ),
      ),
    );
  }
}
