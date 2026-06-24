class DeliveryProfile {
  const DeliveryProfile({
    required this.id,
    required this.name,
    required this.available,
    required this.operationalStatus,
    required this.status,
    required this.hasActiveDelivery,
    this.phone,
    this.email,
  });

  factory DeliveryProfile.fromJson(Map<String, dynamic> json) {
    return DeliveryProfile(
      id: _toInt(json['id']),
      name: json['nombre_publico']?.toString() ??
          json['usuario_nombre']?.toString() ??
          '',
      email: json['usuario_email']?.toString(),
      phone: json['telefono']?.toString(),
      available: json['disponible'] == true,
      operationalStatus: json['estado_operativo']?.toString() ?? '',
      status: json['estado']?.toString() ?? '',
      hasActiveDelivery: json['tiene_entrega_activa'] == true,
    );
  }

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final bool available;
  final String operationalStatus;
  final String status;
  final bool hasActiveDelivery;
}

class DeliveryStore {
  const DeliveryStore({
    required this.id,
    required this.storeId,
    required this.name,
    required this.status,
    this.phone,
    this.email,
    this.businessType,
  });

  factory DeliveryStore.fromJson(Map<String, dynamic> json) {
    return DeliveryStore(
      id: _toInt(json['id']),
      storeId: _toInt(json['tienda']),
      name: json['tienda_nombre']?.toString() ?? 'Tienda asignada',
      phone: json['tienda_telefono']?.toString(),
      email: json['tienda_email']?.toString(),
      businessType: json['tienda_rubro']?.toString(),
      status: json['estado']?.toString() ?? '',
    );
  }

  final int id;
  final int storeId;
  final String name;
  final String? phone;
  final String? email;
  final String? businessType;
  final String status;
}

class DeliveryAssignment {
  const DeliveryAssignment({
    required this.id,
    required this.orderId,
    required this.status,
    required this.storeName,
    this.orderCode,
    this.orderStatus,
    this.paymentStatus,
    this.total,
    this.customerName,
    this.customerPhone,
    this.address,
    this.city,
    this.receiverName,
    this.receiverPhone,
    this.notes,
    this.assignedAt,
  });

  factory DeliveryAssignment.fromJson(Map<String, dynamic> json) {
    return DeliveryAssignment(
      id: _toInt(json['id']),
      orderId: _toInt(json['orden_venta']),
      orderCode: json['orden_codigo']?.toString(),
      orderStatus: json['orden_estado']?.toString(),
      paymentStatus: json['orden_pago_estado']?.toString(),
      total: json['orden_total']?.toString(),
      status: json['estado']?.toString() ?? '',
      storeName: json['tienda_nombre']?.toString() ?? 'Tienda',
      customerName: json['cliente_nombre']?.toString(),
      customerPhone: json['cliente_telefono']?.toString(),
      address: json['direccion_texto']?.toString(),
      city: json['direccion_ciudad']?.toString(),
      receiverName: json['receptor_nombre']?.toString(),
      receiverPhone: json['receptor_telefono']?.toString(),
      notes: json['observaciones']?.toString(),
      assignedAt: json['fecha_asignacion']?.toString(),
    );
  }

  final int id;
  final int orderId;
  final String? orderCode;
  final String? orderStatus;
  final String? paymentStatus;
  final String? total;
  final String status;
  final String storeName;
  final String? customerName;
  final String? customerPhone;
  final String? address;
  final String? city;
  final String? receiverName;
  final String? receiverPhone;
  final String? notes;
  final String? assignedAt;

  bool get canAccept => status == 'asignada';
  bool get canStart => status == 'asignada' || status == 'aceptada';
  bool get canConfirm {
    return status == 'asignada' || status == 'aceptada' || status == 'en_camino';
  }
}

int _toInt(dynamic value) {
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
