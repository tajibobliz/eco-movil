import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/orders_service.dart';
import '../../payment/data/payment_gateway_model.dart';
import '../../payment/data/payment_service.dart';
import '../state/cart_provider.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _ordersService = OrdersService();
  final _paymentService = PaymentService();
  final _tokenStorage = TokenStorage();
  final _notesController = TextEditingController();

  List<PaymentGatewayModel> _gateways = [];
  PaymentGatewayModel? _selectedGateway;
  bool _loadingGateways = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadGateways();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadGateways() async {
    try {
      final gateways = await _paymentService.getStorePaymentMethods();
      if (!mounted) return;
      final list = gateways.isEmpty ? PaymentGatewayModel.defaults : gateways;
      setState(() {
        _gateways = list;
        _selectedGateway = list.first;
      });
    } catch (_) {
      if (!mounted) return;
      // Si falla la carga, usar lista estática de fallback.
      final fallback = PaymentGatewayModel.defaults;
      setState(() {
        _gateways = fallback;
        _selectedGateway = fallback.first;
      });
    } finally {
      if (mounted) setState(() => _loadingGateways = false);
    }
  }

  Future<void> _submitCheckout() async {
    final cart = ref.read(cartProvider);
    final gateway = _selectedGateway;
    if (cart.items.isEmpty || _processing || gateway == null) return;

    final hasToken = await _tokenStorage.hasAccessToken();
    if (!hasToken) {
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.customerLogin);
      return;
    }

    setState(() => _processing = true);

    try {
      final notes = _notesController.text.trim();
      final order = await _ordersService.createOrder(
        notes: notes.isEmpty ? 'Pedido creado desde app móvil cliente' : notes,
      );

      for (final item in cart.items) {
        await _ordersService.createOrderDetail(orderId: order.id, item: item);
      }

      if (gateway.isStripe) {
        await _processStripePayment(order: order, gateway: gateway);
      } else {
        await _ordersService.createPayment(
          orderId: order.id,
          amount: cart.totalAmount,
          paymentMethod: gateway.gateway,
        );
      }

      await ref.read(cartProvider.notifier).clear();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        CheckoutSuccessPage.routeName,
        (_) => false,
        arguments: _CheckoutSuccessArgs(
          order: order,
          isStripe: gateway.isStripe,
        ),
      );
    } on StripeException catch (e) {
      if (!mounted) return;
      final msg = e.error.code == FailureCode.Canceled
          ? 'Pago cancelado.'
          : e.error.message ?? 'Error al procesar el pago con tarjeta.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readError(error))),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _processStripePayment({
    required OrderModel order,
    required PaymentGatewayModel gateway,
  }) async {
    // Configurar la publishable key de ESTA empresa (multi-tenant).
    Stripe.publishableKey = gateway.publishableKey;
    await Stripe.instance.applySettings();

    final intent = await _paymentService.createPaymentIntent(order.id);
    final clientSecret = intent['client_secret'] ?? '';

    await Stripe.instance.initPaymentSheet(
      paymentSheetData: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'ECO Store',
        style: MediaQuery.of(context).platformBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
    );

    // Lanza StripeException si el usuario cancela o hay error de pago.
    await Stripe.instance.presentPaymentSheet();
    // El webhook de Stripe confirma el pedido automaticamente.
  }

  String _readError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final text = data?.toString().toLowerCase() ?? '';

      if (status == 401 || status == 403) {
        return 'Tu sesion expiro o no tienes permiso para comprar.';
      }
      if (text.contains('assigned store')) {
        return 'Tu cuenta no esta asociada a esta tienda.';
      }
      if (text.contains('warehouse')) {
        return 'No se pudo asociar el almacen al pedido.';
      }
      if (text.contains('stripe') || text.contains('pasarela')) {
        return data?.toString() ?? 'Error al iniciar el pago con tarjeta.';
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
                  _DynamicPaymentSelector(
                    gateways: _gateways,
                    selected: _selectedGateway,
                    loading: _loadingGateways,
                    onChanged: (g) => setState(() => _selectedGateway = g),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Instrucciones de entrega',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Dejar en recepcion, llamar al llegar...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed:
                        (_processing || _loadingGateways || _selectedGateway == null)
                            ? null
                            : _submitCheckout,
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

// ---------------------------------------------------------------------------
// Datos para la pantalla de éxito
// ---------------------------------------------------------------------------

class _CheckoutSuccessArgs {
  const _CheckoutSuccessArgs({required this.order, this.isStripe = false});
  final OrderModel order;
  final bool isStripe;
}

// ---------------------------------------------------------------------------
// Selector dinámico de métodos de pago
// ---------------------------------------------------------------------------

class _DynamicPaymentSelector extends StatelessWidget {
  const _DynamicPaymentSelector({
    required this.gateways,
    required this.selected,
    required this.loading,
    required this.onChanged,
  });

  final List<PaymentGatewayModel> gateways;
  final PaymentGatewayModel? selected;
  final bool loading;
  final ValueChanged<PaymentGatewayModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metodo de pago',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  children: [
                    for (final gateway in gateways)
                      ListTile(
                        leading: Icon(
                          selected?.gateway == gateway.gateway
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selected?.gateway == gateway.gateway
                              ? color
                              : null,
                        ),
                        title: Text(gateway.displayName),
                        trailing: Icon(
                          gateway.icon,
                          color: selected?.gateway == gateway.gateway
                              ? color
                              : null,
                        ),
                        onTap: () => onChanged(gateway),
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                  ],
                ),
        ),
        if (selected?.isStripe == true) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Pago seguro procesado por Stripe',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pantalla de éxito
// ---------------------------------------------------------------------------

class CheckoutSuccessPage extends StatelessWidget {
  const CheckoutSuccessPage({super.key});

  static const routeName = '/checkout/exito';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final successArgs = args is _CheckoutSuccessArgs ? args : null;
    final orderId = successArgs?.order.id;
    final isStripe = successArgs?.isStripe ?? false;

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
                  isStripe
                      ? 'Tu pago fue procesado por Stripe. La tienda confirmara el pedido en breve.'
                      : 'Tu compra fue creada correctamente. El administrador confirmara el pedido.',
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

// ---------------------------------------------------------------------------

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
