import '../../../core/api/api_client.dart';
import '../models/tomorrow_delivery_item.dart';

class TomorrowDeliveryService {
  final ApiClient _apiClient;

  TomorrowDeliveryService(this._apiClient);

  // MOCK: pcw 側に対応 API 未実装のためデザイン確認用ダミーデータを返す。実装後に差し戻す。
  Future<List<TomorrowDeliveryItem>> fetchTomorrowList({
    required int shopId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dateText =
        '${tomorrow.year}/${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.day.toString().padLeft(2, '0')}';

    return [
      TomorrowDeliveryItem(
        id: 1,
        type: 'rental',
        kubun: 'レンタル',
        customerName: '山田 太郎 様',
        deliveryDate: dateText,
        deliveryTime: '09:30 - 10:30',
        haisouTantoName: '中村 配送員',
        itemName: '電動ベッド 3M (KQ-7733) ほか 2 点',
        address: '〒530-0001 大阪府大阪市北区梅田 1-2-3',
      ),
      TomorrowDeliveryItem(
        id: 2,
        type: 'rental',
        kubun: 'レンタル',
        customerName: '佐藤 花子 様',
        deliveryDate: dateText,
        deliveryTime: '11:00 - 12:00',
        haisouTantoName: '中村 配送員',
        itemName: '車椅子 自走式 (NA-516A)',
        address: '〒540-0008 大阪府大阪市中央区大手前 4-5-6',
      ),
      TomorrowDeliveryItem(
        id: 3,
        type: 'sale',
        kubun: '販売',
        customerName: '鈴木 一郎 様',
        deliveryDate: dateText,
        deliveryTime: '14:00 - 15:00',
        haisouTantoName: '吉田 配送員',
        itemName: '床ずれ防止クッション 2 点',
        address: '〒541-0041 大阪府大阪市中央区北浜 2-1-10',
      ),
      TomorrowDeliveryItem(
        id: 4,
        type: 'rental',
        kubun: 'レンタル',
        customerName: '田中 美和 様',
        deliveryDate: dateText,
        deliveryTime: '',
        haisouTantoName: '吉田 配送員',
        itemName: '歩行器 (シルバーカート)',
        address: '〒550-0014 大阪府大阪市西区北堀江 3-7-2',
      ),
      TomorrowDeliveryItem(
        id: 5,
        type: 'rental',
        kubun: 'レンタル',
        customerName: '高橋 健 様',
        deliveryDate: dateText,
        deliveryTime: '16:30 - 17:30',
        haisouTantoName: '中村 配送員',
        itemName: 'エアマット (ビッグセル)',
        address: '〒553-0003 大阪府大阪市福島区福島 5-4-1',
      ),
    ];
  }

  // MOCK: 同上（本日完了側）。実装後に差し戻す。
  Future<List<TomorrowDeliveryItem>> fetchTodayCompletedList({
    required int shopId,
    String? targetDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final today = DateTime.now();
    final dateText =
        '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';

    return [
      TomorrowDeliveryItem(
        id: 11,
        type: 'rental',
        kubun: 'レンタル',
        customerName: '伊藤 良子 様',
        deliveryDate: dateText,
        deliveryTime: '09:00',
        haisouTantoName: '中村 配送員',
        itemName: '電動ベッド 3M (KQ-7733)',
        address: '〒531-0072 大阪府大阪市北区豊崎 3-2-1',
      ),
      TomorrowDeliveryItem(
        id: 12,
        type: 'rental',
        kubun: 'レンタル',
        customerName: '渡辺 隆 様',
        deliveryDate: dateText,
        deliveryTime: '10:45',
        haisouTantoName: '吉田 配送員',
        itemName: 'サイドレール 2 本セット',
        address: '〒532-0011 大阪府大阪市淀川区西中島 4-1-1',
      ),
      TomorrowDeliveryItem(
        id: 13,
        type: 'sale',
        kubun: '販売',
        customerName: '小林 千夏 様',
        deliveryDate: dateText,
        deliveryTime: '13:20',
        haisouTantoName: '中村 配送員',
        itemName: '杖 (折りたたみ式)',
        address: '〒536-0014 大阪府大阪市城東区鶴見 2-3-4',
      ),
      TomorrowDeliveryItem(
        id: 14,
        type: 'rental',
        kubun: 'レンタル',
        customerName: '中島 進 様',
        deliveryDate: dateText,
        deliveryTime: '15:10',
        haisouTantoName: '吉田 配送員',
        itemName: '車椅子 自走式 (NA-516A)',
        address: '〒545-0011 大阪府大阪市阿倍野区昭和町 1-5-2',
      ),
    ];
  }
}
