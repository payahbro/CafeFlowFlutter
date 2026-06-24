import 'package:cafe/app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the deployed GCP backend origin by default', () {
    expect(AppConfig.backendOrigin, 'http://34.101.80.186:8080');
    expect(AppConfig.apiBaseUrl, 'http://34.101.80.186:8080/api/v1');
  });

  test('provides default Supabase anon key for local runs', () {
    expect(AppConfig.supabaseAnonKey, isNotEmpty);
    expect(
      AppConfig.supabaseAnonKey,
      startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'),
    );
  });
}
