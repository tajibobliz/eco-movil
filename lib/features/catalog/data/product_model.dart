class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.sku,
    this.storeId,
    this.categoryId,
    this.description,
    this.barcode,
    this.unitOfMeasure,
    this.status,
    this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      storeId: _toNullableInt(json['store']),
      categoryId: _toNullableInt(json['category']),
      name: json['name']?.toString() ?? 'Producto',
      description: json['description']?.toString(),
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      price: double.tryParse(json['sale_price']?.toString() ?? '') ?? 0,
      unitOfMeasure: json['unit_of_measure']?.toString(),
      status: json['status']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  final int id;
  final int? storeId;
  final int? categoryId;
  final String name;
  final String? description;
  final String sku;
  final String? barcode;
  final double price;
  final String? unitOfMeasure;
  final String? status;
  final String? imageUrl;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    return name.toLowerCase().contains(normalized) ||
        sku.toLowerCase().contains(normalized);
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}
