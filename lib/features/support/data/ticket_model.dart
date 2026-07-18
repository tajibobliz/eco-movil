class TicketModel {
  const TicketModel({
    required this.id,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.clienteName,
    this.assignedToName,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: _toInt(json['id']),
      subject: json['subject']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      clienteName: json['cliente_name']?.toString(),
      assignedToName: json['assigned_to_name']?.toString(),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
    );
  }

  final int id;
  final String subject;
  final String status;
  final String priority;
  final String? clienteName;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime updatedAt;

  static int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  static DateTime _toDate(dynamic v) {
    if (v == null) return DateTime.now();
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}

class TicketMessageModel {
  const TicketMessageModel({
    required this.id,
    required this.content,
    required this.authorType,
    required this.createdAt,
    this.authorName,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    return TicketMessageModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      content: json['content']?.toString() ?? '',
      authorType: json['author_type']?.toString() ?? 'CUSTOMER',
      authorName: json['author_name']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  final int id;
  final String content;
  final String authorType;
  final String? authorName;
  final DateTime createdAt;

  bool get isFromCustomer => authorType == 'CUSTOMER';
}
