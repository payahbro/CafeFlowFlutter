import 'package:cafe/features/auth/data/datasources/auth_profile_remote_data_source.dart';
import 'package:cafe/features/auth/data/datasources/supabase_auth_remote_data_source.dart';
import 'package:cafe/features/auth/domain/entities/auth_session.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required SupabaseAuthRemoteDataSource supabaseAuthRemoteDataSource,
    required AuthProfileRemoteDataSource authProfileRemoteDataSource,
  }) : _supabaseAuthRemoteDataSource = supabaseAuthRemoteDataSource,
       _authProfileRemoteDataSource = authProfileRemoteDataSource;

  final SupabaseAuthRemoteDataSource _supabaseAuthRemoteDataSource;
  final AuthProfileRemoteDataSource _authProfileRemoteDataSource;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final token = await _supabaseAuthRemoteDataSource.signInWithPassword(
      email: email,
      password: password,
    );
    final user = await _authProfileRemoteDataSource.getMyProfile(
      token.accessToken,
    );
    return AuthSession(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      user: user,
    );
  }

  @override
  Future<void> logout() async {}
}
