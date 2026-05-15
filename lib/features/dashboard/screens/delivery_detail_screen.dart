import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/haisou_detail.dart';
import '../models/tomorrow_delivery_item.dart';
import '../providers/haisou_detail_provider.dart';

enum DeliveryDetailMode { scheduled, completed }

/// 配送詳細画面。AppBar タイトルだけ `mode` で切替、本体は pcw `haisou/detail` 実 API 駆動。
class DeliveryDetailScreen extends ConsumerWidget {
  final TomorrowDeliveryItem item;
  final DeliveryDetailMode mode;

  const DeliveryDetailScreen({
    super.key,
    required this.item,
    required this.mode,
  });

  bool get _isCompleted => mode == DeliveryDetailMode.completed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(haisouDetailProvider(item.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCompleted ? '配送完了 詳細' : '配送予定 詳細'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildErrorBody(context, ref, e),
        data: (detail) => _buildBody(detail),
      ),
    );
  }

  Widget _buildErrorBody(BuildContext context, WidgetRef ref, Object e) {
    final msg = e is Exception
        ? e.toString().replaceFirst('Exception: ', '')
        : '配送詳細の取得に失敗しました';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(msg,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(haisouDetailProvider(item.id)),
              child: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(HaisouDetail d) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(d),
        const SizedBox(height: 12),
        _buildCustomerCard(d),
        const SizedBox(height: 12),
        _buildItemsCard(d),
        const SizedBox(height: 12),
        _buildTantoCard(d),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 「配送」カード (旧「案件」)。区分バッジ、受付No、納品日時、契約開始日、支店。
  Widget _buildHeaderCard(HaisouDetail d) {
    final isSale = item.type == 'sale';
    final kubunBg = isSale ? Colors.green.shade100 : Colors.blue.shade100;
    final kubunFg = isSale ? Colors.green.shade800 : Colors.blue.shade800;

    final dateTimeText = [
      item.deliveryDate,
      item.deliveryTime,
    ].where((s) => s.isNotEmpty).join(' ');

    return _Section(
      title: '配送',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kubunBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.kubun,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kubunFg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  d.receptionNo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
              label: '納品日時', value: dateTimeText.isEmpty ? '-' : dateTimeText),
          if (d.contractStartDate.isNotEmpty)
            _InfoRow(label: '契約開始日', value: d.contractStartDate),
          _InfoRow(label: '支店', value: d.sitenName.isEmpty ? '-' : d.sitenName),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(HaisouDetail d) {
    return _Section(
      title: '利用者・配送先',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
              label: '利用者', value: d.riyosyaName.isEmpty ? '-' : d.riyosyaName),
          _InfoRow(
              label: '住所',
              value: d.riyosyaAddress.isEmpty ? '-' : d.riyosyaAddress),
          _InfoRow(
              label: '電話番号', value: d.riyosyaTel.isEmpty ? '-' : d.riyosyaTel),
          _InfoRow(
              label: '引渡し場所',
              value: d.placeDelivery.isEmpty ? '-' : d.placeDelivery),
          if (d.hikkosiAddress.isNotEmpty)
            _InfoRow(label: '引越先', value: d.hikkosiAddress),
          if (d.footerComment.isNotEmpty)
            _InfoRow(label: '備考', value: d.footerComment),
        ],
      ),
    );
  }

  Widget _buildItemsCard(HaisouDetail d) {
    return _Section(
      title: '商品',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('商品情報なし', style: TextStyle(color: Colors.grey)),
            )
          else
            ...d.products.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                p.name,
                                if (p.katasiki.isNotEmpty) '(${p.katasiki})',
                              ].join(' '),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (p.rentalNo.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 20),
                          child: Text(
                            'レンタルNo: ${p.rentalNo}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2, left: 20),
                        child: Text(
                          '数量: ${p.qty}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (p.comment.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 20),
                          child: Text(
                            '備考: ${p.comment}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  /// 配送員のみ表示 (代理店担当は削除)。
  Widget _buildTantoCard(HaisouDetail d) {
    return _Section(
      title: '担当',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: '配送員',
            value: d.haisouTantoName.isEmpty ? '-' : d.haisouTantoName,
          ),
        ],
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
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(height: 8),
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
