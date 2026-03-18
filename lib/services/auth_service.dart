class AuthService {
  static const String _adminUsername = 'admin123';
  static const String _adminPassword = 'admin123';

  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return username == _adminUsername && password == _adminPassword;
  }
}
