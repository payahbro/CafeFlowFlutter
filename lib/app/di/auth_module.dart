import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/auth/data/datasources/auth_profile_remote_data_source.dart';
import 'package:cafe/features/auth/data/datasources/supabase_auth_remote_data_source.dart';
import 'package:cafe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';

class AuthModule {
  AuthModule() {
    repository = AuthRepositoryImpl(
      supabaseAuthRemoteDataSource:
          SupabaseAuthRemoteDataSourceImpl.fromConfig(),
      authProfileRemoteDataSource: AuthProfileRemoteDataSourceImpl(
        ApiClient(baseUrl: AppConfig.apiBaseUrl),
      ),
    );
  }

  late final AuthRepository repository;
}
