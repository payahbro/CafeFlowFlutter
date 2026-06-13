class SupabaseAuthTokenModel {
  const SupabaseAuthTokenModel({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory SupabaseAuthTokenModel.fromJson(Map<String, dynamic> json) {
    return SupabaseAuthTokenModel(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }
}
