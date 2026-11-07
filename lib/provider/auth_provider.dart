import 'package:flutter/foundation.dart';
import '../database/app_db.dart';
import '../repository/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repo;
  AuthProvider(this.repo);

  User? user;
  String? error;
  bool get isLoggedIn => user != null;

  Future<bool> login(String username, String password) async {
    user = await repo.login(username.trim(), password);
    error = user == null ? 'Wrong username or password' : null;
    notifyListeners();
    return user != null;
  }

  void logout() {
    user = null;
    notifyListeners();
  }
}
