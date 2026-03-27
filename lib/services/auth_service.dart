import 'package:dartz/dartz.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manga_recommendation_app/config/app_config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _sessionKey = 'active_session';

  final _storage = const FlutterSecureStorage();

  /// Returns true if a previous session exists that wasn't properly logged out.
  Future<bool> hasActiveSession() async {
    final session = await _storage.read(key: _sessionKey);
    return session != null;
  }

  Future<Either<String, String>> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (username != AppConfig.adminUsername || password != AppConfig.adminPassword) {
      return const Left('Invalid username or password');
    }

    final token = JWT({'username': username}).sign(
      SecretKey(AppConfig.jwtSecret),
      expiresIn: const Duration(hours: 1),
    );
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(
      key: _sessionKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    return Right(token);
  }

  Future<String?> getValidToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;
    try {
      JWT.verify(token, SecretKey(AppConfig.jwtSecret));
      return token;
    } catch (_) {
      await _storage.delete(key: _tokenKey);
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _sessionKey);
  }
}
