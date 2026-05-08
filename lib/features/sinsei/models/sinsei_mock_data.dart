/// 入院保留申請画面のモックデータ。
/// pcw 側 SinseiNyuinhoryuController@create の戻り値を念頭に構造を合わせる。
class MockRentalItem {
  final int rentalId;
  final String rentalNo;
  final String syohinName;
  final String keiyakuDateFrom;
  final String? keiyakuDateTo;
  final List<String> horyuKikanTexts;

  const MockRentalItem({
    required this.rentalId,
    required this.rentalNo,
    required this.syohinName,
    required this.keiyakuDateFrom,
    this.keiyakuDateTo,
    this.horyuKikanTexts = const [],
  });
}

class MockHoryuRecord {
  final int rentalHoryuId;
  final String horyuDateFrom;
  final String? horyuDateTo;
  final String inputDate;
  final bool isPending;

  const MockHoryuRecord({
    required this.rentalHoryuId,
    required this.horyuDateFrom,
    this.horyuDateTo,
    required this.inputDate,
    this.isPending = false,
  });
}

const mockRentalItems = <MockRentalItem>[
  MockRentalItem(
    rentalId: 1001,
    rentalNo: '0010-0001',
    syohinName: '電動ベッド 3M (KQ-7733)',
    keiyakuDateFrom: '2025/12/01',
    horyuKikanTexts: ['2026/01/05 ～ 2026/01/20'],
  ),
  MockRentalItem(
    rentalId: 1002,
    rentalNo: '0010-0002',
    syohinName: 'サイドレール 2本セット',
    keiyakuDateFrom: '2025/12/01',
  ),
  MockRentalItem(
    rentalId: 1003,
    rentalNo: '0010-0003',
    syohinName: 'エアマット (ビッグセル)',
    keiyakuDateFrom: '2026/02/14',
  ),
];

const mockOnHoryuRecords = <MockHoryuRecord>[
  MockHoryuRecord(
    rentalHoryuId: 9001,
    horyuDateFrom: '2026/04/12',
    inputDate: '2026/04/10',
    isPending: false,
  ),
];

const mockOffHoryuRecords = <MockHoryuRecord>[
  MockHoryuRecord(
    rentalHoryuId: 9000,
    horyuDateFrom: '2026/01/05',
    horyuDateTo: '2026/01/20',
    inputDate: '2026/01/04',
    isPending: false,
  ),
];
