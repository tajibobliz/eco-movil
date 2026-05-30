class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.status,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Categoria',
      description: json['description']?.toString(),
      status: json['status']?.toString(),
    );
  }

  final int id;
  final String name;
  final String? description;
  final String? status;
}
