import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/features/dashboard/models/tomorrow_delivery_item.dart';

void main() {
  // pcw `haisouyotei/syosai` / `haisou-kanryo/syosai` の 1 行（受付単位, PR #3036）。
  Map<String, dynamic> row({
    dynamic primaryId = 711304,
    dynamic haisouId = 118637,
    String kubun = '1',
    String riyosyaName = '伊庭 清枝',
  }) =>
      {
        'primary_id': primaryId, // 受付ID (hs3.tbl_id)
        'haisou_id': haisouId, // 配送ID (hs1.haisou_id)
        'kubun': kubun,
        'riyosya_name': riyosyaName,
        'kibou_date': '2026/07/18',
        'kibou_time': '18:00',
        'syohin_name': '★CRT-SG-5(自走式)',
        'place_delivery': 'センター渡し',
      };

  group('TomorrowDeliveryItem.fromJson - 受付単位マッピング', () {
    test('id には primary_id(受付ID) が入る（haisou_id ではない）', () {
      final item = TomorrowDeliveryItem.fromJson(row());
      // カードキー / 詳細 API の order_id に流れる値。
      expect(item.id, 711304);
      expect(item.id, isNot(118637));
    });

    test('haisouId には haisou_id(配送ID) が入る', () {
      final item = TomorrowDeliveryItem.fromJson(row());
      expect(item.haisouId, 118637);
    });

    test('kubunCode は生コード、kubun は日本語ラベルになる', () {
      final item = TomorrowDeliveryItem.fromJson(row(kubun: '1'));
      // 詳細 API の kubun には生コードを送るため、ラベルと分離して保持する。
      expect(item.kubunCode, '1');
      expect(item.kubun, 'レンタル');
    });

    test('type は kubun=3(汎用配送) のみ sale、それ以外は rental', () {
      expect(TomorrowDeliveryItem.fromJson(row(kubun: '3')).type, 'sale');
      expect(TomorrowDeliveryItem.fromJson(row(kubun: '1')).type, 'rental');
      expect(TomorrowDeliveryItem.fromJson(row(kubun: '2')).type, 'rental');
      expect(TomorrowDeliveryItem.fromJson(row(kubun: '4')).type, 'rental');
      expect(TomorrowDeliveryItem.fromJson(row(kubun: '5')).type, 'rental');
    });

    test('数値文字列の primary_id / haisou_id も int に変換される', () {
      final item = TomorrowDeliveryItem.fromJson(
        row(primaryId: '711305', haisouId: '118637'),
      );
      expect(item.id, 711305);
      expect(item.haisouId, 118637);
    });

    test('欠損・不正な primary_id / haisou_id は 0 になる', () {
      final item = TomorrowDeliveryItem.fromJson(
        row(primaryId: null, haisouId: 'x'),
      );
      // 0 は詳細画面側でガードされ、先頭受付フォールバックを防ぐ。
      expect(item.id, 0);
      expect(item.haisouId, 0);
    });

    test('合積み配送: 同一 haisou_id・異なる primary_id は別 id を持つ（カードキー分離）', () {
      final a = TomorrowDeliveryItem.fromJson(
        row(primaryId: 711304, haisouId: 118637, riyosyaName: '伊庭 清枝'),
      );
      final b = TomorrowDeliveryItem.fromJson(
        row(primaryId: 711305, haisouId: 118637, riyosyaName: '乾 紀美子'),
      );
      expect(a.haisouId, b.haisouId); // 同じ配送
      expect(a.id, isNot(b.id)); // 別受付 → 別カードキー
    });
  });
}
