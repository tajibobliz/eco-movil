import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../cart/data/cart_item_model.dart';
import 'order_model.dart';

class OrdersService {
  OrdersService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  static const defaultStoreId = 1;
  static const defaultWarehouseId = 1;

  final Dio _dio;

  Future<List<OrderModel>> getMyOrders() async {
    final response = await _dio.get<dynamic>('/sales/orders/mine/');
    return _toList(response.data)
        .map((item) => OrderModel.fromJson(item))
        .toList();
  }

  Future<OrderModel> cancelOrder(int orderId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sales/orders/$orderId/cancel/',
    );

    return OrderModel.fromJson(response.data ?? {});
  }

  Future<OrderModel> createOrder({
    int storeId = defaultStoreId,
    int warehouseId = defaultWarehouseId,
    String notes = 'Pedido creado desde app móvil cliente',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sales/orders/',
      data: {
        'store': storeId,
        'warehouse': warehouseId,
        'notes': notes,
      },
    );

    return OrderModel.fromJson(response.data ?? {});
  }

  Future<void> createOrderDetail({
    required int orderId,
    required CartItemModel item,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/sales/order-details/',
      data: {
        'order': orderId,
        'product': item.productId,
        'quantity': item.quantity.toString(),
        'unit_price': item.unitPrice.toStringAsFixed(2),
      },
    );
  }

  Future<void> createPayment({
    required int orderId,
    required double amount,
    String paymentMethod = 'CASH',
    String status = 'PAID',
    String reference = 'Pago app móvil',
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/sales/payments/',
      data: {
        'order': orderId,
        'payment_method': paymentMethod,
        'amount': amount.toStringAsFixed(2),
        'status': status,
        'reference': reference,
      },
    );
  }

  List<Map<String, dynamic>> _toList(dynamic data) {
    final records = data is Map<String, dynamic> ? data['results'] : data;
    if (records is! List) return [];

    return records
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
