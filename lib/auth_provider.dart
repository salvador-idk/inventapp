import 'package:flutter/material.dart';
import 'user_model.dart';

class AuthProvider with ChangeNotifier {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.role.toLowerCase() == 'admin';
  bool get isEmpleado => _currentUser?.role.toLowerCase() == 'empleado';
  bool get isLoggedIn => _currentUser != null;

  void setCurrentUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}