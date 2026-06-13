import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/auth/data/models/auth_profile_model.dart';
import 'package:cafe/shared/models/app_user.dart';

abstract class AuthProfileRemoteDataSource {
  Future<AppUser> getMyProfile(String accessToken);
}

class AuthProfileRemoteDataSourceImpl implements AuthProfileRemoteDataSource {
  AuthProfileRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AppUser> getMyProfile(String accessToken) async {
    final response = await _apiClient.get(
      '/users/profile',
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );
    final data =
        response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return AuthProfileModel.fromJson(data).toEntity();
  }
}
