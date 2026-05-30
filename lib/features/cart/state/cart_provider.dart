import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../catalog/data/product_model.dart';
import '../data/cart_item_model.dart';

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

class CartState {
  const CartState({
    this.items = const [],
    this.loaded = false,
  });

  final List<CartItemModel> items;
  final bool loaded;

  int get totalItems {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  double get totalAmount {
    return items.fold(0, (total, item) => total + item.subtotal);
  }

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItemModel>? items,
    bool? loaded,
  }) {
    return CartState(
      items: items ?? this.items,
      loaded: loaded ?? this.loaded,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  static const _storageKey = 'customer_cart_items';

  @override
  CartState build() {
    Future.microtask(load);
    return const CartState();
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawCart = preferences.getString(_storageKey);

    if (rawCart == null || rawCart.isEmpty) {
      state = state.copyWith(loaded: true);
      return;
    }

    try {
      final decoded = jsonDecode(rawCart);
      final items = decoded is List
          ? decoded
              .whereType<Map>()
              .map((item) => CartItemModel.fromJson(Map<String, dynamic>.from(item)))
              .where((item) => item.productId > 0 && item.quantity > 0)
              .toList()
          : <CartItemModel>[];

      state = CartState(items: items, loaded: true);
    } catch (_) {
      state = state.copyWith(loaded: true);
    }
  }

  Future<void> addProduct(ProductModel product) async {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.productId == product.id);

    if (index >= 0) {
      final current = items[index];
      items[index] = current.copyWith(quantity: current.quantity + 1);
    } else {
      items.add(CartItemModel.fromProduct(product));
    }

    await _setItems(items);
  }

  Future<void> increaseQuantity(int productId) async {
    final items = state.items.map((item) {
      if (item.productId != productId) return item;
      return item.copyWith(quantity: item.quantity + 1);
    }).toList();

    await _setItems(items);
  }

  Future<void> decreaseQuantity(int productId) async {
    final items = state.items
        .map((item) {
          if (item.productId != productId) return item;
          return item.copyWith(quantity: item.quantity - 1);
        })
        .where((item) => item.quantity > 0)
        .toList();

    await _setItems(items);
  }

  Future<void> removeProduct(int productId) async {
    final items = state.items
        .where((item) => item.productId != productId)
        .toList();

    await _setItems(items);
  }

  Future<void> clear() async {
    await _setItems([]);
  }

  Future<void> _setItems(List<CartItemModel> items) async {
    state = CartState(items: List.unmodifiable(items), loaded: true);
    await _persist();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final payload = state.items.map((item) => item.toJson()).toList();
    await preferences.setString(_storageKey, jsonEncode(payload));
  }
}
