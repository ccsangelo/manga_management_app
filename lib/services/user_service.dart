import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Hive-backed user storage with SHA-256 password hashing
class UserService {
  static const _boxName = 'users';
  late final Box<String> _box;

  static Future<UserService> init() async {
    final service = UserService();
    service._box = await Hive.openBox<String>(_boxName);
    return service;
  }

  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  bool isUsernameTaken(String username) => _box.containsKey(username);

  Future<void> saveUser(String email, String username, String password) async {
    final data = jsonEncode({
      'email': email,
      'username': username,
      'passwordHash': _hashPassword(password),
    });
    await _box.put(username, data);
  }

  bool validateCredentials(String username, String password) {
    final json = _box.get(username);
    if (json == null) return false;
    return jsonDecode(json)['passwordHash'] == _hashPassword(password);
  }

  Future<void> clearAll() => _box.clear();
}
