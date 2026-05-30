import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'category_model.dart';
import 'product_model.dart';

class CatalogService {
  CatalogService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  static const defaultStoreId = 1;

  final Dio _dio;

  Future<List<ProductModel>> getPublicProducts({
    int storeId = defaultStoreId,
  }) async {
    final response = await _dio.get<dynamic>('/public/stores/$storeId/products/');
    return _toList(response.data)
        .map((item) => ProductModel.fromJson(item))
        .toList();
  }

  Future<List<CategoryModel>> getPublicCategories({
    int storeId = defaultStoreId,
  }) async {
    final response = await _dio.get<dynamic>('/public/stores/$storeId/categories/');
    return _toList(response.data)
        .map((item) => CategoryModel.fromJson(item))
        .toList();
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
