import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/orders_service.dart';
import '../state/cart_provider.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _ordersService = OrdersService();
  final _tokenStorage = TokenStorage();

  bool _processing = false;

  Future<void> _submitCheckout() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty || _processing) return;

    final hasToken = await _tokenStorage.hasAccessToken();
    if (!hasToken) {
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.customerLogin);
      return;
    }

    setState(() => _processing = true);

    try {
      final order = await _ordersService.createOrder();

      for (final item in cart.items) {
        await _ordersService.createOrderDetail(
          orderId: order.id,
          item: item,
        );
      }

      await _ordersService.createPayment(
        orderId: order.id,
        amount: cart.totalAmount,
      );

      await ref.read(cartProvider.notifier).clear();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        CheckoutSuccessPage.routeName,
        (_) => false,
        arguments: order,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readError(error))),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String _readError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final text = data?.toString().toLowerCase() ?? '';

      if (status == 401 || status == 403) {
        return 'Tu sesion expiro o no tienes permiso para comprar. Vuelve a iniciar sesion.';
      }

      if (text.contains('assigned store')) {
        return 'Tu cuenta no esta asociada a esta tienda. Vuelve a iniciar sesion o registrate desde la tienda.';
      }

      if (text.contains('warehouse')) {
        return 'No se pudo asociar el almacen predeterminado al pedido.';
      }

      if (data != null) return data.toString();
    }

    return 'No se pudo completar el pedido. Intenta nuevamente.';
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: cart.items.isEmpty
            ? const _EmptyCheckout()
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    'Resumen del pedido',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El pedido se registrara para revision del administrador de tienda.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          for (final item in cart.items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.name} x ${item.quantity}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    'Bs ${item.subtotal.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total'),
                              Text(
                                'Bs ${cart.totalAmount.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.payments_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Pago simulado'),
                      subtitle: const Text('Metodo: efectivo - Estado: pagado'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _processing ? null : _submitCheckout,
                    icon: _processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _processing ? 'Procesando...' : 'Confirmar compra',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class CheckoutSuccessPage extends StatelessWidget {
  const CheckoutSuccessPage({super.key});

  static const routeName = '/checkout/exito';

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments;
    final orderId = order is OrderModel ? order.id : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 82,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  orderId == null
                      ? 'Pedido registrado'
                      : 'Pedido #$orderId registrado',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tu compra fue creada correctamente. El administrador confirmara el pedido.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.myOrders);
                  },
                  child: const Text('Ver mis pedidos'),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.store,
                      (_) => false,
                    );
                  },
                  child: const Text('Volver a la tienda'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 70),
            const SizedBox(height: 16),
            Text(
              'No hay productos para pagar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(AppRoutes.store);
              },
              child: const Text('Ir a la tienda'),
            ),
          ],
        ),
      ),
    );
  }
}
