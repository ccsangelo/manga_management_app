import 'package:dartz/dartz.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manga_recommendation_app/config/app_config.dart';

class AuthService {
  static const _adminUsername = 'admin123';
  static const _adminPassword = 'admin123';
  static const _tokenKey = 'auth_token';

  final _storage = const FlutterSecureStorage();

  Future<Either<String, String>> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (username != _adminUsername || password != _adminPassword) {
      return const Left('Invalid username or password');
    }

    final token = JWT({'username': username}).sign(
      SecretKey(AppConfig.jwtSecret),
      expiresIn: const Duration(hours: 1),
    );
    await _storage.write(key: _tokenKey, value: token);
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

  Future<void> logout() => _storage.delete(key: _tokenKey);
}
