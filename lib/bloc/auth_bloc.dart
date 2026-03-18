import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth_event.dart';
import 'package:manga_recommendation_app/bloc/auth_state.dart';
import 'package:manga_recommendation_app/services/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthUnauthenticated()) {
    on<LoginEvent>(_onLoginEvent);
    on<LogoutEvent>(_onLogoutEvent);
  }

  Future<void> _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final success = await authService.login(event.username, event.password);
      emit(success
          ? AuthAuthenticated()
          : AuthError(message: 'Invalid username or password'));
    } catch (e) {
      emit(AuthError(message: 'An error occurred: ${e.toString()}'));
    }
  }

  void _onLogoutEvent(LogoutEvent event, Emitter<AuthState> emit) {
    emit(AuthUnauthenticated());
  }
}
