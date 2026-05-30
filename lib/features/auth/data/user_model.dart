class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.phone,
    this.store,
    this.currentStore,
    this.activeStoreId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id']),
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? json['nombres']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? json['apellidos']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['telefono']?.toString(),
      userType: json['user_type']?.toString() ?? json['role']?.toString() ?? '',
      store: _toNullableInt(json['store']),
      currentStore: _toNullableInt(json['current_store']),
      activeStoreId: _toNullableInt(json['active_store_id']),
    );
  }

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;
  final String? phone;
  final int? store;
  final int? currentStore;
  final int? activeStoreId;

  String get fullName => '$firstName $lastName'.trim();

  bool get isCustomer => userType.toUpperCase() == 'CUSTOMER';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'user_type': userType,
      'store': store,
      'current_store': currentStore,
      'active_store_id': activeStoreId,
    };
  }

  static int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}
