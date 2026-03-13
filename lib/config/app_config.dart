import 'package:flutter_dotenv/flutter_dotenv.dart';

// Environment configuration
class AppConfig {
  AppConfig._();

  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://api.jikan.moe/v4';
}
