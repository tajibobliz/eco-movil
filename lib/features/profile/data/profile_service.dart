import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/user_storage.dart';
import '../../auth/data/user_model.dart';

class ProfileService {
  ProfileService({
    Dio? dio,
    UserStorage? userStorage,
  })  : _dio = dio ?? ApiClient.instance.dio,
        _userStorage = userStorage ?? UserStorage();

  final Dio _dio;
  final UserStorage _userStorage;

  Future<UserModel> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/usuarios/me/');
    final user = UserModel.fromJson(response.data ?? {});
    await _userStorage.saveUser(user);
    return user;
  }

  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/usuarios/me/',
      data: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'phone': phone.trim(),
      },
    );

    final user = UserModel.fromJson(response.data ?? {});
    await _userStorage.saveUser(user);
    return user;
  }
}
