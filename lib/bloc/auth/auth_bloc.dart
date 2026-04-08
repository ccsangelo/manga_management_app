import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_event.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_state.dart';
import 'package:manga_recommendation_app/config/app_config.dart';
import 'package:manga_recommendation_app/services/auth/auth_service.dart';

// Manages authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthLoading()) {
    on<CheckAuthEvent>((event, emit) async {
      final token = await authService.getValidToken();
      if (token != null) {
        final username = _extractUsername(token);
        emit(AuthAuthenticated(token: token, username: username));
      } else {
        emit(AuthUnauthenticated());
      }
    });
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      final hadSession = await authService.hasActiveSession();
      if (hadSession) await authService.logout();
      final result = await authService.login(event.username, event.password);
      emit(result.fold(
        (error) => AuthError(message: error),
        (token) => AuthAuthenticated(
          token: token,
          username: event.username,
          sessionTakenOver: hadSession,
        ),
      ));
    });
    on<LogoutEvent>((_, emit) async {
      await authService.logout();
      emit(AuthUnauthenticated());
    });
    on<ClearAuthErrorEvent>((_, emit) => emit(AuthUnauthenticated()));
  }

  String _extractUsername(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(AppConfig.jwtSecret));
      return (jwt.payload as Map<String, dynamic>)['username'] as String;
    } catch (_) {
      return '';
    }
  }
}
