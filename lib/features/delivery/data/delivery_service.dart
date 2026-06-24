import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'delivery_models.dart';

class DeliveryService {
  DeliveryService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<DeliveryProfile> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/delivery/deliveries/me/',
    );
    return DeliveryProfile.fromJson(response.data ?? {});
  }

  Future<DeliveryProfile> updateStatus({
    required String operationalStatus,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/delivery/deliveries/me/estado/',
      data: {'estado_operativo': operationalStatus},
    );
    return DeliveryProfile.fromJson(response.data ?? {});
  }

  Future<List<DeliveryStore>> getAssignedStores() async {
    final response = await _dio.get<dynamic>('/delivery/delivery-tiendas/');
    return _readList(response.data)
        .map((item) => DeliveryStore.fromJson(item))
        .toList();
  }

  Future<List<DeliveryAssignment>> getAssignments({bool active = true}) async {
    final response = await _dio.get<dynamic>(
      '/delivery/entregas/',
      queryParameters: active ? {'active': '1'} : null,
    );
    return _readList(response.data)
        .map((item) => DeliveryAssignment.fromJson(item))
        .toList();
  }

  Future<DeliveryAssignment> acceptAssignment(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/delivery/entregas/$id/aceptar/',
    );
    return DeliveryAssignment.fromJson(response.data ?? {});
  }

  Future<DeliveryAssignment> startAssignment(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/delivery/entregas/$id/en-camino/',
    );
    return DeliveryAssignment.fromJson(response.data ?? {});
  }

  Future<DeliveryAssignment> confirmDelivery(
    int id, {
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/delivery/entregas/$id/confirmar-entrega/',
      data: {
        if (notes != null && notes.trim().isNotEmpty)
          'observaciones': notes.trim(),
      },
    );
    return DeliveryAssignment.fromJson(response.data ?? {});
  }

  List<Map<String, dynamic>> _readList(dynamic data) {
    final rawList = data is Map<String, dynamic> ? data['results'] : data;
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
