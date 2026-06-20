import 'package:cafe/app/di/auth_module.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/foundation.dart';

class SessionController extends ChangeNotifier {
  SessionController({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthModule().repository,
      _currentUser = const AppUser(
        id: 'local-demo-user',
        fullName: 'Raditya',
        role: UserRole.customer,
      );

  final AuthRepository _authRepository;
  AppUser _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _accessToken;
  String? _errorMessage;

  AppUser get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  String? get errorMessage => _errorMessage;

  Future<void> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw ArgumentError('Email dan password wajib diisi');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _authRepository.login(
        email: email.trim(),
        password: password,
      );
      _currentUser = session.user;
      _accessToken = session.accessToken;
      _isLoggedIn = true;
    } catch (error) {
      _isLoggedIn = false;
      _accessToken = null;
      _errorMessage = '$error';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final token = _accessToken;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.logout(accessToken: token);
      _isLoggedIn = false;
      _accessToken = null;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = '$error';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
