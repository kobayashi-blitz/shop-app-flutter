import 'package:flutter/material.dart';

import '../models/tomorrow_delivery_item.dart';

// 配送予定 / 配送完了 詳細画面（共通）
// MOCK: pcw 側の納品伝票相当の情報をダミーで描画。実装後に差し戻す。
enum DeliveryDetailMode { scheduled, completed }

class DeliveryDetailScreen extends StatelessWidget {
  final TomorrowDeliveryItem item;
  final DeliveryDetailMode mode;

  const DeliveryDetailScreen({
    super.key,
    required this.item,
    required this.mode,
  });

  bool get _isCompleted => mode == DeliveryDetailMode.completed;

  @override
  Widget build(BuildContext context) {
    final detail = _MockDetail.forId(item.id, item, _isCompleted);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCompleted ? '配送完了 詳細' : '配送予定 詳細'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(detail),
          const SizedBox(height: 12),
          _buildCustomerCard(detail),
          const SizedBox(height: 12),
          _buildItemsCard(detail),
          const SizedBox(height: 12),
          _buildStatusCard(detail),
          const SizedBox(height: 12),
          _buildTantoCard(detail),
          if (_isCompleted) ...[
            const SizedBox(height: 12),
            _buildCompletionCard(detail),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(_MockDetail d) {
    final kubunBg =
        item.type == 'sale' ? Colors.green.shade100 : Colors.blue.shade100;
    final kubunFg =
        item.type == 'sale' ? Colors.green.shade800 : Colors.blue.shade800;

    return _Section(
      title: '案件',
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
              Text(
                d.receptionNo,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: '納品日', value: item.deliveryDate),
          _InfoRow(
              label: '配送時間',
              value: item.deliveryTime.isEmpty ? '時間未定' : item.deliveryTime),
          _InfoRow(label: '契約開始日', value: d.contractStartDate),
          _InfoRow(label: '支店', value: d.sitenName),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(_MockDetail d) {
    return _Section(
      title: '利用者・配送先',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: '利用者名', value: item.customerName),
          _InfoRow(label: '住所', value: item.address),
          _InfoRow(label: '電話番号', value: d.customerPhone),
          _InfoRow(label: '引渡場所', value: d.placeDelivery),
          if (d.hikkosiAddress.isNotEmpty)
            _InfoRow(label: '引越先', value: d.hikkosiAddress),
          if (d.footerComment.isNotEmpty)
            _InfoRow(label: '備考', value: d.footerComment),
        ],
      ),
    );
  }

  Widget _buildItemsCard(_MockDetail d) {
    return _Section(
      title: '商品',
      child: Column(
        children: d.products.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2,
                        size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${p.name}（${p.katasiki}）',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (p.tool)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '工具',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 26, top: 2),
                  child: Row(
                    children: [
                      if (p.rentalNo.isNotEmpty) ...[
                        Text('レンタルNo: ${p.rentalNo}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(width: 12),
                      ],
                      Text('数量: ${p.qty}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (p.comment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 26, top: 2),
                    child: Text(
                      '備考: ${p.comment}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusCard(_MockDetail d) {
    final delivered = d.isDelivered;
    final color = delivered ? Colors.green.shade700 : Colors.orange.shade800;
    final bg = delivered ? Colors.green.shade50 : Colors.orange.shade50;
    return _Section(
      title: '進捗',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              delivered ? Icons.check_circle : Icons.local_shipping,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              delivered ? '納品済' : '未納品',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTantoCard(_MockDetail d) {
    return _Section(
      title: '担当者',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: '代理店担当', value: d.agentTantoName),
          _InfoRow(label: '配送員', value: item.haisouTantoName),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(_MockDetail d) {
    return _Section(
      title: '完了情報',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: '完了日時', value: d.completedAt ?? '-'),
          _InfoRow(label: '受領確認者', value: d.acceptedBy ?? '-'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text('サイン',
                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: d.signatureCaptured
                        ? Colors.green.shade50
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        d.signatureCaptured
                            ? Icons.check_circle
                            : Icons.pending,
                        size: 14,
                        color: d.signatureCaptured
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        d.signatureCaptured ? '取得済' : '未取得',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: d.signatureCaptured
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _MockDetail {
  final String receptionNo;
  final String contractStartDate;
  final String sitenName;
  final String customerPhone;
  final String placeDelivery;
  final String hikkosiAddress;
  final String footerComment;
  final String agentTantoName;
  final List<_MockProduct> products;
  final bool isDelivered;
  final String? completedAt;
  final String? acceptedBy;
  final bool signatureCaptured;

  const _MockDetail({
    required this.receptionNo,
    required this.contractStartDate,
    required this.sitenName,
    required this.customerPhone,
    required this.placeDelivery,
    required this.hikkosiAddress,
    required this.footerComment,
    required this.agentTantoName,
    required this.products,
    required this.isDelivered,
    this.completedAt,
    this.acceptedBy,
    this.signatureCaptured = false,
  });

  static _MockDetail forId(int id, TomorrowDeliveryItem item, bool completed) {
    final base = _details[id];
    if (base != null) {
      if (completed) {
        return _MockDetail(
          receptionNo: base.receptionNo,
          contractStartDate: base.contractStartDate,
          sitenName: base.sitenName,
          customerPhone: base.customerPhone,
          placeDelivery: base.placeDelivery,
          hikkosiAddress: base.hikkosiAddress,
          footerComment: base.footerComment,
          agentTantoName: base.agentTantoName,
          products: base.products,
          isDelivered: true,
          completedAt: '${item.deliveryDate} ${item.deliveryTime}',
          acceptedBy: '${item.customerName.replaceAll(' 様', '')}（本人）',
          signatureCaptured: id % 2 == 1,
        );
      }
      return base;
    }
    // フォールバック: 未登録 id でも壊れないように
    return _MockDetail(
      receptionNo: '受付No.${id.toString().padLeft(6, '0')}',
      contractStartDate: item.deliveryDate,
      sitenName: '本店',
      customerPhone: '06-0000-0000',
      placeDelivery: '自宅',
      hikkosiAddress: '',
      footerComment: '',
      agentTantoName: 'テスト担当者',
      products: [
        _MockProduct(
          name: item.itemName,
          katasiki: '-',
          rentalNo: '',
          qty: 1,
          comment: '',
          tool: false,
        ),
      ],
      isDelivered: completed,
    );
  }

  static final Map<int, _MockDetail> _details = {
    1: const _MockDetail(
      receptionNo: '受付No.000123 / 伝票No.D-2026-0428-001',
      contractStartDate: '2026/04/28',
      sitenName: '梅田支店',
      customerPhone: '06-1234-5678',
      placeDelivery: '自宅 1F リビング',
      hikkosiAddress: '',
      footerComment: '玄関段差あり、台車推奨',
      agentTantoName: 'テスト担当者',
      products: [
        _MockProduct(
          name: '電動ベッド 3M',
          katasiki: 'KQ-7733',
          rentalNo: 'R-088172',
          qty: 1,
          comment: 'マット込み',
          tool: true,
        ),
        _MockProduct(
          name: 'サイドレール',
          katasiki: 'KS-156Q',
          rentalNo: 'R-088173',
          qty: 2,
          comment: '',
          tool: false,
        ),
        _MockProduct(
          name: 'ベッド用テーブル',
          katasiki: 'KF-832',
          rentalNo: 'R-088174',
          qty: 1,
          comment: '',
          tool: false,
        ),
      ],
      isDelivered: false,
    ),
    2: const _MockDetail(
      receptionNo: '受付No.000124 / 伝票No.D-2026-0428-002',
      contractStartDate: '2026/04/28',
      sitenName: '梅田支店',
      customerPhone: '06-2345-6789',
      placeDelivery: '自宅',
      hikkosiAddress: '',
      footerComment: '',
      agentTantoName: 'テスト担当者',
      products: [
        _MockProduct(
          name: '車椅子 自走式',
          katasiki: 'NA-516A',
          rentalNo: 'R-088201',
          qty: 1,
          comment: 'クッション付き',
          tool: false,
        ),
      ],
      isDelivered: false,
    ),
    3: const _MockDetail(
      receptionNo: '受付No.000125 / 伝票No.S-2026-0428-001',
      contractStartDate: '2026/04/28',
      sitenName: '梅田支店',
      customerPhone: '06-3456-7890',
      placeDelivery: '訪問介護センター窓口',
      hikkosiAddress: '',
      footerComment: '法人請求',
      agentTantoName: 'テスト担当者',
      products: [
        _MockProduct(
          name: '床ずれ防止クッション',
          katasiki: 'CK-200',
          rentalNo: '',
          qty: 2,
          comment: '販売',
          tool: false,
        ),
      ],
      isDelivered: false,
    ),
    4: const _MockDetail(
      receptionNo: '受付No.000126 / 伝票No.D-2026-0428-003',
      contractStartDate: '2026/04/28',
      sitenName: '北浜支店',
      customerPhone: '06-4567-8901',
      placeDelivery: '自宅',
      hikkosiAddress: '',
      footerComment: '時間未定（事前 TEL）',
      agentTantoName: 'テスト担当者',
      products: [
        _MockProduct(
          name: '歩行器（シルバーカート）',
          katasiki: 'SC-310',
          rentalNo: 'R-088260',
          qty: 1,
          comment: '',
          tool: false,
        ),
      ],
      isDelivered: false,
    ),
    5: const _MockDetail(
      receptionNo: '受付No.000127 / 伝票No.D-2026-0428-004',
      contractStartDate: '2026/04/28',
      sitenName: '北浜支店',
      customerPhone: '06-5678-9012',
      placeDelivery: '自宅 2F 寝室',
      hikkosiAddress: '〒553-0003 大阪府大阪市福島区福島 5-4-1',
      footerComment: '4/30 引越予定',
      agentTantoName: 'テスト担当者',
      products: [
        _MockProduct(
          name: 'エアマット（ビッグセル）',
          katasiki: 'BC-400',
          rentalNo: 'R-088301',
          qty: 1,
          comment: 'コンプレッサ含む',
          tool: false,
        ),
      ],
      isDelivered: false,
    ),
    11: const _MockDetail(
      receptionNo: '受付No.000110 / 伝票No.D-2026-0427-011',
      contractStartDate: '2026/04/27',
      sitenName: '梅田支店',
      customerPhone: '06-1111-2222',
      placeDelivery: '自宅 1F',
      hikkosiAddress: '',
      footerComment: '',
      agentTantoName: 'テスト担当者',
      products: [
        _MockProduct(
          name: '電動ベッド 3M',
          katasiki: 'KQ-7733',
          rentalNo: 'R-087990',
          qty: 1,
          comment: '',
          tool: true,
        ),
      ],
      isDelivered: true,
    ),
    12: const _MockDetail(
      receptionNo: '受付No.000111 / 伝票No.D-2026-0427-012',
      contractStartDate: '2026/04/27',
      sitenName: '梅田支店',
      customerPhone: '06-3333-4444',
      placeDelivery: '自宅',
      hikkosiAddress: '',
      footerComment: '',
      agentTantoName: 'テスト担当者',
      products: [
        _MockProduct(
          name: 'サイドレール',
          katasiki: 'KS-156Q',
          rentalNo: 'R-087991',
          qty: 2,
          comment: '',
          tool: false,
        ),
      ],
      isDelivered: true,
    ),
    13: const _MockDetail(
      receptionNo: '受付No.000112 / 伝票No.S-2026-0427-013',
      contractStartDate: '2026/04/27',
      sitenName: '北浜支店',
      customerPhone: '06-5555-6666',
      placeDelivery: '自宅',
      hikkosiAddress: '',
      footerComment: '',
      agentTantoName: 'テスト担当者',
      products: [
        _MockProduct(
          name: '杖（折りたたみ式）',
          katasiki: 'TS-110',
          rentalNo: '',
          qty: 1,
          comment: '販売',
          tool: false,
        ),
      ],
      isDelivered: true,
    ),
    14: const _MockDetail(
      receptionNo: '受付No.000113 / 伝票No.D-2026-0427-014',
      contractStartDate: '2026/04/27',
      sitenName: '北浜支店',
      customerPhone: '06-7777-8888',
      placeDelivery: '自宅 1F',
      hikkosiAddress: '',
      footerComment: '',
      agentTantoName: 'テスト担当者',
      products: [
        _MockProduct(
          name: '車椅子 自走式',
          katasiki: 'NA-516A',
          rentalNo: 'R-087992',
          qty: 1,
          comment: '',
          tool: false,
        ),
      ],
      isDelivered: true,
    ),
  };
}

class _MockProduct {
  final String name;
  final String katasiki;
  final String rentalNo;
  final int qty;
  final String comment;
  final bool tool;
  const _MockProduct({
    required this.name,
    required this.katasiki,
    required this.rentalNo,
    required this.qty,
    required this.comment,
    required this.tool,
  });
}
