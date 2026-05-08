import 'package:flutter/material.dart';

import '../models/sinsei_mock_data.dart';

enum SinseiKubun { create, update }

class NyuinHoryuSinseiCreateScreen extends StatefulWidget {
  final String riyosyaName;
  final String? riyosyaKana;

  const NyuinHoryuSinseiCreateScreen({
    super.key,
    required this.riyosyaName,
    this.riyosyaKana,
  });

  @override
  State<NyuinHoryuSinseiCreateScreen> createState() =>
      _NyuinHoryuSinseiCreateScreenState();
}

class _NyuinHoryuSinseiCreateScreenState
    extends State<NyuinHoryuSinseiCreateScreen> {
  SinseiKubun _sinseiKubun = SinseiKubun.create;
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _riyuController = TextEditingController();
  final Set<int> _checkedRentalIds = {
    for (final r in mockRentalItems) r.rentalId,
  };
  int? _selectedHoryuId;

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

  void _toggleAllChecks() {
    setState(() {
      if (_checkedRentalIds.length == mockRentalItems.length) {
        _checkedRentalIds.clear();
      } else {
        _checkedRentalIds
          ..clear()
          ..addAll(mockRentalItems.map((e) => e.rentalId));
      }
    });
  }

  void _selectHoryuRecord(MockHoryuRecord record) {
    setState(() {
      _selectedHoryuId = record.rentalHoryuId;
      _fromDate = _parseDate(record.horyuDateFrom);
      _toDate = _parseDate(record.horyuDateTo);
      _checkedRentalIds
        ..clear()
        ..add(mockRentalItems.first.rentalId); // モック: 該当 1 件
    });
  }

  Future<void> _submit() async {
    if (_fromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('開始日を入力してください')),
      );
      return;
    }
    if (_sinseiKubun == SinseiKubun.create && _checkedRentalIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品は一つ以上、選択してください')),
      );
      return;
    }
    if (_sinseiKubun == SinseiKubun.update && _selectedHoryuId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('変更対象の保留期間を選択してください')),
      );
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
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('申請しました（モック）')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('入院保留申請'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildFormCard(),
          const SizedBox(height: 16),
          if (_sinseiKubun == SinseiKubun.create) ..._buildCreateBody(),
          if (_sinseiKubun == SinseiKubun.update) ..._buildUpdateBody(),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _submit,
            child: const Text('申請する',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('戻る'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
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
              widget.riyosyaKana == null || widget.riyosyaKana!.isEmpty
                  ? widget.riyosyaName
                  : '${widget.riyosyaKana}（${widget.riyosyaName}）',
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
                setState(() {
                  _sinseiKubun = v;
                  _selectedHoryuId = null;
                  if (v == SinseiKubun.create) {
                    _checkedRentalIds
                      ..clear()
                      ..addAll(mockRentalItems.map((e) => e.rentalId));
                  } else {
                    _checkedRentalIds.clear();
                  }
                });
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

  List<Widget> _buildCreateBody() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('保留商品選択',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          OutlinedButton.icon(
            onPressed: _toggleAllChecks,
            icon: const Icon(Icons.checklist, size: 18),
            label: const Text('一括 ON/OFF'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...mockRentalItems.map(_buildRentalTile),
    ];
  }

  Widget _buildRentalTile(MockRentalItem item) {
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
                  if (item.horyuKikanTexts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    ...item.horyuKikanTexts.map((t) => Text(
                          '保留期間: $t',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUpdateBody() {
    final selected = _selectedHoryuId == null
        ? null
        : [...mockOnHoryuRecords, ...mockOffHoryuRecords]
            .where((r) => r.rentalHoryuId == _selectedHoryuId)
            .firstOrNull;
    return [
      const Text('入院保留中',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (mockOnHoryuRecords.isEmpty)
        const _EmptyHoryuRow(label: '入院保留中の期間はありません')
      else
        ...mockOnHoryuRecords.map(_buildHoryuRow),
      const SizedBox(height: 16),
      const Text('入院保留履歴',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (mockOffHoryuRecords.isEmpty)
        const _EmptyHoryuRow(label: '入院保留履歴はありません')
      else
        ...mockOffHoryuRecords.map(_buildHoryuRow),
      if (selected != null) ...[
        const SizedBox(height: 16),
        const Text('変更対象商品',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildRentalTile(mockRentalItems.first),
      ],
    ];
  }

  Widget _buildHoryuRow(MockHoryuRecord r) {
    final selected = _selectedHoryuId == r.rentalHoryuId;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? Colors.indigo.shade400
              : Colors.grey.withOpacity(0.2),
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
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selected ? Colors.indigo : Colors.red.shade700,
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
