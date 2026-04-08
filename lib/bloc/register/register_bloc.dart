import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/register/register_event.dart';
import 'package:manga_recommendation_app/bloc/register/register_state.dart';
import 'package:manga_recommendation_app/services/auth/email_verification_service.dart';
import 'package:manga_recommendation_app/services/auth/user_service.dart';

// Manages registration and email verification flow
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final UserService userService;
  final EmailVerificationService emailVerificationService;

  String _pendingEmail = '';
  String _pendingUsername = '';
  String _pendingPassword = '';

  RegisterBloc({required this.userService, required this.emailVerificationService})
      : super(RegisterInitial()) {
    on<RegisterSubmitted>((event, emit) async {
      emit(RegisterLoading());

      if (userService.isUsernameTaken(event.username)) {
        emit(RegisterError(message: 'Username is already taken'));
        return;
      }

      _pendingEmail = event.email;
      _pendingUsername = event.username;
      _pendingPassword = event.password;

      final result = await emailVerificationService.sendVerificationCode(event.email);
      emit(result.fold(
        (error) => RegisterError(message: error),
        (_) => RegisterCodeSent(email: event.email),
      ));
    });
    on<VerificationCodeSubmitted>((event, emit) async {
      emit(RegisterLoading());

      if (!emailVerificationService.verifyCode(event.code)) {
        emit(RegisterError(message: 'Invalid or expired verification code', isVerificationStep: true));
        return;
      }

      await userService.saveUser(_pendingEmail, _pendingUsername, _pendingPassword);
      emit(RegisterVerified(username: _pendingUsername, password: _pendingPassword));
    });
  }
}
