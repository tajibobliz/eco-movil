import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/storage/user_storage.dart';
import 'user_model.dart';

class AuthService {
  AuthService({Dio? dio, TokenStorage? tokenStorage, UserStorage? userStorage})
    : _dio = dio ?? ApiClient.instance.dio,
      _tokenStorage = tokenStorage ?? TokenStorage(),
      _userStorage = userStorage ?? UserStorage();

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final UserStorage _userStorage;

  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/',
      data: {'email': email.trim(), 'password': password},
    );

    return _persistAuthResponse(response.data ?? {});
  }

  Future<UserModel> registerCustomer(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/usuarios/register/',
      data: payload,
    );

    return _persistAuthResponse(response.data ?? {});
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/usuarios/me/');
    final user = UserModel.fromJson(response.data ?? {});
    await _userStorage.saveUser(user);
    return user;
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    await _userStorage.clear();
  }

  Future<UserModel> _persistAuthResponse(Map<String, dynamic> data) async {
    final access = data['access']?.toString();
    final refresh = data['refresh']?.toString();
    final userData = data['user'];

    if (access == null ||
        refresh == null ||
        userData is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de autenticacion invalida.');
    }

    final user = UserModel.fromJson(userData);
    await _tokenStorage.saveTokens(access: access, refresh: refresh);
    await _userStorage.saveUser(user);
    await NotificationService.registerCurrentTokenIfAuthenticated();
    return user;
  }
}
