import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../data/order_model.dart';
import '../data/orders_service.dart';
import 'order_detail_card.dart';
import 'order_status_chip.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final _ordersService = OrdersService();
  final _tokenStorage = TokenStorage();

  List<OrderModel> _orders = [];
  bool _loading = true;
  int? _cancellingOrderId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final hasToken = await _tokenStorage.hasAccessToken();
    if (!hasToken) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.customerLogin);
      return;
    }

    try {
      final orders = await _ordersService.getMyOrders();
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (error) {
      if (!mounted) return;
      if (error is DioException &&
          (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403)) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.customerLogin);
        return;
      }

      setState(() {
        _error = 'No se pudieron cargar tus pedidos.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text('¿Desea cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancellingOrderId = order.id);

    try {
      await _ordersService.cancelOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado correctamente.')),
      );
      await _loadOrders();
    } catch (error) {
      if (!mounted) return;
      final message = error is DioException
          ? _extractErrorMessage(error)
          : 'No se pudo cancelar el pedido.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _cancellingOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? null
            : IconButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.store);
                },
                icon: const Icon(Icons.home_outlined),
                tooltip: 'Ir a tienda',
              ),
        title: const Text('Mis pedidos'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.customerProfile);
            },
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi perfil',
          ),
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadOrders,
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
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 96),
          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadOrders,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 96),
          Icon(
            Icons.shopping_bag_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aun no tienes pedidos',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando completes una compra, aparecera aqui.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(AppRoutes.store);
            },
            child: const Text('Ir a la tienda'),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _OrderCard(
          order: order,
          cancelling: _cancellingOrderId == order.id,
          onCancel: () => _cancelOrder(order),
        );
      },
    );
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail != null) return detail.toString();
    }

    return 'No se pudo cancelar el pedido.';
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.cancelling,
    required this.onCancel,
  });

  final OrderModel order;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final paymentMethod =
        order.paymentMethodDisplay ?? order.paymentMethod ?? 'Sin metodo';
    final canCancel = order.status.trim().toUpperCase() == 'DRAFT';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    'Pedido #${order.id}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  'Bs ${order.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              runSpacing: 8,
              spacing: 8,
              children: [
                OrderStatusChip(status: order.status),
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  text: _formatDate(order.createdAt),
                ),
                _InfoChip(
                  icon: Icons.store_outlined,
                  text: order.storeName ?? 'Tienda',
                ),
                _InfoChip(
                  icon: Icons.warehouse_outlined,
                  text: order.warehouseName ?? 'Almacen',
                ),
                _InfoChip(
                  icon: Icons.credit_card_outlined,
                  text: paymentMethod,
                ),
                OrderStatusChip(
                  status: order.paymentStatus ?? order.paymentStatusDisplay,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Productos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            if (order.details.isEmpty)
              Text(
                'Este pedido no tiene detalles disponibles.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...order.details.map(
                (detail) => OrderDetailCard(detail: detail),
              ),
            if (canCancel) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: cancelling ? null : onCancel,
                  icon: cancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: Text(cancelling ? 'Cancelando...' : 'Cancelar pedido'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Sin fecha';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      visualDensity: VisualDensity.compact,
    );
  }
}
