import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/display_format.dart';
import '../models/sinsei_models.dart';
import '../providers/sinsei_provider.dart';

enum SinseiKubun { create, update }

extension on SinseiKubun {
  String get apiValue => this == SinseiKubun.create ? '1' : '2';
}

class NyuinHoryuSinseiCreateScreen extends ConsumerStatefulWidget {
  final int shopId;
  final int riyosyaId;
  final String? riyosyaName;
  final String? riyosyaKana;

  const NyuinHoryuSinseiCreateScreen({
    super.key,
    required this.shopId,
    required this.riyosyaId,
    this.riyosyaName,
    this.riyosyaKana,
  });

  @override
  ConsumerState<NyuinHoryuSinseiCreateScreen> createState() =>
      _NyuinHoryuSinseiCreateScreenState();
}

class _NyuinHoryuSinseiCreateScreenState
    extends ConsumerState<NyuinHoryuSinseiCreateScreen> {
  SinseiKubun _sinseiKubun = SinseiKubun.create;
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _riyuController = TextEditingController();

  /// チェックされた rental_id の集合。
  /// 初期化タイミング:
  /// - 初回ロード時 → create モードなら rentals 全件、update モードは空
  /// - sinsei_kubun 切替 → 上記と同じ
  /// - 変更モードで select_rental_horyu_id を切替 → horyu_orders[] の全件
  /// それ以外（ソフト再フェッチ）は **保持**。
  final Set<int> _checkedRentalIds = {};

  int? _selectedHoryuId;

  /// 「checkedRentalIds をデータ受信後に再初期化すべきか」のフラグ。
  /// fetchInit を発火する直前に立て、データ受信後の最初の build で消費する。
  bool _resetChecksOnNextData = true;

  SinseiProviderArgs get _args =>
      SinseiProviderArgs(shopId: widget.shopId, riyosyaId: widget.riyosyaId);

  @override
  void dispose() {
    _riyuController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  /// "YYYY/MM/DD" を DateTime に変換。失敗時 null。
  DateTime? _parseDate(String? text) {
    if (text == null || text.isEmpty) return null;
    final parts = text.split('/');
    if (parts.length != 3) return null;
    try {
      return DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _fromDate : _toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  /// data 受信後に呼ばれ、checkedRentalIds を sinsei_kubun に応じて初期化する。
  void _applyInitialChecks(SinseiCreateData data) {
    _checkedRentalIds.clear();
    if (_sinseiKubun == SinseiKubun.create) {
      _checkedRentalIds.addAll(data.rentals.map((e) => e.rentalId));
    } else {
      _checkedRentalIds.addAll(data.horyuOrders.map((e) => e.rentalId));
    }
  }

  void _toggleAllChecks(SinseiCreateData data) {
    setState(() {
      final ids = (_sinseiKubun == SinseiKubun.create)
          ? data.rentals.map((e) => e.rentalId).toSet()
          : data.horyuOrders.map((e) => e.rentalId).toSet();
      if (_checkedRentalIds.containsAll(ids) &&
          _checkedRentalIds.length == ids.length) {
        _checkedRentalIds.clear();
      } else {
        _checkedRentalIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  void _selectHoryuRecord(SinseiHoryuRecord record) {
    setState(() {
      _selectedHoryuId = record.rentalHoryuId;
      _resetChecksOnNextData = true;
    });
    ref.read(sinseiProvider(_args).notifier).fetchInit(
          sinseiKubun: SinseiKubun.update.apiValue,
          selectRentalHoryuId: record.rentalHoryuId,
        );
  }

  void _onSinseiKubunChanged(SinseiKubun v) {
    setState(() {
      _sinseiKubun = v;
      _selectedHoryuId = null;
      _fromDate = null;
      _toDate = null;
      _resetChecksOnNextData = true;
    });
    ref.read(sinseiProvider(_args).notifier).fetchInit(sinseiKubun: v.apiValue);
  }

  /// 変更モードでサーバから取得した「対象保留」の日付を画面に prefill する。
  void _prefillFromHoryuOrders(SinseiCreateData data) {
    if (data.horyuOrders.isEmpty) return;
    final first = data.horyuOrders.first;
    final f = _parseDate(first.inpHoryuDateFrom);
    final t = _parseDate(first.inpHoryuDateTo);
    if (f != null) _fromDate = f;
    _toDate = t;
  }

  Future<void> _submit(SinseiCreateData data) async {
    if (_fromDate == null) {
      _showSnack('開始日を入力してください');
      return;
    }
    if (_sinseiKubun == SinseiKubun.create && _checkedRentalIds.isEmpty) {
      _showSnack('商品は一つ以上、選択してください');
      return;
    }
    if (_sinseiKubun == SinseiKubun.update && _selectedHoryuId == null) {
      _showSnack('変更対象の保留期間を選択してください');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('入院保留申請'),
        content: const Text('申請を実行してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('実行'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    // 申請ペイロードを組み立てる
    if (_sinseiKubun == SinseiKubun.create) {
      final rentals = data.rentals;
      await ref.read(sinseiProvider(_args).notifier).submit(
            sinseiKubun: SinseiKubun.create.apiValue,
            sinseiFromDate: _formatDate(_fromDate!),
            sinseiToDate: _toDate == null ? null : _formatDate(_toDate!),
            sinseiRiyu: _riyuController.text,
            horyucheck: rentals
                .map((r) => r.rentalId)
                .where(_checkedRentalIds.contains)
                .toList(),
            rentalid: rentals.map((r) => r.rentalId).toList(),
            tankaflag: rentals.map((r) => r.rentalTankaFlag ?? '').toList(),
          );
    } else {
      // update: horyu_orders[] を対象に rentalid/tankaflag/rental_horyu_syohin_id/old_* を構築
      final orders = data.horyuOrders;
      await ref.read(sinseiProvider(_args).notifier).submit(
            sinseiKubun: SinseiKubun.update.apiValue,
            sinseiFromDate: _formatDate(_fromDate!),
            sinseiToDate: _toDate == null ? null : _formatDate(_toDate!),
            sinseiRiyu: _riyuController.text,
            horyucheck: orders
                .map((o) => o.rentalId)
                .where(_checkedRentalIds.contains)
                .toList(),
            rentalid: orders.map((o) => o.rentalId).toList(),
            tankaflag: orders.map((o) => o.rentalTankaFlag ?? '').toList(),
            rentalHoryuSyohinId:
                orders.map((o) => o.rentalHoryuSyohinId).toList(),
            oldHoryuDateFrom: orders.map((o) => o.oldHoryuDateFrom).toList(),
            oldHoryuDateTo: orders.map((o) => o.oldHoryuDateTo).toList(),
          );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sinseiProvider(_args));

    // データ受信時の副作用処理
    ref.listen<SinseiCreateState>(sinseiProvider(_args), (prev, next) {
      // フェッチ完了
      if (next.data != null && next.data != prev?.data) {
        setState(() {
          if (_resetChecksOnNextData) {
            _applyInitialChecks(next.data!);
            _resetChecksOnNextData = false;
          }
          if (_sinseiKubun == SinseiKubun.update) {
            _prefillFromHoryuOrders(next.data!);
          }
        });
      }
      // 送信完了
      final completedId = next.completedSinseiSyoninId;
      if (completedId != null && prev?.completedSinseiSyoninId != completedId) {
        _showSnack('申請しました (ID: $completedId)');
        Navigator.of(context).pop();
      }
      // 送信エラー
      if (next.submitError != null && next.submitError != prev?.submitError) {
        _showSnack(next.submitError!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('入院保留申請'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(SinseiCreateState state) {
    if (state.isLoading && state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(state.error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(sinseiProvider(_args).notifier)
                    .fetchInit(sinseiKubun: _sinseiKubun.apiValue),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    final data = state.data;
    if (data == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(data),
            const SizedBox(height: 16),
            _buildFormCard(),
            const SizedBox(height: 16),
            if (_sinseiKubun == SinseiKubun.create) ..._buildCreateBody(data),
            if (_sinseiKubun == SinseiKubun.update) ..._buildUpdateBody(data),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: state.isSubmitting ? null : () => _submit(data),
              child: const Text('申請する',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed:
                  state.isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
        // 申請送信中 or 再フェッチ中のオーバーレイ
        if (state.isSubmitting || (state.isLoading && state.data != null))
          const ColoredBox(
            color: Color(0x33000000),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildHeaderCard(SinseiCreateData data) {
    // trim してから存否を判定する。空白のみの値を「あり」と誤判定して
    // 引数側の正しい氏名へのフォールバックを塞がないようにする。
    final name = _firstNonBlank(data.riyosyaName, widget.riyosyaName);
    final kana = _firstNonBlank(data.riyosyaKana, widget.riyosyaKana);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ご利用者名',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              buildRiyosyaDisplayName(name: name, kana: kana),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<SinseiKubun>(
              value: _sinseiKubun,
              decoration: const InputDecoration(
                labelText: '申請内容',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                    value: SinseiKubun.create, child: Text('入院保留')),
                DropdownMenuItem(
                    value: SinseiKubun.update, child: Text('入院保留変更')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _onSinseiKubunChanged(v);
              },
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text('申請保留期間 ',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('※', style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _dateField(isFrom: true)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('〜'),
                ),
                Expanded(child: _dateField(isFrom: false)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _riyuController,
              decoration: const InputDecoration(
                labelText: '申請理由',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField({required bool isFrom}) {
    final value = isFrom ? _fromDate : _toDate;
    return InkWell(
      onTap: () => _pickDate(isFrom: isFrom),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isFrom ? '開始日' : '終了日',
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value == null ? '' : _formatDate(value),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  List<Widget> _buildCreateBody(SinseiCreateData data) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('保留商品選択',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          OutlinedButton.icon(
            onPressed: () => _toggleAllChecks(data),
            icon: const Icon(Icons.checklist, size: 18),
            label: const Text('一括 ON/OFF'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (data.rentals.isEmpty)
        const _EmptyHoryuRow(label: '申請可能なレンタル商品がありません')
      else
        ...data.rentals.map(_buildRentalTile),
    ];
  }

  Widget _buildRentalTile(SinseiRentalItem item) {
    final checked = _checkedRentalIds.contains(item.rentalId);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: checked,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _checkedRentalIds.add(item.rentalId);
                  } else {
                    _checkedRentalIds.remove(item.rentalId);
                  }
                });
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(item.rentalNo,
                            style: TextStyle(
                                fontSize: 11, color: Colors.indigo.shade800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.syohinName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'レンタル期間: ${item.keiyakuDateFrom} 〜 ${item.keiyakuDateTo ?? '継続中'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  if (item.horyuKikan.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    ...item.horyuKikan.map((k) {
                      final to = k.horyuDateTo ?? '';
                      return Text(
                        '保留期間: ${k.horyuDateFrom} 〜 $to',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoryuOrderTile(SinseiHoryuOrder order) {
    final checked = _checkedRentalIds.contains(order.rentalId);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: checked,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _checkedRentalIds.add(order.rentalId);
                  } else {
                    _checkedRentalIds.remove(order.rentalId);
                  }
                });
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(order.rentalNo,
                            style: TextStyle(
                                fontSize: 11, color: Colors.indigo.shade800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(order.syohinName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'レンタル期間: ${order.keiyakuDateFrom} 〜 ${order.keiyakuDateTo ?? '継続中'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '保留期間: ${order.horyuDateFrom} 〜 ${order.horyuDateTo ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUpdateBody(SinseiCreateData data) {
    return [
      const Text('入院保留中',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (data.onhoryuList.isEmpty)
        const _EmptyHoryuRow(label: '入院保留中の期間はありません')
      else
        ...data.onhoryuList.map(_buildHoryuRow),
      const SizedBox(height: 16),
      const Text('入院保留履歴',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (data.offhoryuList.isEmpty)
        const _EmptyHoryuRow(label: '入院保留履歴はありません')
      else
        ...data.offhoryuList.map(_buildHoryuRow),
      if (_selectedHoryuId != null && data.horyuOrders.isNotEmpty) ...[
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('変更対象商品',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            OutlinedButton.icon(
              onPressed: () => _toggleAllChecks(data),
              icon: const Icon(Icons.checklist, size: 18),
              label: const Text('一括 ON/OFF'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...data.horyuOrders.map(_buildHoryuOrderTile),
      ],
    ];
  }

  Widget _buildHoryuRow(SinseiHoryuRecord r) {
    final selected = _selectedHoryuId == r.rentalHoryuId;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              selected ? Colors.indigo.shade400 : Colors.grey.withOpacity(0.2),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '保留期間: ${r.horyuDateFrom} 〜 ${r.horyuDateTo ?? ''}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '入力日: ${r.inputDate}${r.isPending ? ' / 申請中' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selected ? Colors.indigo : Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _selectHoryuRecord(r),
              child: Text(selected ? '選択中' : '選択'),
            ),
          ],
        ),
      ),
    );
  }
}

/// [primary] を trim して非空ならそれを、そうでなければ [fallback] を trim して返す。
///
/// `isNotEmpty` だけだと空白のみの値を「あり」と判定してしまい、
/// 遷移元から渡された正しい氏名へのフォールバックが効かなくなる。
String _firstNonBlank(String primary, String? fallback) {
  final p = primary.trim();
  if (p.isNotEmpty) return p;
  return (fallback ?? '').trim();
}

/// 入院保留申請 作成画面のヘッダに出す利用者名。ふりがなを併記し敬称を付ける。
///
/// - 氏名 + ふりがな → `さとう ゆうこ（佐藤 雄子） 様`
/// - 氏名のみ        → `佐藤 雄子 様`
/// - ふりがなのみ    → `さとう ゆうこ 様`（`さとう ゆうこ（） 様` を作らない）
/// - 両方空          → 空文字（この画面は従来から空欄表示のため `-` にしない）
///
/// 敬称の付与自体は [formatRiyosyaName] に委譲し、ロジックを一本化する。
/// 画面から切り出してあるのは単体テストで境界を固定するため。
String buildRiyosyaDisplayName({required String name, required String kana}) {
  final n = name.trim();
  final k = kana.trim();
  final combined = n.isEmpty ? k : (k.isEmpty ? n : '$k（$n）');
  return formatRiyosyaName(combined, emptyPlaceholder: '');
}

class _EmptyHoryuRow extends StatelessWidget {
  final String label;
  const _EmptyHoryuRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(label, style: const TextStyle(color: Colors.grey)),
    );
  }
}
