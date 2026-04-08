import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Hive-backed user storage with bcrypt password hashing
class UserService {
  static const _boxName = 'users';
  late final Box<String> _box;

  static Future<UserService> init() async {
    final service = UserService();
    service._box = await Hive.openBox<String>(_boxName);
    return service;
  }

  String _hashPassword(String password) =>
      BCrypt.hashpw(password, BCrypt.gensalt());

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
    final raw = _box.get(username);
    if (raw == null) return false;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final storedHash = map['passwordHash'] as String;

    // Legacy SHA-256 hash (64-char hex) — reject, requires re-registration
    if (!storedHash.startsWith('\$2')) {
      return false;
    }

    return BCrypt.checkpw(password, storedHash);
  }

  Future<void> clearAll() => _box.clear();
}
