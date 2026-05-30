class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    this.statusDisplay,
    this.storeName,
    this.warehouseName,
    this.createdAt,
    this.paymentStatus,
    this.paymentStatusDisplay,
    this.paymentMethod,
    this.paymentMethodDisplay,
    this.details = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '') ?? 0,
      statusDisplay: json['status_display']?.toString(),
      storeName: json['store_name']?.toString(),
      warehouseName: json['warehouse_name']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      paymentStatus: json['payment_status']?.toString(),
      paymentStatusDisplay: json['payment_status_display']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentMethodDisplay: json['payment_method_display']?.toString(),
      details: _parseDetails(json['details']),
    );
  }

  final int id;
  final String status;
  final double totalAmount;
  final String? statusDisplay;
  final String? storeName;
  final String? warehouseName;
  final DateTime? createdAt;
  final String? paymentStatus;
  final String? paymentStatusDisplay;
  final String? paymentMethod;
  final String? paymentMethodDisplay;
  final List<OrderDetailModel> details;

  static List<OrderDetailModel> _parseDetails(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => OrderDetailModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class OrderDetailModel {
  const OrderDetailModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      productId: int.tryParse(json['product']?.toString() ?? '') ?? 0,
      productName: json['product_name']?.toString() ?? 'Producto',
      productSku: json['product_sku']?.toString() ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '') ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '') ?? 0,
    );
  }

  final int id;
  final int productId;
  final String productName;
  final String productSku;
  final double quantity;
  final double unitPrice;
  final double subtotal;
}
