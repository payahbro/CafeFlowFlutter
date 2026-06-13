import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/core/errors/app_exception.dart';
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/auth/data/models/supabase_auth_token_model.dart';

abstract class SupabaseAuthRemoteDataSource {
  Future<SupabaseAuthTokenModel> signInWithPassword({
    required String email,
    required String password,
  });
}

class SupabaseAuthRemoteDataSourceImpl implements SupabaseAuthRemoteDataSource {
  SupabaseAuthRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String anonKey,
  }) : _apiClient = apiClient,
       _anonKey = anonKey;

  final ApiClient _apiClient;
  final String _anonKey;

  @override
  Future<SupabaseAuthTokenModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (_anonKey.isEmpty) {
      throw const AppException(
        'SUPABASE_ANON_KEY belum dikonfigurasi.',
        code: 'SUPABASE_CONFIG_MISSING',
      );
    }

    final response = await _apiClient.post(
      '/token',
      queryParameters: const <String, dynamic>{'grant_type': 'password'},
      headers: <String, String>{'apikey': _anonKey},
      body: <String, dynamic>{'email': email, 'password': password},
    );

    final token = SupabaseAuthTokenModel.fromJson(response);
    if (token.accessToken.isEmpty) {
      throw const AppException('Login gagal: token Supabase kosong.');
    }
    return token;
  }

  static SupabaseAuthRemoteDataSourceImpl fromConfig() {
    return SupabaseAuthRemoteDataSourceImpl(
      apiClient: ApiClient(baseUrl: AppConfig.supabaseAuthBaseUrl),
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
}
