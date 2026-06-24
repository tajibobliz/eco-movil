import 'package:flutter/material.dart';

import '../data/delivery_models.dart';
import '../data/delivery_service.dart';

class DeliveryAssignmentsPage extends StatefulWidget {
  const DeliveryAssignmentsPage({
    super.key,
    this.confirmMode = false,
  });

  final bool confirmMode;

  @override
  State<DeliveryAssignmentsPage> createState() =>
      _DeliveryAssignmentsPageState();
}

class _DeliveryAssignmentsPageState extends State<DeliveryAssignmentsPage> {
  final _deliveryService = DeliveryService();

  bool _loading = true;
  int? _workingId;
  String? _error;
  List<DeliveryAssignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final assignments = await _deliveryService.getAssignments();
      if (!mounted) return;
      setState(() => _assignments = assignments);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar tus pedidos asignados.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(DeliveryAssignment assignment) async {
    await _runAction(
      assignment.id,
      () => _deliveryService.acceptAssignment(assignment.id),
      'Entrega aceptada.',
    );
  }

  Future<void> _start(DeliveryAssignment assignment) async {
    await _runAction(
      assignment.id,
      () => _deliveryService.startAssignment(assignment.id),
      'Marcaste la entrega como en camino.',
    );
  }

  Future<void> _confirm(DeliveryAssignment assignment) async {
    final notes = await _askConfirmationNotes(assignment);
    if (notes == null) return;

    await _runAction(
      assignment.id,
      () => _deliveryService.confirmDelivery(assignment.id, notes: notes),
      'Entrega confirmada correctamente.',
    );
  }

  Future<void> _runAction(
    int id,
    Future<DeliveryAssignment> Function() action,
    String successMessage,
  ) async {
    if (_workingId != null) return;

    setState(() => _workingId = id);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      await _loadAssignments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la entrega.')),
      );
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<String?> _askConfirmationNotes(DeliveryAssignment assignment) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar entrega'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              hintText: 'Ej. Entregado al receptor indicado',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.confirmMode ? 'Confirmacion de entrega' : 'Pedidos asignados';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: _loadAssignments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAssignments,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _MessageList(
        icon: Icons.assignment_outlined,
        message: _error!,
        action: FilledButton(
          onPressed: _loadAssignments,
          child: const Text('Reintentar'),
        ),
      );
    }

    if (_assignments.isEmpty) {
      return const _MessageList(
        icon: Icons.assignment_outlined,
        message: 'No tienes pedidos asignados activos por el momento.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        return _AssignmentCard(
          assignment: assignment,
          working: _workingId == assignment.id,
          confirmMode: widget.confirmMode,
          onAccept: () => _accept(assignment),
          onStart: () => _start(assignment),
          onConfirm: () => _confirm(assignment),
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.working,
    required this.confirmMode,
    required this.onAccept,
    required this.onStart,
    required this.onConfirm,
  });

  final DeliveryAssignment assignment;
  final bool working;
  final bool confirmMode;
  final VoidCallback onAccept;
  final VoidCallback onStart;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final phone = assignment.receiverPhone ?? assignment.customerPhone;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    assignment.orderCode ?? 'Pedido #${assignment.orderId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Chip(label: Text(assignment.status)),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.storefront_outlined,
              text: assignment.storeName,
            ),
            if ((assignment.paymentStatus ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.payments_outlined,
                text: 'Pago: ${assignment.paymentStatus}',
              ),
            if ((assignment.total ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.receipt_long_outlined,
                text: 'Total: Bs ${assignment.total}',
              ),
            if ((assignment.customerName ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.person_outline,
                text: 'Cliente: ${assignment.customerName}',
              ),
            if ((assignment.receiverName ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.badge_outlined,
                text: 'Receptor: ${assignment.receiverName}',
              ),
            if ((phone ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.phone_outlined,
                text: phone!,
              ),
            if ((assignment.address ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.place_outlined,
                text: [
                  assignment.address,
                  assignment.city,
                ].where((value) => (value ?? '').isNotEmpty).join(' - '),
              ),
            if ((assignment.notes ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.notes_outlined,
                text: assignment.notes!,
              ),
            const SizedBox(height: 14),
            if (working)
              const LinearProgressIndicator()
            else if (confirmMode)
              FilledButton.icon(
                onPressed: assignment.canConfirm ? onConfirm : null,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Confirmar entrega'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: assignment.canAccept ? onAccept : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Aceptar'),
                  ),
                  FilledButton.icon(
                    onPressed: assignment.canStart ? onStart : null,
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('En camino'),
                  ),
                  OutlinedButton.icon(
                    onPressed: assignment.canConfirm ? onConfirm : null,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Confirmar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 96),
        Icon(icon, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          action!,
        ],
      ],
    );
  }
}
