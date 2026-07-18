import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'ticket_model.dart';

class TicketService {
  TicketService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  static const _defaultStoreSlug = 'demo-store';

  final Dio _dio;

  Future<List<TicketModel>> getTickets() async {
    final response = await _dio.get<dynamic>('/support/tickets/');
    return _toList(response.data)
        .map((item) => TicketModel.fromJson(item))
        .toList();
  }

  Future<TicketModel> createTicket({
    required String subject,
    required String initialMessage,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/support/tickets/',
      data: {
        'subject': subject,
        'initial_message': initialMessage,
        'store_slug': _defaultStoreSlug,
      },
    );
    return TicketModel.fromJson(response.data ?? {});
  }

  Future<List<TicketMessageModel>> getMessages(int ticketId) async {
    final response =
        await _dio.get<dynamic>('/support/tickets/$ticketId/messages/');
    return _toList(response.data)
        .map((item) => TicketMessageModel.fromJson(item))
        .toList();
  }

  Future<void> sendMessage(int ticketId, String content) async {
    await _dio.post<dynamic>(
      '/support/tickets/$ticketId/messages/',
      data: {'content': content},
    );
  }

  Future<void> resolveTicket(int ticketId) async {
    await _dio.patch<dynamic>(
      '/support/tickets/$ticketId/',
      data: {'status': 'RESOLVED'},
    );
  }

  List<Map<String, dynamic>> _toList(dynamic data) {
    final records = data is Map<String, dynamic> ? data['results'] ?? data : data;
    if (records is! List) return [];
    return records
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
