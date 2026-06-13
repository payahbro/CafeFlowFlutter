import 'package:cafe/app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provides default Supabase anon key for local runs', () {
    expect(AppConfig.supabaseAnonKey, isNotEmpty);
    expect(
      AppConfig.supabaseAnonKey,
      startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'),
    );
  });
}
