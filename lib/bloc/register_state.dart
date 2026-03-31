// Registration states
abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterCodeSent extends RegisterState {
  final String email;
  RegisterCodeSent({required this.email});
}

class RegisterVerified extends RegisterState {
  final String username;
  final String password;
  RegisterVerified({required this.username, required this.password});
}

class RegisterError extends RegisterState {
  final String message;
  final bool isVerificationStep;
  RegisterError({required this.message, this.isVerificationStep = false});
}
