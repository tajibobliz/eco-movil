import 'package:flutter/material.dart';

import '../data/order_model.dart';

class OrderDetailCard extends StatelessWidget {
  const OrderDetailCard({
    required this.detail,
    super.key,
  });

  final OrderDetailModel detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.productName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          if (detail.productSku.isNotEmpty)
            Text(
              'SKU: ${detail.productSku}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cant: ${_formatQuantity(detail.quantity)}'),
              Text('PU: Bs ${detail.unitPrice.toStringAsFixed(2)}'),
              Text(
                'Bs ${detail.subtotal.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toStringAsFixed(2);
  }
}
