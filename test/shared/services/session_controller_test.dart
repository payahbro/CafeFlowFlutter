import 'package:cafe/features/auth/domain/entities/auth_session.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return const AuthSession(
      accessToken: 'access-token-123',
      refreshToken: 'refresh-token-123',
      user: AppUser(
        id: 'user-1',
        email: 'user@cafe.test',
        fullName: 'User Cafe',
        role: UserRole.customer,
        isVerified: true,
        isActive: true,
        phoneNumber: '+628123456789',
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  test('login stores backend user profile and access token', () async {
    final controller = SessionController(authRepository: _FakeAuthRepository());

    await controller.loginWithCredentials(
      email: 'user@cafe.test',
      password: '12345678',
    );

    expect(controller.isLoggedIn, isTrue);
    expect(controller.accessToken, 'access-token-123');
    expect(controller.currentUser.email, 'user@cafe.test');
    expect(controller.currentUser.fullName, 'User Cafe');
  });
}
