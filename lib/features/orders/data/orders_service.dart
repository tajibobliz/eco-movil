import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../cart/data/cart_item_model.dart';
import 'order_model.dart';

class OrdersService {
  OrdersService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  static const defaultStoreId = 57;
  static const defaultWarehouseId = 45;

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

  /// Confirma el pago de un pedido con el método no-Stripe seleccionado
  /// (CASH, QR, TRANSFER). El backend descuenta stock y marca la orden
  /// como CONFIRMED en una sola operación atómica.
  Future<void> payOrder(int orderId) async {
    await _dio.post<dynamic>('/sales/orders/$orderId/pay/');
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
