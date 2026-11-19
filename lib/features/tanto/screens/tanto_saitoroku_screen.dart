import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tanto_models.dart';
import '../providers/tanto_provider.dart';
import '../providers/tanto_service.dart';
import '../tanto_labels.dart';
import '../widgets/tanto_widgets.dart';

/// 利用者再登録 (PRMT-32・33)。選んだ利用者をログイン中の担当者の担当にする。
///
/// - 選択は検索やページ移動をしても残す。選んだ時点の shop_syain_id / rireki_id を持ち、
///   一覧を取り直しても上書きしない (上書きすると、ほかの人の変更を 409 で検知できなくなる)
/// - 自分が今担当している利用者は、チェック済みのまま外せない (外すのは担当者未設定登録で行う)
class TantoSaitorokuScreen extends ConsumerStatefulWidget {
  const TantoSaitorokuScreen({
    super.key,
    this.maxSelection = TantoService.maxItems,
  });

  /// 一度に送れる人数。pcw の上限 (500) に合わせる。テストで小さくするための入口。
  final int maxSelection;

  @override
  ConsumerState<TantoSaitorokuScreen> createState() =>
      _TantoSaitorokuScreenState();
}

class _TantoSaitorokuScreenState extends ConsumerState<TantoSaitorokuScreen> {
  static const jibunNote = '担当を外すには担当者未設定登録へ';

  final _keywordController = TextEditingController();
  TantoJotai _jotai = TantoJotai.all;
  int? _syainId;
  TantoKeiyaku _keiyaku = TantoKeiyaku.keiyakutyu;
  int _page = 1;

  TantoListResult? _result;
  bool _loading = false;
  String? _error;
  int _fetchSeq = 0;

  /// 選んだ利用者 (riyosya_id → 選んだ時点の行)。
  final Map<int, TantoRiyosyaItem> _selected = {};
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
            jotai: _jotai,
            syainId: _syainId,
            keiyaku: _keiyaku,
            page: target,
          );
      if (!mounted || seq != _fetchSeq) return;
      // 登録で件数が減り、今のページが最後のページより後ろになったら戻す。
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

  bool _isJibun(TantoRiyosyaItem item) =>
      _result != null && item.tantoSyainId == _result!.jibunSyainId;

  void _toggle(TantoRiyosyaItem item, bool checked) {
    setState(() {
      if (!checked) {
        _selected.remove(item.riyosyaId);
        return;
      }
      if (_selected.length >= widget.maxSelection) {
        _showSnack('一度に登録できるのは${widget.maxSelection}人までです。');
        return;
      }
      _selected[item.riyosyaId] = item;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmAndSubmit() async {
    // 確認した中身をそのまま送る (ダイアログ中に一覧が変わっても送る対象は変えない)。
    final items = _selected.values.toList();
    if (items.isEmpty) return;
    final hikitsugi = items.where((e) => e.tantoSyainId != null).length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('担当に登録しますか？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('自分の担当に登録：${items.length}人'),
            Text('うち、ほかの担当者から引き継ぎ：$hikitsugi人'),
            if (hikitsugi > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'ほかの担当者の利用者が含まれています。担当者が変わります。',
                  style: TextStyle(color: Colors.red.shade700),
                ),
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
            child: const Text('登録する'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(tantoServiceProvider).saitoroku(items);
      if (!mounted) return;
      setState(() {
        for (final item in items) {
          _selected.remove(item.riyosyaId);
        }
      });
      _showSnack('${items.length}人を自分の担当に登録しました。');
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
        // 競合・指定できない利用者は選択から外し、ほかの選択は残して取り直す。
        final ids = e.riyosyaIds.toSet();
        final affected = sent.where((s) => ids.contains(s.riyosyaId));
        final names = describeRiyosyaNames(affected);
        setState(() {
          for (final id in ids) {
            _selected.remove(id);
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
      appBar: AppBar(title: const Text(TantoLabels.saitoroku)),
      body: Column(
        children: [
          _buildFilters(result),
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

  Widget _buildFilters(TantoListResult? result) {
    final syainList = result?.syainList ?? const <TantoSyain>[];
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
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TantoJotai>(
                  value: _jotai,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '担当状態',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: TantoJotai.values
                      .map((j) =>
                          DropdownMenuItem(value: j, child: Text(j.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _jotai = v);
                    _load(page: 1);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: syainList.any((s) => s.shopSyainId == _syainId)
                      ? _syainId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '担当者',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('指定なし'),
                    ),
                    ...syainList.map((s) => DropdownMenuItem<int?>(
                          value: s.shopSyainId,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _syainId = v);
                    _load(page: 1);
                  },
                ),
              ),
            ],
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
                      child: Center(child: Text('該当する利用者はいません。')),
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: result.items.length,
                  itemBuilder: (_, i) {
                    final item = result.items[i];
                    final jibun = _isJibun(item);
                    return TantoRiyosyaCard(
                      key: ValueKey('tanto-${item.riyosyaId}'),
                      item: item,
                      checked: jibun || _selected.containsKey(item.riyosyaId),
                      onChanged:
                          jibun || _submitting ? null : (v) => _toggle(item, v),
                      note: jibun ? jibunNote : null,
                    );
                  },
                ),
        ),
        if (_loading) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildBottomBar() {
    final count = _selected.length;
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
                        title: '選んでいる利用者',
                        selection: _selected,
                        onRemove: (id) => setState(() => _selected.remove(id)),
                      ),
              icon: const Icon(Icons.checklist),
              label: Text('選択中 $count人'),
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
                  : Text('登録（$count人）'),
            ),
          ],
        ),
      ),
    );
  }
}
