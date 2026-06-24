import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    // Hardcoded para defensa: apunta a Railway producción
    return 'https://eco-backend-production-8c5a.up.railway.app/api/v1';
  }
}
