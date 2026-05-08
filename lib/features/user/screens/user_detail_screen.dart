import 'package:flutter/material.dart';

// SAP-13: お客様画面に入院保留 開始/完了 を切り替える機能
// MOCK: API 未実装のためダミーデータで描画。トグルはローカル状態のみ。
class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isOnHold = false;
  DateTime _effectiveDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();

  static const _mockRentalItems = <_RentalItem>[
    _RentalItem(name: '電動ベッド 3M (KQ-7733)', startDate: '2025/12/01'),
    _RentalItem(name: 'サイドレール 2本セット', startDate: '2025/12/01'),
    _RentalItem(name: 'エアマット (ビッグセル)', startDate: '2026/02/14'),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _effectiveDate = picked);
    }
  }

  void _toggleHold() {
    final action = _isOnHold ? '入院保留を完了' : '入院保留を開始';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action),
        content: Text(
          '${_formatDate(_effectiveDate)}付で「$action」します。よろしいですか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _isOnHold = !_isOnHold);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$action しました（モック）')),
              );
            },
            child: const Text('実行'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お客様詳細'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBasicInfoCard(),
          const SizedBox(height: 16),
          _buildHoldCard(),
          const SizedBox(height: 16),
          _buildRentalItemsCard(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return _Section(
      title: 'お客様情報',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _InfoRow(label: '氏名', value: '山田 太郎 様'),
          _InfoRow(label: 'ふりがな', value: 'やまだ たろう'),
          _InfoRow(label: '住所', value: '〒530-0001 大阪府大阪市北区梅田 1-2-3'),
          _InfoRow(label: '電話番号', value: '06-1234-5678'),
          _InfoRow(label: '契約日', value: '2025/12/01'),
          _InfoRow(label: '担当者', value: 'テスト担当者'),
        ],
      ),
    );
  }

  Widget _buildHoldCard() {
    final stateColor =
        _isOnHold ? Colors.amber.shade800 : Colors.green.shade700;
    final stateBg = _isOnHold ? Colors.amber.shade50 : Colors.green.shade50;

    return _Section(
      title: '入院保留',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: stateBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: stateColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _isOnHold ? Icons.pause_circle : Icons.check_circle,
                  color: stateColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnHold ? '入院保留中' : '通常（保留なし）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: stateColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isOnHold ? '完了日' : '開始日',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_formatDate(_effectiveDate)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '備考（任意）',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleHold,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isOnHold ? Colors.green.shade700 : Colors.amber.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _isOnHold ? '入院保留を完了する' : '入院保留を開始する',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalItemsCard() {
    return _Section(
      title: 'レンタル中の商品',
      child: Column(
        children: _mockRentalItems.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.inventory_2, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 14)),
                      Text(
                        'レンタル開始: ${item.startDate}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
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

class _RentalItem {
  final String name;
  final String startDate;
  const _RentalItem({required this.name, required this.startDate});
}
