import 'package:flutter_dotenv/flutter_dotenv.dart';

// Environment configuration
class AppConfig {
  AppConfig._();

  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? (throw Exception('BASE_URL is not set in .env'));

  static String get jwtSecret =>
      dotenv.env['JWT_SECRET'] ?? (throw Exception('JWT_SECRET is not set in .env'));

  static String get adminUsername =>
      dotenv.env['ADMIN_USERNAME'] ?? (throw Exception('ADMIN_USERNAME is not set in .env'));

  static String get adminPassword =>
      dotenv.env['ADMIN_PASSWORD'] ?? (throw Exception('ADMIN_PASSWORD is not set in .env'));
}
