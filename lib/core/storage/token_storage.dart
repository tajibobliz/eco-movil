import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _secureStorage.write(key: _accessKey, value: access);
    await _secureStorage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> getAccessToken() {
    return _secureStorage.read(key: _accessKey);
  }

  Future<String?> getRefreshToken() {
    return _secureStorage.read(key: _refreshKey);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _accessKey);
    await _secureStorage.delete(key: _refreshKey);
  }
}
