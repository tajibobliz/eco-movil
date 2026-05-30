import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/user_model.dart';

class UserStorage {
  static const _userKey = 'customer_user';

  Future<void> saveUser(UserModel user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final preferences = await SharedPreferences.getInstance();
    final rawUser = preferences.getString(_userKey);
    if (rawUser == null || rawUser.isEmpty) return null;

    final json = jsonDecode(rawUser);
    if (json is! Map<String, dynamic>) return null;

    return UserModel.fromJson(json);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_userKey);
  }
}
