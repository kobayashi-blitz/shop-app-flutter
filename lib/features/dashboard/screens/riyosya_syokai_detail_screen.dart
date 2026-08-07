import 'package:flutter/material.dart';

import '../../../core/utils/display_format.dart';
import '../models/riyosya_syokai_item.dart';

/// 利用者照会 詳細画面。
///
/// 一覧画面 (`RiyosyaSyokaiListScreen`) の利用者カードタップで遷移。
/// 引数 `items` には同一 `riyosyaId` の商品行が DESC で並んでおり、
/// `items.first` から利用者基本情報を取り出す。追加 API コールはしない。
class RiyosyaSyokaiDetailScreen extends StatelessWidget {
  final List<RiyosyaSyokaiItem> items;
  const RiyosyaSyokaiDetailScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final head = items.first;
    // 敬称の付与はヘルパーに一本化する (以前はここだけ手書きだった)。
    final displayName =
        formatRiyosyaName(head.riyosyaName, emptyPlaceholder: '(氏名未登録)');
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBasicInfoCard(head),
          const SizedBox(height: 16),
          _buildHistoryCard(items),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(RiyosyaSyokaiItem r) {
    final fullAddress = [
      if (r.riyosyaPost.isNotEmpty) '〒${r.riyosyaPost}',
      [r.riyosyaPref, r.riyosyaJyusyo1, r.riyosyaJyusyo2]
          .where((e) => e.isNotEmpty)
          .join(''),
    ].where((e) => e.isNotEmpty).join('\n');

    final age = _calcAge(r.riyosyaBirthday);
    final birthdayValue = r.riyosyaBirthday.isEmpty
        ? '-'
        : (age != null ? '${r.riyosyaBirthday}（$age 歳）' : r.riyosyaBirthday);

    final kaigoPeriod = (r.riyosyaKaigoKikanFrom.isEmpty &&
            r.riyosyaKaigoKikanTo.isEmpty)
        ? ''
        : '${r.riyosyaKaigoKikanFrom.isEmpty ? '-' : r.riyosyaKaigoKikanFrom} 〜 '
            '${r.riyosyaKaigoKikanTo.isEmpty ? '-' : r.riyosyaKaigoKikanTo}';
    final kaigoValue = [
      if (r.riyosyaKaigoRank.isNotEmpty) r.riyosyaKaigoRank,
      if (kaigoPeriod.isNotEmpty) kaigoPeriod,
    ].join('  ');

    return _Section(
      title: '利用者情報',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.riyosyaKana.isNotEmpty)
            _InfoRow(label: 'ふりがな', value: r.riyosyaKana),
          _InfoRow(
            label: '性別',
            value: r.riyosyaGender.isEmpty ? '-' : r.riyosyaGender,
          ),
          _InfoRow(label: '生年月日', value: birthdayValue),
          if (fullAddress.isNotEmpty) _InfoRow(label: '住所', value: fullAddress),
          _InfoRow(
              label: '電話番号', value: r.riyosyaTel.isEmpty ? '-' : r.riyosyaTel),
          if (kaigoValue.isNotEmpty) _InfoRow(label: '要介護度', value: kaigoValue),
          if (r.riyosyaCareMan.isNotEmpty)
            _InfoRow(label: 'ケアマネ', value: r.riyosyaCareMan),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(List<RiyosyaSyokaiItem> items) {
    return _Section(
      title: '契約履歴（${items.length} 件）',
      child: Column(
        children: items.map(_buildHistoryRow).toList(),
      ),
    );
  }

  Widget _buildHistoryRow(RiyosyaSyokaiItem it) {
    final period = it.keiyakuDateTo.isEmpty
        ? '${it.keiyakuDateFrom} 〜'
        : '${it.keiyakuDateFrom} 〜 ${it.keiyakuDateTo}';
    final isActive = it.isActive;
    final chipBg = isActive ? Colors.blue.shade50 : Colors.grey.shade200;
    final chipFg = isActive ? Colors.blue.shade800 : Colors.grey.shade800;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.inventory_2, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.syohinName, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  period,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isActive ? '契約中' : '過去',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: chipFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `YYYY/MM/DD` 形式の生年月日から年齢を算出。失敗時 null。
  int? _calcAge(String birthday) {
    if (birthday.isEmpty) return null;
    final parts = birthday.split('/');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    final now = DateTime.now();
    var age = now.year - y;
    if (now.month < m || (now.month == m && now.day < d)) age--;
    if (age < 0 || age > 150) return null;
    return age;
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
