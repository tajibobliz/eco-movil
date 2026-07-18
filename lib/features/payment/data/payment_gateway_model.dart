import 'package:flutter/material.dart';

class PaymentGatewayModel {
  const PaymentGatewayModel({
    required this.id,
    required this.gateway,
    required this.displayName,
    this.publishableKey = '',
    this.extraConfig = const {},
  });

  factory PaymentGatewayModel.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      gateway: json['gateway']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      publishableKey: json['publishable_key']?.toString() ?? '',
      extraConfig: json['extra_config'] is Map<String, dynamic>
          ? json['extra_config'] as Map<String, dynamic>
          : const {},
    );
  }

  final int id;
  final String gateway;
  final String displayName;
  final String publishableKey;
  final Map<String, dynamic> extraConfig;

  bool get isStripe => gateway.toUpperCase() == 'STRIPE';

  IconData get icon => switch (gateway.toUpperCase()) {
        'STRIPE' || 'CARD' => Icons.credit_card_outlined,
        'QR' => Icons.qr_code_outlined,
        'TRANSFER' => Icons.account_balance_outlined,
        'PAYPAL' => Icons.payment_outlined,
        _ => Icons.payments_outlined,
      };

  // Lista de fallback cuando la tienda no tiene pasarelas configuradas.
  static List<PaymentGatewayModel> get defaults => const [
        PaymentGatewayModel(id: 0, gateway: 'CASH', displayName: 'Efectivo'),
        PaymentGatewayModel(id: 0, gateway: 'QR', displayName: 'Pago QR'),
        PaymentGatewayModel(
          id: 0,
          gateway: 'TRANSFER',
          displayName: 'Transferencia bancaria',
        ),
        PaymentGatewayModel(
          id: 0,
          gateway: 'CARD',
          displayName: 'Tarjeta de debito/credito',
        ),
      ];
}
