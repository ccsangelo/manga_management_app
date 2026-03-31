import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:manga_recommendation_app/config/app_config.dart';

// Generates and sends 6-digit verification codes via SMTP
class EmailVerificationService {
  String? _pendingCode;
  DateTime? _codeExpiry;

  void _clearPending() {
    _pendingCode = null;
    _codeExpiry = null;
  }

  // Send a verification code to the given email
  Future<Either<String, void>> sendVerificationCode(String email) async {
    _pendingCode = List.generate(6, (_) => Random.secure().nextInt(10)).join();
    _codeExpiry = DateTime.now().add(const Duration(minutes: 10));

    final smtpServer = SmtpServer(
      AppConfig.smtpHost,
      port: AppConfig.smtpPort,
      username: AppConfig.smtpUsername,
      password: AppConfig.smtpPassword,
      ssl: AppConfig.smtpPort == 465,
    );

    final message = Message()
      ..from = Address(AppConfig.smtpUsername, 'Manga App')
      ..recipients.add(email)
      ..subject = 'Your Verification Code'
      ..text = 'Your verification code is: $_pendingCode\n\nThis code expires in 10 minutes.';

    try {
      await send(message, smtpServer).timeout(const Duration(seconds: 15));
      return const Right(null);
    } catch (e) {
      _clearPending();
      return Left('Failed to send email: $e');
    }
  }

  // Validate the submitted code against the pending code
  bool verifyCode(String code) {
    if (_pendingCode == null || _codeExpiry == null) return false;
    if (DateTime.now().isAfter(_codeExpiry!)) {
      _clearPending();
      return false;
    }
    final valid = code == _pendingCode;
    if (valid) _clearPending();
    return valid;
  }
}
