import '../../catalog/data/product_model.dart';

class CartItemModel {
  const CartItemModel({
    required this.productId,
    required this.name,
    required this.sku,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
  });

  factory CartItemModel.fromProduct(
    ProductModel product, {
    int quantity = 1,
  }) {
    return CartItemModel(
      productId: product.id,
      name: product.name,
      sku: product.sku,
      imageUrl: product.imageUrl,
      unitPrice: product.price,
      quantity: quantity,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: int.tryParse(json['productId']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Producto',
      sku: json['sku']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      unitPrice: double.tryParse(json['unitPrice']?.toString() ?? '') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
    );
  }

  final int productId;
  final String name;
  final String sku;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;

  double get subtotal => unitPrice * quantity;

  CartItemModel copyWith({
    String? name,
    String? sku,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
  }) {
    return CartItemModel(
      productId: productId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'sku': sku,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }
}
