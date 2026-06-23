import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/features/dashboard/models/haisou_detail.dart';

void main() {
  // fromJson に必要な最小限の detail。その他のキーは fromJson 側で '' 既定。
  Map<String, dynamic> baseDetail() => {
        'haisou_id': 1,
        'kubun': '1',
        'reception_no': 'R-001',
        'haisou_tanto_name': '山田太郎',
      };

  group('HaisouDetail.fromJson - 配送員 tel/photo', () {
    test('tel / photo_url が値ありで正しくパースされる', () {
      final json = baseDetail()
        ..['haisou_tanto_tel'] = '090-1234-5678'
        ..['haisou_tanto_photo_url'] =
            'https://example.com/storage/images/syain/abc.jpg';

      final d = HaisouDetail.fromJson(json, const []);

      expect(d.haisouTantoTel, '090-1234-5678');
      expect(d.haisouTantoPhotoUrl,
          'https://example.com/storage/images/syain/abc.jpg');
    });

    test('キー無しのとき空文字になる', () {
      final d = HaisouDetail.fromJson(baseDetail(), const []);

      expect(d.haisouTantoTel, '');
      expect(d.haisouTantoPhotoUrl, '');
    });

    test('null のとき空文字になる（pcw 未登録時の契約）', () {
      final json = baseDetail()
        ..['haisou_tanto_tel'] = null
        ..['haisou_tanto_photo_url'] = null;

      final d = HaisouDetail.fromJson(json, const []);

      expect(d.haisouTantoTel, '');
      expect(d.haisouTantoPhotoUrl, '');
    });

    test('電話番号が int で来ても文字列化される（?.toString() の回帰防止）', () {
      final json = baseDetail()..['haisou_tanto_tel'] = 9012345678;

      final d = HaisouDetail.fromJson(json, const []);

      expect(d.haisouTantoTel, '9012345678');
    });
  });
}
