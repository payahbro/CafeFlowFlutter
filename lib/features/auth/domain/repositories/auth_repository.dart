import 'package:cafe/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<void> logout();
}
