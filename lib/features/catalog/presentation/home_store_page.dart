import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_service.dart';
import '../../cart/state/cart_provider.dart';
import '../data/catalog_service.dart';
import '../data/category_model.dart';
import '../data/product_model.dart';
import 'product_detail_page.dart';

class HomeStorePage extends ConsumerStatefulWidget {
  const HomeStorePage({super.key});

  @override
  ConsumerState<HomeStorePage> createState() => _HomeStorePageState();
}

class _HomeStorePageState extends ConsumerState<HomeStorePage> {
  final _authService = AuthService();
  final _catalogService = CatalogService();
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ensureCustomerSessionAndLoad();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureCustomerSessionAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final hasToken = await _tokenStorage.hasAccessToken();
    if (!mounted) return;

    if (!hasToken) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return;
    }

    try {
      final user = await _authService.getMe();
      if (!mounted) return;

      if (user.isDelivery) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.deliveryHome);
        return;
      }

      if (!user.isCustomer) {
        await _authService.logout();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        return;
      }

      await _loadCatalog();
    } catch (_) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _catalogService.getPublicProducts(),
        _catalogService.getPublicCategories(),
      ]);

      if (!mounted) return;

      setState(() {
        _products = results[0] as List<ProductModel>;
        _categories = results[1] as List<CategoryModel>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el catalogo.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Map<int, String> get _categoryNames {
    return {
      for (final category in _categories) category.id: category.name,
    };
  }

  List<ProductModel> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategoryId == null ||
          product.categoryId == _selectedCategoryId;
      return matchesCategory && product.matches(_query);
    }).toList();
  }

  void _openProduct(ProductModel product) {
    Navigator.of(context).pushNamed(
      AppRoutes.productDetail,
      arguments: ProductDetailArgs(
        product: product,
        categoryName: _categoryNames[product.categoryId],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final totalItems = ref.watch(cartProvider.select((cart) => cart.totalItems));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: [
          IconButton(
            onPressed: _ensureCustomerSessionAndLoad,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.customerProfile);
            },
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi perfil',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.myOrders);
            },
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Mis pedidos',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
          _CartIconButton(totalItems: totalItems),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _ensureCustomerSessionAndLoad,
          child: _buildBody(products),
        ),
      ),
    );
  }

  Widget _buildBody(List<ProductModel> products) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 96),
          const Icon(Icons.wifi_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _ensureCustomerSessionAndLoad,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Text(
          'Catalogo publico',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Explora productos disponibles de la tienda.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre o SKU',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 14),
        _CategoryChips(
          categories: _categories,
          selectedCategoryId: _selectedCategoryId,
          onSelected: (categoryId) {
            setState(() => _selectedCategoryId = categoryId);
          },
        ),
        const SizedBox(height: 18),
        if (_products.isEmpty)
          const _EmptyCatalog(
            message: 'No hay productos disponibles por el momento.',
          )
        else if (products.isEmpty)
          const _EmptyCatalog(
            message: 'No encontramos productos con esos filtros.',
          )
        else
          ...products.map(
            (product) {
              return _ProductCard(
                product: product,
                categoryName: _categoryNames[product.categoryId],
                onTap: () => _openProduct(product),
              );
            },
          ),
      ],
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    await ref.read(cartProvider.notifier).clear();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (_) => false,
    );
  }
}

class _CartIconButton extends StatelessWidget {
  const _CartIconButton({required this.totalItems});

  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context).pushNamed(AppRoutes.cart);
      },
      tooltip: 'Carrito',
      icon: Badge(
        isLabelVisible: totalItems > 0,
        label: Text(totalItems.toString()),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Todos'),
              selected: selectedCategoryId == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map(
            (category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category.name),
                  selected: selectedCategoryId == category.id,
                  onSelected: (_) => onSelected(category.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    this.categoryName,
  });

  final ProductModel product;
  final String? categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductThumbnail(imageUrl: product.imageUrl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    if (product.sku.isNotEmpty)
                      Text(
                        'SKU: ${product.sku}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (categoryName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        categoryName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Bs ${product.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12, right: 10),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return SizedBox(
      width: 112,
      height: 132,
      child: ColoredBox(
        color: const Color(0xFFF3F4F6),
        child: url == null || url.isEmpty
            ? const Icon(Icons.image_outlined, color: Colors.grey)
            : Image.network(
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
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 58, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
