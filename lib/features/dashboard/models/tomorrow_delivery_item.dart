class TomorrowDeliveryItem {
  final int id;
  final String type;              // rental / sale
  final String kubun;             // レンタル / 販売
  final String customerName;      // 利用者名
  final String deliveryDate;      // 納品希望日 (YYYY/MM/DD)
  final String deliveryTime;      // 納品時間（空文字の場合もあり）
  final String haisouTantoName;   // 配送担当者
  final String itemName;          // 商品名
  final String address;           // 納品先住所

  TomorrowDeliveryItem({
    required this.id,
    required this.type,
    required this.kubun,
    required this.customerName,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.haisouTantoName,
    required this.itemName,
    required this.address,
  });

  factory TomorrowDeliveryItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];

    return TomorrowDeliveryItem(
      id: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      type: (json['type'] ?? '') as String,
      kubun: (json['kubun'] ?? '') as String,
      customerName: (json['customer_name'] ?? '') as String,
      deliveryDate: (json['delivery_date'] ?? '') as String,
      deliveryTime: (json['delivery_time'] ?? '') as String,
      haisouTantoName: (json['haisou_tanto_name'] ?? '') as String,
      itemName: (json['item_name'] ?? '') as String,
      address: (json['address'] ?? '') as String,
    );
  }
}