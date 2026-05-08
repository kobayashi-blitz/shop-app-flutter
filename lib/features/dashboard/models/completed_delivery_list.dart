class DeliveryListResponse {
  final String status;
  final String date;
  final int count;
  final List<DeliveryItem> items;

  DeliveryListResponse({
    required this.status,
    required this.date,
    required this.count,
    required this.items,
  });

  factory DeliveryListResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryListResponse(
      status: json['status'] ?? '',
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => DeliveryItem.fromJson(e))
          .toList(),
    );
  }
}

class DeliveryItem {
  final int id;
  final String type;
  final String kubun;
  final String customerName;
  final String deliveryDate;
  final String? deliveryTime;
  final String haisouTantoName;
  final String itemName;
  final String address;

  DeliveryItem({
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

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      kubun: json['kubun'] ?? '',
      customerName: json['customer_name'] ?? '',
      deliveryDate: json['delivery_date'] ?? '',
      deliveryTime: json['delivery_time'],
      haisouTantoName: json['haisou_tanto_name'] ?? '',
      itemName: json['item_name'] ?? '',
      address: json['address'] ?? '',
    );
  }
}