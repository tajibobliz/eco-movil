import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_routes.dart';
import '../data/cart_item_model.dart';
import '../state/cart_provider.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => notifier.clear(),
              child: const Text('Limpiar'),
            ),
        ],
      ),
      body: SafeArea(
        child: cart.loaded
            ? _CartContent(cart: cart, notifier: notifier)
            : const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : _CartSummary(
              totalItems: cart.totalItems,
              totalAmount: cart.totalAmount,
            ),
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({
    required this.cart,
    required this.notifier,
  });

  final CartState cart;
  final CartNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (cart.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Tu carrito esta vacio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega productos desde la tienda para verlos aqui.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return _CartItemTile(
          item: item,
          onIncrease: () => notifier.increaseQuantity(item.productId),
          onDecrease: () => notifier.decreaseQuantity(item.productId),
          onRemove: () => notifier.removeProduct(item.productId),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: cart.items.length,
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItemModel item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CartItemImage(imageUrl: item.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (item.sku.isNotEmpty)
                    Text(
                      'SKU: ${item.sku}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Bs ${item.unitPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton.outlined(
                        onPressed: onDecrease,
                        icon: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          item.quantity.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: onIncrease,
                        icon: const Icon(Icons.add),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemImage extends StatelessWidget {
  const _CartItemImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return SizedBox(
      width: 82,
      height: 92,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: url == null || url.isEmpty
            ? const Icon(Icons.image_outlined, color: Colors.grey)
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.totalItems,
    required this.totalAmount,
  });

  final int totalItems;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              color: Color(0x1A000000),
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$totalItems item(s)'),
                Text(
                  'Bs ${totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.checkout);
              },
              child: const Text('Proceder al pago'),
            ),
          ],
        ),
      ),
    );
  }
}
