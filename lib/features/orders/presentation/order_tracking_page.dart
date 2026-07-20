import 'package:flutter/material.dart';

import '../data/order_model.dart';

// ---------------------------------------------------------------------------
// Step descriptor (private, used by _Stepper)
// ---------------------------------------------------------------------------

class _StepData {
  const _StepData(this.icon, this.iconDone, this.title, this.desc);
  final IconData icon;
  final IconData iconDone;
  final String title;
  final String desc;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage>
    with SingleTickerProviderStateMixin {
  // One controller drives both the step-icon pulse and the live-badge dot.
  // repeat(reverse: true) creates the smooth in-out loop.
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String get _status => widget.order.status.trim().toUpperCase();

  bool get _isCancelled => _status == 'CANCELLED';
  bool get _isWaiting => _status == 'DRAFT' || _status == 'PENDING';

  /// How many of the 3 steps are completed.
  int get _doneCount {
    switch (_status) {
      case 'CONFIRMED':
        return 1;
      case 'DELIVERED':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento de pedido')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
          children: [
            _InfoCard(order: widget.order, pulseAnim: _pulseAnim),
            const SizedBox(height: 24),
            if (_isCancelled)
              const _CancelledCard()
            else ...[
              if (_isWaiting) const _WaitingBanner(),
              _Stepper(done: _doneCount, pulseAnim: _pulseAnim),
            ],
            const SizedBox(height: 28),
            Text(
              'Este seguimiento es referencial.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.65),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info card  (header + date + live badge + 2 metric tiles)
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.order, required this.pulseAnim});

  final OrderModel order;
  final Animation<double> pulseAnim;

  String get _dateStr {
    final d = order.createdAt;
    if (d == null) return 'Sin fecha';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${order.id}',
                        style: tt.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dateStr,
                        style:
                            tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _LiveBadge(anim: pulseAnim),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Total',
                    value: 'Bs ${order.totalAmount.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: 'Artículos',
                    value: '${order.details.length}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.anim});

  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: anim,
          builder: (_, child) =>
              Opacity(opacity: 0.35 + 0.65 * anim.value, child: child!),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'Actualizado ahora',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cancelled state
// ---------------------------------------------------------------------------

class _CancelledCard extends StatelessWidget {
  const _CancelledCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.cancel_outlined, size: 76, color: cs.error),
            const SizedBox(height: 14),
            Text(
              'Pedido cancelado',
              style: tt.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800, color: cs.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Este pedido fue cancelado y no será procesado.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Waiting banner  (DRAFT / PENDING)
// ---------------------------------------------------------------------------

class _WaitingBanner extends StatelessWidget {
  const _WaitingBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_top_outlined,
            color: cs.onSecondaryContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esperando confirmación de pago',
              style: TextStyle(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stepper  (3 fixed steps, vertical)
// ---------------------------------------------------------------------------

class _Stepper extends StatelessWidget {
  const _Stepper({required this.done, required this.pulseAnim});

  final int done;
  final Animation<double> pulseAnim;

  static const _steps = [
    _StepData(
      Icons.check_circle_outline,
      Icons.check_circle,
      'Confirmado',
      'Tu pedido fue recibido y confirmado.',
    ),
    _StepData(
      Icons.inventory_2_outlined,
      Icons.inventory_2,
      'En preparación',
      'La tienda está preparando tu pedido.',
    ),
    _StepData(
      Icons.local_shipping_outlined,
      Icons.local_shipping,
      'Entregado',
      'Tu pedido fue entregado exitosamente.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _steps.length; i++)
          _StepRow(
            isCompleted: i < done,
            isActive: done > 0 && i == done - 1,
            isConnectorDone: (i + 1) < done,
            isLast: i == _steps.length - 1,
            data: _steps[i],
            pulseAnim: pulseAnim,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.isCompleted,
    required this.isActive,
    required this.isConnectorDone,
    required this.isLast,
    required this.data,
    required this.pulseAnim,
  });

  final bool isCompleted;
  final bool isActive;
  final bool isConnectorDone;
  final bool isLast;
  final _StepData data;
  final Animation<double> pulseAnim;

  static const _connectorH = 38.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final doneColor = cs.primary;
    final pendingColor = cs.onSurfaceVariant.withValues(alpha: 0.28);

    Widget iconWidget = Icon(
      isCompleted ? data.iconDone : data.icon,
      size: 30,
      color: isCompleted ? doneColor : pendingColor,
    );

    // Subtle scale pulse only on the last-completed ("active") step.
    if (isActive) {
      iconWidget = AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: 0.86 + 0.14 * pulseAnim.value,
          child: child,
        ),
        child: iconWidget,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: icon + vertical connector line
        SizedBox(
          width: 44,
          child: Column(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Center(child: iconWidget),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: _connectorH,
                  decoration: BoxDecoration(
                    color: isConnectorDone ? doneColor : pendingColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Right column: title + description
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: 11,
              bottom: isLast ? 0 : _connectorH + 6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight:
                        isCompleted ? FontWeight.w700 : FontWeight.w500,
                    color: isCompleted
                        ? cs.onSurface
                        : cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.desc,
                  style: tt.bodySmall?.copyWith(
                    color: isCompleted
                        ? cs.onSurfaceVariant
                        : cs.onSurfaceVariant.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
