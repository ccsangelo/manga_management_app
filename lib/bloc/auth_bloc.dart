import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth_event.dart';
import 'package:manga_recommendation_app/bloc/auth_state.dart';
import 'package:manga_recommendation_app/services/auth_service.dart';

// Manages authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthLoading()) {
    on<CheckAuthEvent>((event, emit) async {
      final token = await authService.getValidToken();
      emit(token != null ? AuthAuthenticated(token: token) : AuthUnauthenticated());
    });
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      final hadSession = await authService.hasActiveSession();
      if (hadSession) await authService.logout();
      final result = await authService.login(event.username, event.password);
      emit(result.fold(
        (error) => AuthError(message: error),
        (token) => AuthAuthenticated(token: token, sessionTakenOver: hadSession),
      ));
    });
    on<LogoutEvent>((_, emit) async {
      await authService.logout();
      emit(AuthUnauthenticated());
    });
    on<ClearAuthErrorEvent>((_, emit) => emit(AuthUnauthenticated()));
  }
}
