import 'package:flutter/material.dart';

import '../models/tomorrow_delivery_item.dart';
import '../screens/delivery_detail_screen.dart';

/// 配送予定/配送完了一覧で共通のカード描画。
///
/// バッジ色は kubun=3 (汎用配送) → 緑、それ以外 (レンタル/返却/預入) → 青。
/// タップで [DeliveryDetailScreen] に遷移。呼出側で `detailMode` を指定して
/// 配送予定 (scheduled) / 配送完了 (completed) を切り替える。
///
/// 一覧では「担当配送員」は表示せず、詳細画面で表示する。
/// 利用者住所も一覧では表示せず、代わりに「引渡し場所」を表示する。
class DeliveryListTile extends StatelessWidget {
  final TomorrowDeliveryItem item;
  final DeliveryDetailMode detailMode;

  const DeliveryListTile({
    super.key,
    required this.item,
    required this.detailMode,
  });

  @override
  Widget build(BuildContext context) {
    final isSale = item.type == 'sale';
    final badgeBg = isSale ? Colors.green.shade100 : Colors.blue.shade100;
    final badgeFg = isSale ? Colors.green.shade800 : Colors.blue.shade800;

    final dateTimeText = [
      item.deliveryDate,
      item.deliveryTime,
    ].where((s) => s.isNotEmpty).join(' ');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeliveryDetailScreen(
              item: item,
              mode: detailMode,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上段: 区分バッジ + 日時
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.kubun,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeFg,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateTimeText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 利用者名
            Text(
              item.customerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // 引渡し場所
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.placeDelivery.isEmpty ? '-' : item.placeDelivery,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 商品名
            Text(
              item.itemName,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
