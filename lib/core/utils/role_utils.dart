String normalizeRole(Map<String, dynamic> data) {
  final rawRole = data['user_type'] ?? data['role_scope'] ?? data['role'] ?? '';
  return rawRole.toString().trim().toUpperCase();
}

bool isCustomerRole(String role) => role.trim().toUpperCase() == 'CUSTOMER';
