import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'payment_gateway_model.dart';

class PaymentService {
  PaymentService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  static const _defaultStoreId = 57;

  final Dio _dio;

  Future<List<PaymentGatewayModel>> getStorePaymentMethods({
    int storeId = _defaultStoreId,
  }) async {
    final response = await _dio.get<dynamic>(
      '/public/stores/$storeId/payment-methods/',
    );
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] ?? []) : []);

    return (list as List)
        .whereType<Map>()
        .map(
          (item) => PaymentGatewayModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  /// Crea (o recupera) un PaymentIntent en Stripe para el pedido dado.
  /// Retorna { 'client_secret': '...', 'payment_intent_id': '...' }.
  Future<Map<String, String>> createPaymentIntent(int orderId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sales/orders/$orderId/create-payment-intent/',
    );
    return {
      'client_secret': response.data?['client_secret']?.toString() ?? '',
      'payment_intent_id':
          response.data?['payment_intent_id']?.toString() ?? '',
    };
  }
}
