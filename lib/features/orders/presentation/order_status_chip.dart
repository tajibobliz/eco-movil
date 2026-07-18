import 'package:flutter/material.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({
    required this.status,
    super.key,
  });

  final String? status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 15, color: style.foreground),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
    required this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final IconData icon;
}

_StatusStyle _statusStyle(String? rawStatus) {
  final status = (rawStatus ?? '').trim().toUpperCase();

  switch (status) {
    case 'DRAFT':
      return const _StatusStyle(
        label: 'Pendiente de confirmación',
        foreground: Color(0xFFC2410C),
        background: Color(0xFFFFEDD5),
        border: Color(0xFFFDBA74),
        icon: Icons.schedule_outlined,
      );
    case 'CONFIRMED':
      return const _StatusStyle(
        label: 'Confirmado',
        foreground: Color(0xFF15803D),
        background: Color(0xFFDCFCE7),
        border: Color(0xFF86EFAC),
        icon: Icons.check_circle_outline,
      );
    case 'CANCELLED':
      return const _StatusStyle(
        label: 'Cancelado',
        foreground: Color(0xFFB91C1C),
        background: Color(0xFFFEE2E2),
        border: Color(0xFFFCA5A5),
        icon: Icons.cancel_outlined,
      );
    case 'DELIVERED':
      return const _StatusStyle(
        label: 'Entregado',
        foreground: Color(0xFF166534),
        background: Color(0xFFBBF7D0),
        border: Color(0xFF4ADE80),
        icon: Icons.local_shipping_outlined,
      );
    case 'PENDING':
      return const _StatusStyle(
        label: 'Pendiente',
        foreground: Color(0xFF92400E),
        background: Color(0xFFFEF3C7),
        border: Color(0xFFFCD34D),
        icon: Icons.hourglass_empty_outlined,
      );
    case 'PAID':
      return const _StatusStyle(
        label: 'Pagado',
        foreground: Color(0xFF1D4ED8),
        background: Color(0xFFDBEAFE),
        border: Color(0xFF93C5FD),
        icon: Icons.payments_outlined,
      );
    default:
      return const _StatusStyle(
        label: 'En revisión',
        foreground: Color(0xFF374151),
        background: Color(0xFFF3F4F6),
        border: Color(0xFFD1D5DB),
        icon: Icons.info_outline,
      );
  }
}
