import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_routes.dart';
import '../../cart/state/cart_provider.dart';
import '../data/product_model.dart';

class ProductDetailArgs {
  const ProductDetailArgs({
    required this.product,
    this.categoryName,
  });

  final ProductModel product;
  final String? categoryName;
}

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({
    required this.args,
    super.key,
  });

  final ProductDetailArgs args;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.args.product;
    final subtotal = product.price * _quantity;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de producto')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ProductImage(imageUrl: product.imageUrl),
            const SizedBox(height: 22),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            if (product.sku.isNotEmpty)
              Text(
                'SKU: ${product.sku}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (widget.args.categoryName != null) ...[
              const SizedBox(height: 8),
              Chip(label: Text(widget.args.categoryName!)),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Bs ${product.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (_quantity > 1) ...[
                  const SizedBox(width: 8),
                  Text(
                    '× $_quantity = Bs ${subtotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Text(
              product.description?.trim().isNotEmpty == true
                  ? product.description!
                  : 'Este producto todavia no tiene descripcion.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  'Cantidad',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                IconButton.outlined(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await ref
                    .read(cartProvider.notifier)
                    .addProduct(product, quantity: _quantity);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$_quantity × ${product.name} agregado al carrito.',
                    ),
                    action: SnackBarAction(
                      label: 'Ver',
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.cart);
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Agregar al carrito'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: url == null || url.isEmpty
            ? const Icon(Icons.image_outlined, size: 72, color: Colors.grey)
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.broken_image_outlined,
                      size: 72,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
      ),
    );
  }
}
