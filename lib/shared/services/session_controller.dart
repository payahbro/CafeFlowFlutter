import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/foundation.dart';

class SessionController extends ChangeNotifier {
  SessionController()
    : _currentUser = const AppUser(
        id: 'local-demo-user',
        fullName: 'Raditya',
        role: UserRole.customer,
      );

  AppUser _currentUser;
  bool _isLoggedIn = false;

  AppUser get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  void loginWithCredentials({required String email, required String password}) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw ArgumentError('Email dan password wajib diisi');
    }

    final normalized = email.toLowerCase();
    final role = normalized.contains('admin')
        ? UserRole.admin
        : normalized.contains('pegawai')
        ? UserRole.pegawai
        : UserRole.customer;

    final namePart = email.split('@').first.trim();
    final safeName = namePart.isEmpty ? 'Pengguna' : _capitalize(namePart);

    _currentUser = _currentUser.copyWith(fullName: safeName, role: role);
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
