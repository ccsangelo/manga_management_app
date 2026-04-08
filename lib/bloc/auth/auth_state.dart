// Auth states
abstract class AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final String username;
  final bool sessionTakenOver;
  AuthAuthenticated({required this.token, required this.username, this.sessionTakenOver = false});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}
