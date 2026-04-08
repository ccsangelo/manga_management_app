import 'package:flutter_dotenv/flutter_dotenv.dart';

// Environment variable configuration
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

  static String get smtpHost =>
      dotenv.env['SMTP_HOST'] ?? (throw Exception('SMTP_HOST is not set in .env'));

  static int get smtpPort =>
      int.tryParse(dotenv.env['SMTP_PORT'] ?? '') ?? (throw Exception('SMTP_PORT is not set in .env'));

  static String get smtpUsername =>
      dotenv.env['SMTP_USERNAME'] ?? (throw Exception('SMTP_USERNAME is not set in .env'));

  static String get smtpPassword =>
      dotenv.env['SMTP_PASSWORD'] ?? (throw Exception('SMTP_PASSWORD is not set in .env'));
}
